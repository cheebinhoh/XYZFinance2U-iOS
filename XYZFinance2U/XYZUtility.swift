//
//  XYZUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/30/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import UIKit

// MARK: - type

// generic structure to support UITableView section and cell
struct TableSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]() 
    var data: Any?
}

// MARK: - formatting

func formattingDate(date: Date,
                    _ style: DateFormatter.Style) -> String {
    
    let dateFormatter = DateFormatter();
    
    dateFormatter.dateStyle = style
    return dateFormatter.string(from: date)
}

func formattingDateTime(date: Date) -> String {
    
    let dateFormatter = DateFormatter();
    
    // FIXME, we will need to think about localization
    dateFormatter.dateFormat = "MMM-dd, yyyy 'at' hh:mm a"
    
    return dateFormatter.string(from: date)
}

func formattingAndProcessDoubleValue(input: String) -> String {
    
    var processedInput = ""
    var afterPoint = false
    var numberOfDigitsAfterPoint = 0
    let digitSet = CharacterSet.decimalDigits
    let numberOfFixedDecimalPoints = 2
    
    let lastChar = input[input.index(before: input.endIndex)]
    
    if ( Locale.current.decimalSeparator ?? "" == "\(lastChar)" ) {
        
        processedInput = shiftingDecimalPoint(input: input)
        numberOfDigitsAfterPoint = numberOfFixedDecimalPoints
    } else {
        
        for c in input.unicodeScalars {
            
            if !digitSet.contains(c) {
                
                afterPoint = true
                continue
            } else {
                
                if afterPoint {
                    
                    numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
                }
                
                processedInput += "\(c)"
            }
        }
    }

    var doubleValue = Double(processedInput) ?? 0.0
    
    while numberOfDigitsAfterPoint != numberOfFixedDecimalPoints {
        
        doubleValue = doubleValue / 100
        
        if numberOfDigitsAfterPoint < numberOfFixedDecimalPoints {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
        } else {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint - 1
        }
    }
    
    return "\(doubleValue)"
}

func shiftingDecimalPoint(input: String) -> String {
    
    var processedInput = ""
    let reversedInput = input.reversed()
    var decimalPointFound = false
    
    for c in String(reversedInput).unicodeScalars {
        
        if ( Locale.current.decimalSeparator ?? "" == "\(c)" ) {
            
            if ( decimalPointFound ) {
                
                continue
            } else {
                
                if ( processedInput.isEmpty ) {
                    
                    processedInput = processedInput + "00"
                }
            }
            
            decimalPointFound = true
        }

        processedInput = processedInput + "\(c)"
    }
    
    return String(processedInput.reversed())
}

func formattingDoubleValueAsDouble(input: String) -> Double {
    
    return Double(formattingDoubleValue(input: input)) ?? 0.0
}

func formattingDoubleValue(input: String) -> String {
    
    var processedInput = ""
    var startWithDecimalDigit = false
    let digitSet = CharacterSet.decimalDigits
    
    var inputToBeProcessed = input
    
    for c in inputToBeProcessed.unicodeScalars {
        
        if startWithDecimalDigit {
            
            if digitSet.contains(c) || ( Locale.current.decimalSeparator ?? "" == "\(c)" ) {
                
                processedInput += "\(c)"
            }
        } else if !digitSet.contains(c) {
            
            continue
        } else {
            
            startWithDecimalDigit = true
            processedInput += "\(c)"
        }
    }
    
    return processedInput
}

func formattingCurrencyValue(input: Double,
                             _ code: String?) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(input: value, code)
}

func formattingCurrencyValue(input: String,
                             _ code: String?) -> String {
    
    let processedInput = formattingDoubleValue(input: input)
    let formatter = NumberFormatter()

    let amountAsDouble = Double(processedInput) ?? 0.0
    let amountASNSNumber = NSNumber(value: amountAsDouble)
    
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    
    guard let formattedAmount = formatter.string(from: amountASNSNumber) else {
        
        return ""
    }
    
    return formattedAmount
}

// MARK: - core data

func managedContext() -> NSManagedObjectContext? {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    return appDelegate.persistentContainer.viewContext
}

func saveManageContext() {
    
    let aContext = managedContext()
    
    do {
        
        try aContext?.save()
    } catch let nserror as NSError {
        
        fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
    }
}

func sortAcounts(_ incomeList: [XYZAccount]) -> [XYZAccount] {
    
    return incomeList.sorted() { (acc1, acc2) in
        
        return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
    }
}

func loadAccounts() -> [XYZAccount]? {
    
    var output: [XYZAccount]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZAccount>(entityName: "XYZAccount")
    
    do {
        
        output = try aContext?.fetch(fetchRequest)
        
        output = sortAcounts(output!)
    } catch let error as NSError {
        
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    return output
}

func loadExpenses() -> [XYZExpense]? {
    
    var expenses: [XYZExpense]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZExpense>(entityName: "XYZExpense")
    
    do {
        
        expenses = try aContext?.fetch(fetchRequest)
    } catch let error as NSError {
        
        print("******** Could not fetch. \(error), \(error.userInfo)")
    }
    
    let fetchRequestExpPerson = NSFetchRequest<XYZExpensePerson>(entityName: "XYZExpensePerson")
    
    do {
        
        _ = try aContext?.fetch(fetchRequestExpPerson)
    } catch let error as NSError {
        
        print("******** Could not fetch. \(error), \(error.userInfo)")
    }
    
    let fetchRequestExpReceipt = NSFetchRequest<XYZExpenseReceipt>(entityName: "XYZExpenseReceipt")
    
    do {
        
        _ = try aContext?.fetch(fetchRequestExpReceipt)
    } catch let error as NSError {
        
        print("******** Could not fetch. \(error), \(error.userInfo)")
    }
    
    return sortExpenses(expenses: expenses!)
}

func sortExpenses(expenses: [XYZExpense]) -> [XYZExpense] {
    
    return expenses.sorted(by: { (exp1, exp2) -> Bool in
        
        let date1 = exp1.value(forKey: XYZExpense.date) as! Date
        let date2 = exp2.value(forKey: XYZExpense.date) as! Date
        
        return date1 > date2
    })
}

func loadExchangeRates() -> [XYZExchangeRate]? {
    
    var output: [XYZExchangeRate]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZExchangeRate>(entityName: XYZExchangeRate.type)
    
    do {
        
        output = try aContext?.fetch(fetchRequest)
    } catch let error as NSError {
        
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    return output
}

func loadiCloudZone() -> [XYZiCloudZone]? {
    
    var output: [XYZiCloudZone]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZiCloudZone>(entityName: XYZiCloudZone.type)
    
    do {
        
        output = try aContext?.fetch(fetchRequest)
    } catch let error as NSError {
        
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    return output
}

// MARK: - iCloud
//
// The high level interaction between iCloud and local core data is that:
// on start up:
//    - we check local iCloud zone cache if zone exists.
//    - if it is not, we try to create it
//    - after created, we sync iCloud state to local core dataset, that can either add or delete
//      record
//    - if it does exist, then we sync iCloud state to local core dataset, then we push pending update to iCloud change to iCloud
//
// after data manipulated on app:
//    - we do a sync from icloud to local store
//    - we then push changes from local store to icloud

func createUpdateAccount(_ record: CKRecord,
                         _ incomeList: [XYZAccount],
                         _ context: NSManagedObjectContext) -> [XYZAccount] {

    let recordName = record.recordID.recordName
    let bank = record[XYZAccount.bank] as? String
    let accountNr = record[XYZAccount.accountNr] as? String
    let amount = record[XYZAccount.amount] as? Double
    let lastUpdate = record[XYZAccount.lastUpdate] as? Date
    let currencyCode = record[XYZAccount.currencyCode] as? String
    let repeatDate = record[XYZAccount.repeatDate] as? Date
    let repeatAction = record[XYZAccount.repeatAction] as? String
    
    var outputIncomeList: [XYZAccount] = incomeList
    var incomeToBeUpdated: XYZAccount?
    
    for income in outputIncomeList {
        
        guard let recordId = income.value(forKey: XYZAccount.recordId) as? String else {
            
            fatalError("Exception: record is expected")
        }
        
        if recordId == recordName {
            
            incomeToBeUpdated = income
            break
        }
    }

    let sequenceNr = record[XYZAccount.sequenceNr] as? Int
    
    if nil == incomeToBeUpdated {
        
        incomeToBeUpdated = XYZAccount(recordName,
                                       sequenceNr: sequenceNr!,
                                       bank: bank!,
                                       accountNr: accountNr ?? "",
                                       amount: amount!,
                                       date: lastUpdate!,
                                       context: context)
        outputIncomeList.append(incomeToBeUpdated!)
    }
    
    incomeToBeUpdated?.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
    incomeToBeUpdated?.setValue(amount!, forKey: XYZAccount.amount)
    incomeToBeUpdated?.setValue(lastUpdate!, forKey: XYZAccount.lastUpdate)
    incomeToBeUpdated?.setValue(currencyCode!, forKey: XYZAccount.currencyCode)
    incomeToBeUpdated?.setValue(recordName, forKey: XYZAccount.recordId)
    
    if repeatDate != nil {
        
        incomeToBeUpdated?.setValue(repeatDate, forKey: XYZAccount.repeatDate)
        incomeToBeUpdated?.setValue(repeatAction, forKey: XYZAccount.repeatAction)
    }

    // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
    incomeToBeUpdated?.setValue(Date(), forKey: XYZAccount.lastRecordChange)

    return outputIncomeList
}

func fetchiCloudZoneChange(_ zones: [CKRecordZone],
                           _ icloudZones: [XYZiCloudZone],
                           _ completionblock: @escaping () -> Void ) {
 
    let aContext = managedContext()
    let container = CKContainer.default()
    let database = container.privateCloudDatabase
    var changedZoneIDs: [CKRecordZoneID] = []
    var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
    
    for zone in zones {
        
        changedZoneIDs.append(zone.zoneID)
        
        var changeToken: CKServerChangeToken? = nil
        
        for icloudzone in icloudZones {
         
            let name = icloudzone.value(forKey: XYZiCloudZone.name) as? String
            if name == zone.zoneID.zoneName {
                
                if let data = icloudzone.value(forKey: XYZiCloudZone.changeToken) as? Data {
                
                    changeToken = (NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken)
                } else {
                    
                }
                
                break
            }
        }
        
        let option = CKFetchRecordZoneChangesOptions()
        option.previousServerChangeToken = changeToken
        
        optionsByRecordZoneID[zone.zoneID] = option
    }
    
    let opZoneChange = CKFetchRecordZoneChangesOperation(recordZoneIDs: changedZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID )
    
    opZoneChange.recordChangedBlock = { (record) in
        
        print("-------- record change")
        let ckrecordzone = CKRecordZone(zoneName: record.recordID.zoneID.zoneName)
        let icloudZone = iCloudZone(of: ckrecordzone, icloudZones)
        
        let zoneName = icloudZone?.value(forKey: XYZiCloudZone.name) as? String
        
        switch zoneName! {
            
            case XYZAccount.type:
                guard var incomeList = icloudZone?.data as? [XYZAccount] else {
                    
                    fatalError("Exception: incomeList is expected")
                }
            
                incomeList = createUpdateAccount(record, incomeList, aContext!)
                icloudZone?.data = incomeList
            
            case XYZExpense.type:
                guard var expenseList = icloudZone?.data as? [XYZExpense] else {
                    
                    fatalError("Exception: expense is expected")
                }
            
                // TODO
                fatalError("Exception: TODO")
                icloudZone?.data = expenseList
            
            default:
                fatalError("Exception: zone type \(String(describing: zoneName)) is not supported")
        }
    }
    
    opZoneChange.recordWithIDWasDeletedBlock = { (recordId, recordType) in
        
        for icloudZone in icloudZones {
            
            if let zName = icloudZone.value(forKey: XYZiCloudZone.name) as? String, zName == recordType {
            
                switch recordType {
                    
                    case XYZAccount.type:
                        guard var incomeList = icloudZone.data as? [XYZAccount] else {
                            
                            fatalError("Exception: [XYZAccount] is expected")
                        }
                    
                        for (index, income) in incomeList.enumerated() {
                            
                            guard let recordName = income.value(forKey: XYZAccount.recordId) as? String else {
                                fatalError("Exception: record id is expected")
                            }
                            
                            if recordName == recordId.recordName {
                                
                                aContext?.delete(income)
                                incomeList.remove(at: index)
                                
                                break
                            }
                        }
                    
                        icloudZone.data = incomeList
                    
                    case XYZExpense.type:
                        guard var expenseList = icloudZone.data as? [XYZExpense] else {
                            
                            fatalError("Exception: expense is expected")
                        }
                    
                        for (index, expense) in expenseList.enumerated() {
                            
                            guard let recordName = expense.value(forKey: XYZExpense.recordId) as? String else {
                                fatalError("Exception: record id is expected")
                            }
                            
                            if recordName == recordId.recordName {
                                
                                aContext?.delete(expense)
                                expenseList.remove(at: index)
                                
                                break
                            }
                        }
                    
                        icloudZone.data = expenseList
                    
                    default:
                        fatalError("Exception: \(recordType) is not supported")
                }
            }
        }
    }
    
    opZoneChange.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
        
        print("----- token \(String(describing: token))")
    }
    
    opZoneChange.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
        
        if let _ = error {
            
            print("Error fetching zone changes for database:", error!)
            return
        }
        
        OperationQueue.main.addOperation {
            
            for icloudzone in icloudZones {
                
                if let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zName == zoneId.zoneName {
                    
                    var hasChangeToken = true;
              
                    if let data = icloudzone.value(forKey: XYZiCloudZone.changeToken) as? Data {
                        
                        let previousChangeToken = (NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken)
                        hasChangeToken = previousChangeToken != changeToken!
                    }
                    
                    if hasChangeToken {
                        
                        print("---- save change token")
                        let lastTokenFetchDate = Date()
                        
                        let archivedChangeToken = NSKeyedArchiver.archivedData(withRootObject: changeToken! )
                        icloudzone.setValue(archivedChangeToken, forKey: XYZiCloudZone.changeToken)
                        icloudzone.setValue(lastTokenFetchDate, forKey: XYZiCloudZone.changeTokenLastFetch)
                    }
                    
                    break
                }
                
                saveManageContext() // save changed token and data
            }
        }
    }
    
    opZoneChange.fetchRecordZoneChangesCompletionBlock = { (error) in
        
        if let error = error {
            
            print("Error fetching zone changes for database:", error)
            return
        }
        
        completionblock()
    }
    
    database.add(opZoneChange)
}

func iCloudZone(of zone: CKRecordZone, _ icloudZones: [XYZiCloudZone]) -> XYZiCloudZone? {
    
    for icloudzone in icloudZones {
        
        if let name = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zone.zoneID.zoneName == name {
            
            return icloudzone
        }
    }
    
    return nil
}

func pushChangeToiCloudZone(_ zones: [CKRecordZone],
                            _ icloudZones: [XYZiCloudZone],
                            _ completionblock: @escaping () -> Void) {
    
    for zone in zones {
        
        let name = zone.zoneID.zoneName
        
        switch name {
            
            case XYZAccount.type:
                if let iCloudZone = iCloudZone(of: zone, icloudZones) {
                    
                    guard let incomeList = iCloudZone.data as? [XYZAccount] else {
                        
                        fatalError("Exception: [XYZAccount] is expected")
                    }
                    
                    saveAccountsToiCloud(zone, iCloudZone, incomeList, {
                        
                        OperationQueue.main.addOperation {
                            
                            fetchiCloudZoneChange([zone], icloudZones, {
                                
                            })
                            
                            completionblock()
                        }
                    })
                }
            
        case XYZExpense.type:
            if let iCloudZone = iCloudZone(of: zone, icloudZones) {
                
                print("TODO save change to icloud")
            }
            
            default:
                fatalError("Exception: zone \(name) is not supported")
        }
    }
}

func fetchAndUpdateiCloud(_ zones: [CKRecordZone],
                          _ iCloudZones: [XYZiCloudZone],
                          _ completionblock: @escaping () -> Void) {
    
    if !iCloudZones.isEmpty {
        
        fetchiCloudZoneChange(zones, iCloudZones, {
            
            //we should only write to icloud if we do have changed after last token change
            
            OperationQueue.main.addOperation {
                
                pushChangeToiCloudZone(zones, iCloudZones, completionblock)
            }
        })
    }
}

func saveAccountsToiCloud(_ zone: CKRecordZone,
                          _ iCloudZone: XYZiCloudZone,
                          _ incomeList: [XYZAccount],
                          _ completionblock: @escaping () -> Void ) {
    
    var incomeListToBeSaved: [XYZAccount]?
    
    if let lastChangeTokenFetch = iCloudZone.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date {
        
        incomeListToBeSaved = [XYZAccount]()
        
        for income in incomeList {
    
            if let lastChanged = income.value(forKey: XYZAccount.lastRecordChange) as? Date {
                
                if lastChanged > lastChangeTokenFetch {
                    
                    incomeListToBeSaved?.append(income)
                }
            } else {
                
                incomeListToBeSaved?.append(income)
            }
        }
    } else {
      
        incomeListToBeSaved = incomeList
    }
 
    var recordIdsToBeDeleted = [CKRecordID]()
    
    guard let data = iCloudZone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
        
        fatalError("Exception: data is expected for deleteRecordIdList")
    }
    
    guard let deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteRecordLiset {
        
        let customZone = CKRecordZone(zoneName: XYZAccount.type)
        let ckrecordId = CKRecordID(recordName: deleteRecordName, zoneID: customZone.zoneID)
        
        recordIdsToBeDeleted.append(ckrecordId)
    }

    saveAccountsToiCloud(iCloudZone, incomeListToBeSaved!, recordIdsToBeDeleted, completionblock)
}

func saveAccountsToiCloud(_ iCloudZone: XYZiCloudZone,
                          _ incomeList: [XYZAccount],
                          _ recordIdsToBeDeleted: [CKRecordID],
                          _ completionblock: @escaping () -> Void ) {
    
    let container = CKContainer.default()
    let database = container.privateCloudDatabase
    
    var recordsToBeSaved = [CKRecord]()

    for income in incomeList {

        let recordName = income.value(forKey: XYZAccount.recordId) as? String
        let customZone = CKRecordZone(zoneName: XYZAccount.type)
        let ckrecordId = CKRecordID(recordName: recordName!, zoneID: customZone.zoneID)

        let record = CKRecord(recordType: XYZAccount.type, recordID: ckrecordId)

        let bank = income.value(forKey: XYZAccount.bank) as? String
        let accountNr = income.value(forKey: XYZAccount.accountNr) as? String ?? ""
        let amount = income.value(forKey: XYZAccount.amount) as? Double
        let lastUpdate = income.value(forKey: XYZAccount.lastUpdate) as? Date
        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        let repeatDate = income.value(forKey: XYZAccount.repeatDate) as? Date
        let repeatAction = income.value(forKey: XYZAccount.repeatAction) as? String
        let sequencNr = income.value(forKey: XYZAccount.sequenceNr) as? Int
        
        record.setValue(sequencNr, forKey: XYZAccount.sequenceNr)
        record.setValue(bank, forKey: XYZAccount.bank)
        record.setValue(accountNr, forKey: XYZAccount.accountNr)
        record.setValue(amount, forKey: XYZAccount.amount)
        record.setValue(lastUpdate, forKey: XYZAccount.lastUpdate)
        record.setValue(currencyCode, forKey: XYZAccount.currencyCode)

        if nil != repeatDate {

            record.setValue(repeatDate, forKey: XYZAccount.repeatDate)
            record.setValue(repeatAction, forKey: XYZAccount.repeatAction)
        }

        recordsToBeSaved.append(record)
    }

    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
    
        OperationQueue.main.addOperation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [String]())
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func registeriCloudSubscription(_ iCloudZones: [XYZiCloudZone]) {
    
    for icloudzone in iCloudZones {
        
        guard let name = (icloudzone.value(forKey: XYZiCloudZone.name) as? String) else {
            
            fatalError("Exception: iCloud zone name is expected")
        }
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        let ckrecordzone = CKRecordZone(zoneName: name)
        
        let fetchOp = CKFetchSubscriptionsOperation.init(subscriptionIDs: [ckrecordzone.zoneID.zoneName])
        
        fetchOp.fetchSubscriptionCompletionBlock = {(subscriptionDict, error) -> Void in
            
            if let _ = subscriptionDict?[ckrecordzone.zoneID.zoneName] {
                
                print("-------- has subscription")
            } else {

                print("-------- create new subscription")
                let subscription = CKRecordZoneSubscription.init(zoneID: ckrecordzone.zoneID, subscriptionID: ckrecordzone.zoneID.zoneName)
                let notificationInfo = CKNotificationInfo()
                
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
                operation.qualityOfService = .utility
                operation.completionBlock = {
                    
                }
                
                database.add(operation)
            }
        }
        
        database.add(fetchOp)
    }
}


