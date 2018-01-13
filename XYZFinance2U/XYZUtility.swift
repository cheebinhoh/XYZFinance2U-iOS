//
//  XYZUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/30/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import Foundation
import CoreData
import UIKit
import CloudKit

struct TableSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]() 
    var data: Any?
}

func formattingDate(date: Date, _ style: DateFormatter.Style) -> String {
    
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

func formattingCurrencyValue(input: Double, _ code: String?) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(input: value, code)
}

func formattingCurrencyValue(input: String, _ code: String?) -> String {
    
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

// MARK: - iCloud

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
    
    print("-------- record name = \(recordName)")
    for income in outputIncomeList {
        
        guard let recordId = income.value(forKey: XYZAccount.recordId) as? String else {
            
            fatalError("Exception: record is expected")
        }
        
        if recordId == recordName {
            
            incomeToBeUpdated = income
            break
        }
    }

    if nil == incomeToBeUpdated {
        
        let tokenStrings = recordName.split(separator: ":")
        let sequenceNr = Int(tokenStrings[tokenStrings.count - 1])!
        
        incomeToBeUpdated = XYZAccount(sequenceNr: sequenceNr,
                                       bank: bank!,
                                       accountNr: accountNr ?? "",
                                       amount: amount!,
                                       date: lastUpdate!,
                                       context: context)
        outputIncomeList.append(incomeToBeUpdated!)
    }
    
    incomeToBeUpdated?.setValue(amount!, forKey: XYZAccount.amount)
    incomeToBeUpdated?.setValue(lastUpdate!, forKey: XYZAccount.lastUpdate)
    incomeToBeUpdated?.setValue(currencyCode!, forKey: XYZAccount.currencyCode)
    incomeToBeUpdated?.setValue(recordName, forKey: XYZAccount.recordId)
    
    if repeatDate != nil {
        
        incomeToBeUpdated?.setValue(repeatDate, forKey: XYZAccount.repeatDate)
        incomeToBeUpdated?.setValue(repeatAction, forKey: XYZAccount.repeatAction)
    }

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
        
        print("Record changed...")
        
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
            
            default:
                fatalError("Exception: zone type \(String(describing: zoneName)) is not supported")
        }
    }
    
    opZoneChange.recordWithIDWasDeletedBlock = { (recordId, recordType) in
        
        print("-------- record deleted:", recordId)
        
        for icloudzone in icloudZones {
            
            if let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zName == recordType {
            
                switch recordType {
                    
                    case XYZAccount.type:
                        guard var incomeList = icloudzone.data as? [XYZAccount] else {
                            
                            fatalError("Exception: [XYZAccount] is expected")
                        }
                    
                        for (index, income) in incomeList.enumerated() {
                            
                            guard let recordName = income.value(forKey: XYZAccount.recordId) as? String else {
                                fatalError("Exception: record id is expected")
                            }
                            
                            if recordName == recordId.recordName {
                                
                                print("-------- record found and delete")
                                aContext?.delete(income)
                                incomeList.remove(at: index)
                                
                                break
                            }
                        }
                    
                        icloudzone.data = incomeList
                    
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
        
        if let error = error {
            
            print("Error fetching zone changes for database:", error)
            return
        }
        
        print("-------- success in fetching zone last change token")
        OperationQueue.main.addOperation {
            
            for icloudzone in icloudZones {
                
                if let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zName == zoneId.zoneName {
                    
                    //zone.data = updatedIncomeList
                    let updatedIncomeList = icloudzone.data as? [XYZAccount]
                    print("-------- # of income = \(String(describing: updatedIncomeList?.count))")
                    
                    print("-------- change token \(changeToken!)")
                    
                    var hasChangeToken = true;
              
                    if let data = icloudzone.value(forKey: XYZiCloudZone.changeToken) as? Data {
                        
                        let previousChangeToken = (NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken)
                        hasChangeToken = previousChangeToken != changeToken!
                    }
                    
                    if hasChangeToken {
                        
                        print("-------- has new changeToken")
                        let lastTokenFetchDate = Date()
                        
                        let archivedChangeToken = NSKeyedArchiver.archivedData(withRootObject: changeToken! )
                        icloudzone.setValue(archivedChangeToken, forKey: XYZiCloudZone.changeToken)
                        icloudzone.setValue(lastTokenFetchDate, forKey: XYZiCloudZone.changeTokenLastFetch)
                    
                        saveManageContext()
                    }
                    
                    break
                }
                
                completionblock()
            }
        }
    }
    
    opZoneChange.fetchRecordZoneChangesCompletionBlock = { (error) in
        
        print("-------- fetch record zone complete")
        
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
    
    print("-------- push change to zone")
    
    for zone in zones {
        
        let name = zone.zoneID.zoneName
        
        switch name {
            
            case XYZAccount.type:
                if let iCloudZone = iCloudZone(of: zone, icloudZones) {
                    
                    guard let incomeList = iCloudZone.data as? [XYZAccount] else {
                        
                        fatalError("Exception: [XYZAccount] is expected")
                    }
                    
                    saveAccountsToiCloud(zone, iCloudZone, incomeList, {
                        
                        print("-------- done saving to iCloud")
                        OperationQueue.main.addOperation {
                            
                            fetchiCloudZoneChange([zone], icloudZones, {
                                
                                print("-------- fetch change after upload to iCloud")
                            })
                            
                            completionblock()
                        }
                    })
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
        
        print("-------- fetch changes from zones")
        
        fetchiCloudZoneChange(zones, iCloudZones, {
            
            print("-------- done fetching change from zone")
            
            //we should only write to icloud if we do have changed after last token change
            
            OperationQueue.main.addOperation {
                
                pushChangeToiCloudZone(zones, iCloudZones, completionblock)
            }
        })
    }
}

func saveAccountsToiCloud(_ zone: CKRecordZone, _ iCloudZone: XYZiCloudZone, _ incomeList: [XYZAccount], _ completionblock: @escaping () -> Void ) {
    
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

    print("-------- # of changed accounts to upload to iCloud is = \(String(describing: incomeListToBeSaved?.count))")
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

        print("-------- saving record name = \(String(describing: recordName))")
        
        let record = CKRecord(recordType: XYZAccount.type, recordID: ckrecordId)

        let bank = income.value(forKey: XYZAccount.bank) as? String
        let accountNr = income.value(forKey: XYZAccount.accountNr) as? String ?? ""
        let amount = income.value(forKey: XYZAccount.amount) as? Double
        let lastUpdate = income.value(forKey: XYZAccount.lastUpdate) as? Date
        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        let repeatDate = income.value(forKey: XYZAccount.repeatDate) as? Date
        let repeatAction = income.value(forKey: XYZAccount.repeatAction) as? String

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
    opToSaved.savePolicy = .changedKeys
    opToSaved.completionBlock = {
    
        OperationQueue.main.addOperation {

            let data = NSKeyedArchiver.archivedData(withRootObject: [String]())
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
            
            saveManageContext()
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
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

