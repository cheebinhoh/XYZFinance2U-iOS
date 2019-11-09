//
//  XYZiCloudUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/9/19.
//  Copyright © 2019 CB Hoh. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import CloudKit

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
    let principal = record[XYZAccount.principal] as? Double ?? 0.0

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
        
        incomeToBeUpdated = XYZAccount(id: recordName,
                                       sequenceNr: sequenceNr!,
                                       bank: bank!,
                                       accountNr: accountNr ?? "",
                                       amount: amount!,
                                       principal: principal,
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
        
        if let _ = XYZAccount.RepeatAction(rawValue: repeatAction ?? "") {
            
            incomeToBeUpdated?.setValue(repeatAction, forKey: XYZAccount.repeatAction)
        } else {
            
            incomeToBeUpdated?.setValue(XYZAccount.RepeatAction.none.rawValue, forKey: XYZAccount.repeatAction)
        }
    }

    // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
    incomeToBeUpdated?.setValue(Date(), forKey: XYZAccount.lastRecordChange)

    return outputIncomeList
}

func createUpdateExpense(_ oldChangeToken: Data,
                         _ isShared: Bool,
                         _ record: CKRecord,
                         _ expenseList: [XYZExpense],
                         _ unprocessedCKrecords: [CKRecord],
                         _ context: NSManagedObjectContext) -> ([XYZExpense], [CKRecord]) {
    
    var outputExpenseList: [XYZExpense] = expenseList
    var outputUnprocessedCkrecords: [CKRecord] = unprocessedCKrecords
    var unprocessedCkrecord: CKRecord?
    
    if record.recordType == XYZExpensePerson.type {
        
        let parentckreference = record[XYZExpense.type] as? CKRecord.Reference
      
        unprocessedCkrecord = record
        
        for expense in expenseList {
            
            let recordid = expense.value(forKey: XYZExpense.recordId) as? String
            if recordid == parentckreference?.recordID.recordName {
                
                let sequenceNr = record[XYZExpensePerson.sequenceNr] as? Int
                let name = record[XYZExpensePerson.name] as? String
                let email = record[XYZExpensePerson.email] as? String
                let paid = record[XYZExpensePerson.paid] as? Bool
                
                expense.addPerson(sequenceNr: sequenceNr!, name: name!, email: email!, paid: paid!, context: context)
                unprocessedCkrecord = nil
                
                break
            }
        }
        
        if let _ = unprocessedCkrecord {
            
            outputUnprocessedCkrecords.append(unprocessedCkrecord!)
        }
    } else if record.recordType == XYZExpense.type {
    
        let recordName = record.recordID.recordName
        let detail = record[XYZExpense.detail] as? String
        let amount = record[XYZExpense.amount] as? Double
        let date = record[XYZExpense.date] as? Date
        let shareRecordId = record[XYZExpense.shareRecordId] as? String
        let hasLocation = record[XYZExpense.hasLocation] as? Bool
        let isSoftDelete = record[XYZExpense.isSoftDelete] as? Bool
        let isSharedRecord = record[XYZExpense.isShared] as? Bool ?? false
        let currency = record[XYZExpense.currencyCode] as? String ?? Locale.current.currencyCode
        let budget = record[XYZExpense.budgetCategory] as? String ?? ""
        let recurring = record[XYZExpense.recurring] as? String ?? XYZExpense.Length.none.rawValue
        let recurringStopDate = record[XYZExpense.recurringStopDate] as? Date ?? date
        
        var expenseToBeUpdated: XYZExpense?

        for expense in outputExpenseList {
            
            guard let recordId = expense.value(forKey: XYZExpense.recordId) as? String else {
                
                fatalError("Exception: record is expected")
            }
            
            if recordId == recordName {
                
                expenseToBeUpdated = expense
                break
            }
        }
        
        if nil == expenseToBeUpdated {
        
            expenseToBeUpdated = XYZExpense(id: recordName, detail: detail!, amount: amount!, date: date!, context: context)
            outputExpenseList.append(expenseToBeUpdated!)
        }
        
        var indexToBeRemoved = [Int]()
        
        for (index, pendingCkrecord) in unprocessedCKrecords.enumerated() {
            
            let parentckreference = pendingCkrecord[XYZExpense.type] as? CKRecord.Reference
            
            if recordName == parentckreference?.recordID.recordName {
                
                let sequenceNr = pendingCkrecord[XYZExpensePerson.sequenceNr] as? Int
                let name = pendingCkrecord[XYZExpensePerson.name] as? String
                let email = pendingCkrecord[XYZExpensePerson.email] as? String
                let paid = pendingCkrecord[XYZExpensePerson.paid] as? Bool
                
                expenseToBeUpdated?.addPerson(sequenceNr: sequenceNr!, name: name!, email: email!, paid: paid!, context: context)

                indexToBeRemoved.append(index)
            }
        }

        for index in indexToBeRemoved.reversed() {
            
            outputUnprocessedCkrecords.remove(at: index)
        }
        
        expenseToBeUpdated?.setValue(detail, forKey: XYZExpense.detail)
        expenseToBeUpdated?.setValue(amount, forKey: XYZExpense.amount)
        expenseToBeUpdated?.setValue(date, forKey: XYZExpense.date)
        expenseToBeUpdated?.setValue(shareRecordId, forKey: XYZExpense.shareRecordId)
        expenseToBeUpdated?.setValue(isShared || isSharedRecord, forKey: XYZExpense.isShared)
        expenseToBeUpdated?.setValue(hasLocation, forKey: XYZExpense.hasLocation)
        expenseToBeUpdated?.setValue(oldChangeToken, forKey: XYZExpense.preChangeToken)
        expenseToBeUpdated?.setValue(isSoftDelete, forKey: XYZExpense.isSoftDelete)
        expenseToBeUpdated?.setValue(currency, forKey: XYZExpense.currencyCode)
        expenseToBeUpdated?.setValue(budget, forKey: XYZExpense.budgetCategory)
        expenseToBeUpdated?.setValue(recurring, forKey: XYZExpense.recurring)
        expenseToBeUpdated?.setValue(recurringStopDate, forKey: XYZExpense.recurringStopDate)
        
        let nrOfReceipt = record[XYZExpense.nrOfReceipts] as? Int
        for index in 0..<nrOfReceipt! {
            
            let image = "image\(index)"
            let ckasset = record[image] as? CKAsset
            let fileURL = ckasset?.fileURL!
            
            if let _ = fileURL {
            
                let task = URLSession.shared.dataTask(with: fileURL!) {(data, response, error) in
                    
                    if nil != error {
                        
                        print("-------- \(String(describing: error))")
                    } else {
                        
                        OperationQueue.main.addOperation {
                        
                            expenseToBeUpdated?.addReceipt(sequenceNr: index, image: data! as NSData)
                        }
                    }
                }
                
                task.resume()
            }
        }
    
        if let locationData = record[XYZExpense.loction] as? CLLocation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: locationData)
            
            expenseToBeUpdated?.setValue(data, forKey: XYZExpense.loction)
        }
        
        var ckshareFound: CKShare? = nil
        var ckshareFoundIndex: Int? = nil
        
        for (index, ckshare) in cksharesFoundButNoRootRecord.enumerated() {
            
            if ckshare.recordID.recordName == shareRecordId {
                
                ckshareFoundIndex = index
                ckshareFound = ckshare
                break
            }
        }
        
        if let _ = ckshareFound {
            
            if let shareUrl = ckshareFound?.url?.absoluteString {
                
                expenseToBeUpdated?.setValue(shareUrl, forKey: XYZExpense.shareUrl)
            }
            
            cksharesFoundButNoRootRecord.remove(at: ckshareFoundIndex!)
        }
        
        // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
        expenseToBeUpdated?.setValue(Date(), forKey: XYZExpense.lastRecordChange)
    } else if record.recordType == "cloudkit.share" {
        
        let recordName = record.recordID.recordName
        var found = false

        guard let ckshare = record as? CKShare else {
            
            fatalError("Exception: CKShare is expected")
        }
        
        for expense in expenseList {
            
            if let shareRecordId = expense.value(forKey: XYZExpense.shareRecordId) as? String, shareRecordId == recordName {

                if let shareUrl = ckshare.url?.absoluteString {
                
                    expense.setValue(shareUrl, forKey: XYZExpense.shareUrl)
                }
                
                found = true
                break
            }
        }
        
        if !found {

            cksharesFoundButNoRootRecord.append(ckshare)
        }
        
    } else {
        
        fatalError("Exception: \(record.recordType) is not supported")
    }
    
    return (outputExpenseList, outputUnprocessedCkrecords)
}

func createUpdateBudget(_ record: CKRecord,
                        _ budgetList: [XYZBudget],
                        _ context: NSManagedObjectContext) -> [XYZBudget] {
    
    let recordName = record.recordID.recordName
    let name = record[XYZBudget.name] as? String
    let amount = record[XYZBudget.amount] as? Double
    let start = record[XYZBudget.start] as? Date
    let length = record[XYZBudget.length] as? String
    let currency = record[XYZBudget.currency] as? String
    let sequenceNr = record[XYZBudget.sequenceNr] as? Int
    let color = record[XYZBudget.color] as? String ?? ""
    let dataAmount = record[XYZBudget.historicalAmount] as? Data ?? NSData() as Data
    let dataStart = record[XYZBudget.historicalStart] as? Data ?? NSData() as Data
    let dataLength = record[XYZBudget.historicalLength] as? Data ?? NSData() as Data
    let iconName = record[XYZBudget.iconName] as? String ?? ""
    
    var outputBudgetList: [XYZBudget] = budgetList
    var budgetToBeUpdated: XYZBudget?
    
    for budget in outputBudgetList {
        
        guard let recordId = budget.value(forKey: XYZBudget.recordId) as? String else {
            
            fatalError("Exception: record is expected")
        }
        
        if recordId == recordName {
            
            budgetToBeUpdated = budget
            break
        }
    }
    
    if nil == budgetToBeUpdated {
        
        budgetToBeUpdated = XYZBudget(id: recordName, name: name!, amount: amount!, currency: currency!, length: XYZBudget.Length(rawValue: length!)!, start: start!, sequenceNr: sequenceNr!, context: context)
        
        outputBudgetList.append(budgetToBeUpdated!)
    }
    
    budgetToBeUpdated?.setValue(name, forKey: XYZBudget.name)
    budgetToBeUpdated?.setValue(amount, forKey: XYZBudget.amount)
    budgetToBeUpdated?.setValue(currency, forKey: XYZBudget.currency)
    budgetToBeUpdated?.setValue(length, forKey: XYZBudget.length)
    budgetToBeUpdated?.setValue(sequenceNr, forKey: XYZBudget.sequenceNr)
    budgetToBeUpdated?.setValue(color, forKey: XYZBudget.color)
    budgetToBeUpdated?.setValue(dataStart, forKey: XYZBudget.historicalStart)
    budgetToBeUpdated?.setValue(dataAmount, forKey: XYZBudget.historicalAmount)
    budgetToBeUpdated?.setValue(dataLength, forKey: XYZBudget.historicalLength)
    budgetToBeUpdated?.setValue(iconName, forKey: XYZBudget.iconName)
    
    // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
    budgetToBeUpdated?.setValue(Date(), forKey: XYZBudget.lastRecordChange)
    
    return outputBudgetList
}

func fetchiCloudZoneChange(_ database: CKDatabase,
                           _ zones: [CKRecordZone],
                           _ icloudZones: [XYZiCloudZone],
                           _ completionblock: @escaping () -> Void ) {
 
    let aContext = managedContext()
    var changedZoneIDs: [CKRecordZone.ID] = []
    var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]()
    var unprocessedCkrecords = [CKRecord]()
    
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
        
        let option = CKFetchRecordZoneChangesOperation.ZoneOptions()
        option.previousServerChangeToken = changeToken
        
        optionsByRecordZoneID[zone.zoneID] = option
    }
    
    let opZoneChange = CKFetchRecordZoneChangesOperation(recordZoneIDs: changedZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID )
    
    opZoneChange.recordChangedBlock = { (record) in
        
        let ckrecordzone = CKRecordZone(zoneName: record.recordID.zoneID.zoneName)
        let icloudZone = GetiCloudZone(of: ckrecordzone,
                                       share: CKContainer.default().sharedCloudDatabase == database,
                                       icloudZones)
        
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
         
                let changeToken = icloudZone?.value(forKey: XYZiCloudZone.changeToken) as? Data
                
                (expenseList, unprocessedCkrecords) = createUpdateExpense(changeToken!,
                                                                          CKContainer.default().sharedCloudDatabase == database,
                                                                          record,
                                                                          expenseList,
                                                                          unprocessedCkrecords,
                                                                          aContext!)
                
                icloudZone?.data = expenseList
            
            case XYZBudget.type:
                guard var budgetList = icloudZone?.data as? [XYZBudget] else {
                    
                    fatalError("Exception: incomeList is expected")
                }
                
                budgetList = createUpdateBudget(record, budgetList, aContext!)
                icloudZone?.data = budgetList
            
            default:
                fatalError("Exception: zone type \(String(describing: zoneName)) is not supported")
        }
    }
    
    opZoneChange.recordWithIDWasDeletedBlock = { (recordId, recordType) in
    
        for icloudZone in icloudZones {
            
            if let zName = icloudZone.value(forKey: XYZiCloudZone.name) as? String, zName == recordId.zoneID.zoneName {

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
                            
                            // TODO: there are case that we do not get recordName
                            //guard let recordName = expense.value(forKey: XYZExpense.recordId) as? String else {
                                
                            //    fatalError("Exception: record id is expected")
                            //}
                            
                            let recordName = expense.value(forKey: XYZExpense.recordId) as? String
                            
                            if let _ = recordName, recordName == recordId.recordName {
                                
                                aContext?.delete(expense)
                                expenseList.remove(at: index)
                                
                                break
                            }
                        }
                    
                        icloudZone.data = expenseList
                    
                    case XYZExpensePerson.type:
                        guard let expenseList = icloudZone.data as? [XYZExpense] else {
                            
                            fatalError("Exception: expense is expected")
                        }
                        
                        let tokens = recordId.recordName.split(separator: "-")
                        var parentRecordName = ""
                        
                        for index in 0..<(tokens.count - 1) {
                            
                            if parentRecordName != "" {
                                
                                parentRecordName = parentRecordName + "-" + String(tokens[index])
                            } else {
                             
                                parentRecordName = String(tokens[index])
                            }
                        }
                        
                        for expense in expenseList {
                            
                            let recordId = expense.value(forKey: XYZExpense.recordId) as? String
                            
                            if recordId! == parentRecordName {
                                
                                let sequenceNr = Int(tokens[tokens.count - 1])
                                expense.removePerson(sequenceNr: sequenceNr!, context: aContext)
                                
                                break
                            }
                        }
                    
                    case XYZBudget.type:
                        guard var budgetList = icloudZone.data as? [XYZBudget] else {
                            
                            fatalError("Exception: [XYZBudget] is expected")
                        }
                        
                        for (index, budget) in budgetList.enumerated() {
                            
                            guard let recordName = budget.value(forKey: XYZBudget.recordId) as? String else {
                                fatalError("Exception: record id is expected")
                            }
                            
                            if recordName == recordId.recordName {
                                
                                aContext?.delete(budget)
                                budgetList.remove(at: index)
                                
                                break
                            }
                        }
                        
                        icloudZone.data = budgetList
                    
                    case "cloudkit.share":
                        break
                    
                    default:
                        fatalError("Exception: \(recordType) is not supported")
                }
            }
        }
    }
    
    opZoneChange.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
        
        print("----- token \(String(describing: token))")
        OperationQueue.main.addOperation {
            
            for icloudzone in icloudZones {
                
                if let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zName == zoneId.zoneName {
                    
                    var hasChangeToken = true;
                    
                    if let data = icloudzone.value(forKey: XYZiCloudZone.changeToken) as? Data {
                        
                        let previousChangeToken = (NSKeyedUnarchiver.unarchiveObject(with: data) as? CKServerChangeToken)
                        hasChangeToken = previousChangeToken != token!
                    }
                    
                    if hasChangeToken {
                        
                        let lastTokenFetchDate = Date()
                        
                        let archivedChangeToken = NSKeyedArchiver.archivedData(withRootObject: token! )
                        icloudzone.setValue(archivedChangeToken, forKey: XYZiCloudZone.changeToken)
                        icloudzone.setValue(lastTokenFetchDate, forKey: XYZiCloudZone.changeTokenLastFetch)
                    }
                    
                    break
                }
                
                saveManageContext() // save changed token and data
            }
        }
    }
    
    opZoneChange.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
        
        if let _ = error {
            
            let ckerror = error as? CKError
            
            switch ckerror! {
                
                case CKError.zoneNotFound:
                    
                    if CKContainer.default().sharedCloudDatabase == database {
                        
                        DispatchQueue.main.async {
                            
                            let appDelegate = UIApplication.shared.delegate as? AppDelegate
                            var shareiCloudZones = appDelegate?.shareiCloudZones
                        
                            for (index, icloudZone) in (shareiCloudZones?.enumerated())! {
                                
                                if let name = icloudZone.value(forKey: XYZiCloudZone.name) as? String, name == zoneId.zoneName {
                                    
                                    if let inShare = icloudZone.value(forKey: XYZiCloudZone.inShareDB) as? Bool, inShare && database == CKContainer.default().sharedCloudDatabase {
                                        
                                        aContext?.delete(icloudZone)
                                        shareiCloudZones?.remove(at: index)
                                        saveManageContext()
                                        
                                        break
                                    }
                                }
                            }
                            
                            appDelegate?.shareiCloudZones = shareiCloudZones!
                        }
                    }
                
                default:
                    break
            }
            
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

func GetiCloudZone(of zone: CKRecordZone,
                   share inShare: Bool,
                   _ icloudZones: [XYZiCloudZone]) -> XYZiCloudZone? {
    
    for icloudzone in icloudZones {
        
        if let name = icloudzone.value(forKey: XYZiCloudZone.name) as? String, zone.zoneID.zoneName == name {
            
            let isInShare = icloudzone.value(forKey: XYZiCloudZone.inShareDB) as? Bool ?? false
            
            if isInShare == inShare {
            
                return icloudzone
            }
        }
    }
    
    return nil
}

func pushChangeToiCloudZone(_ database: CKDatabase,
                            _ zones: [CKRecordZone],
                            _ icloudZones: [XYZiCloudZone],
                            _ completionblock: @escaping () -> Void) {
    
    for zone in zones {
        
        let name = zone.zoneID.zoneName
        guard let iCloudZone = GetiCloudZone(of: zone,
                                             share: CKContainer.default().sharedCloudDatabase == database,
                                             icloudZones) else {
            
            continue
        }
            
        switch name {
            
            case XYZAccount.type:
                    guard let incomeList = iCloudZone.data as? [XYZAccount] else {
                        
                        fatalError("Exception: [XYZAccount] is expected")
                    }
                    
                    saveAccountsToiCloud(database, zone, iCloudZone, incomeList, {
                        
                        OperationQueue.main.addOperation {
                            
                            fetchiCloudZoneChange(database, [zone], icloudZones, {
                                
                            })
                            
                            completionblock()
                        }
                    })
            
            case XYZExpense.type:
                guard let expenseList = iCloudZone.data as? [XYZExpense] else {
                    
                    fatalError("Exception: [XYZAccount] is expected")
                }
            
                saveExpensesToiCloud(database, zone, iCloudZone, expenseList, {
                    
                    OperationQueue.main.addOperation {

                        fetchiCloudZoneChange(database, [zone], icloudZones, {
                    
                            completionblock()
                        })
                    }
                })

            case XYZBudget.type:
                    guard let budgetList = iCloudZone.data as? [XYZBudget] else {
                        
                        fatalError("Exception: [XYZBudget] is expected")
                    }
                    
                    saveBudgetsToiCloud(database, zone, iCloudZone, budgetList, {
                        
                        OperationQueue.main.addOperation {
                            
                            fetchiCloudZoneChange(database, [zone], icloudZones, {
                                
                            })
                            
                            completionblock()
                        }
                    })
            
            default:
                fatalError("Exception: zone \(name) is not supported")
        }
    }
}

func fetchAndUpdateiCloud(_ database: CKDatabase,
                          _ zones: [CKRecordZone],
                          _ iCloudZones: [XYZiCloudZone],
                          _ completionblock: @escaping () -> Void) {
    
    if !iCloudZones.isEmpty {
        
        fetchiCloudZoneChange(database, zones, iCloudZones, {
            
            //we should only write to icloud if we do have changed after last token change
            OperationQueue.main.addOperation {
                
                pushChangeToiCloudZone(database, zones, iCloudZones, completionblock)
            }
        })
    }
}

func saveExpensesToiCloud(_ database: CKDatabase,
                          _ zone: CKRecordZone,
                          _ iCloudZone: XYZiCloudZone,
                          _ expenseList: [XYZExpense],
                          _ completionblock: @escaping () -> Void ) {
    
    var expenseListToBeSaved: [XYZExpense]?
    
    if let lastChangeTokenFetch = iCloudZone.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date {
        
        expenseListToBeSaved = [XYZExpense]()
        
        for expense in expenseList {
            
            if let lastChanged = expense.value(forKey: XYZExpense.lastRecordChange) as? Date {
                
                if lastChanged > lastChangeTokenFetch {
                    
                    expenseListToBeSaved?.append(expense)
                }
            } else {
                
                expenseListToBeSaved?.append(expense)
            }
        }
    } else {
        
        expenseListToBeSaved = expenseList
    }
    
    var recordIdsToBeDeleted = [CKRecord.ID]()
    
    guard let data = iCloudZone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
        
        fatalError("Exception: data is expected for deleteRecordIdList")
    }
    
    guard let deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }

    for deleteRecordName in deleteRecordLiset {
        
        if deleteRecordName != "" {
            
            let customZone = CKRecordZone(zoneName: XYZExpense.type)
            let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
            
            recordIdsToBeDeleted.append(ckrecordId)
        }
    }
    
    // delete share record
    guard let shareData = iCloudZone.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data else {
        
        fatalError("Exception: data is expected for deleteRecordIdList")
    }
    
    guard let deleteShareRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: shareData) as? [String]) else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteShareRecordLiset {
        
        if deleteRecordName != "" {
            
            let customZone = CKRecordZone(zoneName: XYZExpense.type)
            let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
            
            recordIdsToBeDeleted.append(ckrecordId)
        }
    }

    saveExpensesToiCloud(database, iCloudZone, expenseListToBeSaved!, recordIdsToBeDeleted, completionblock)
}

func saveExpensesToiCloud(_ database: CKDatabase,
                          _ iCloudZone: XYZiCloudZone,
                          _ expenseList: [XYZExpense],
                          _ recordIdsToBeDeleted: [CKRecord.ID],
                          _ completionblock: @escaping () -> Void ) {
    
    var recordsToBeSaved = [CKRecord]()
    var ckshares = [CKShare?]()
    var shareRecordIds = [String]()
    
    for expense in expenseList {
        
        let recordName = expense.value(forKey: XYZExpense.recordId) as? String
        let customZone = CKRecordZone(zoneName: XYZExpense.type)
        let ckrecordId = CKRecord.ID(recordName: recordName!, zoneID: customZone.zoneID)
        
        let record = CKRecord(recordType: XYZExpense.type, recordID: ckrecordId)
        
        let detail = expense.value(forKey: XYZExpense.detail) as? String
        let amount = expense.value(forKey: XYZExpense.amount) as? Double
        let date = expense.value(forKey: XYZExpense.date) as? Date
        let isSoftDelete = expense.value(forKey: XYZExpense.isSoftDelete) as? Bool
        let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool
        let currency = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
        let budget = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
        
        let recurring = expense.value(forKey: XYZExpense.recurring) as? String ?? XYZExpense.Length.none.rawValue
        let recurringStopDate = expense.value(forKey: XYZExpense.recurringStopDate) as? Date ?? date
        
        record.setValue(detail, forKey: XYZExpense.detail)
        record.setValue(amount, forKey: XYZExpense.amount)
        record.setValue(date, forKey: XYZExpense.date)
        record.setValue(currency, forKey: XYZExpense.currencyCode)
        record.setValue(budget, forKey: XYZExpense.budgetCategory)
        
        record.setValue(isSoftDelete, forKey: XYZExpense.isSoftDelete)
        record.setValue(isShared, forKey: XYZExpense.isShared)
        record.setValue(recurring, forKey: XYZExpense.recurring)
        record.setValue(recurringStopDate, forKey: XYZExpense.recurringStopDate)
    
        guard let receiptList = expense.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>  else {
            
            fatalError("Exception: [XYZExpenseReceipt] is expected")
        }
        
        let sortedReceiptList = receiptList.sorted(by: { (p1, p2) -> Bool in
        
            ( p1.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int)! < (p2.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int)!
        })
        
        var maxSequenceNr = 0
        for receipt in sortedReceiptList {

            let sequenceNr = receipt.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int
            
            maxSequenceNr = max(sequenceNr!, maxSequenceNr)
            
            let file = "image\(sequenceNr!)"
            let text = receipt.value(forKey: XYZExpenseReceipt.image) as? NSData
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
                let fileURL = dir.appendingPathComponent(file)
                text?.write(to: fileURL, atomically: true)
                
                let ckasset = CKAsset(fileURL: fileURL)
                record.setValue(ckasset, forKey: file)
            } else {
                
                fatalError("Exception: fail to get dir")
            }
        }
        
        record.setValue(maxSequenceNr + 1, forKey: XYZExpense.nrOfReceipts)
        
        let hasLocation = expense.value(forKey: XYZExpense.hasLocation) as? Bool ?? false
        
        record.setValue(hasLocation, forKey: XYZExpense.hasLocation)
        
        if hasLocation, let data = expense.value(forKey: XYZExpense.loction) as? Data {
            
            if let cllocation = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLLocation {
            
                record.setValue(cllocation, forKey: XYZExpense.loction)
            }
        }
        
        guard let personList = expense.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for person in personList {
            
            let sequenceNr = person.value(forKey: XYZExpensePerson.sequenceNr) as? Int
            let personRecordName = "\(recordName!)-\(sequenceNr!)"
            let personckrecordId = CKRecord.ID(recordName: personRecordName, zoneID: customZone.zoneID)
         
            let personRecord = CKRecord(recordType: XYZExpensePerson.type, recordID: personckrecordId)
            
            let email = person.value(forKey: XYZExpensePerson.email) as? String
            let name = person.value(forKey: XYZExpensePerson.name) as? String
            let paid = person.value(forKey: XYZExpensePerson.paid) as? Bool
            
            personRecord.setValue(email, forKey: XYZExpensePerson.email)
            personRecord.setValue(name, forKey: XYZExpensePerson.name)
            personRecord.setValue(paid, forKey: XYZExpensePerson.paid)
            personRecord.setValue(sequenceNr, forKey: XYZExpensePerson.sequenceNr)
            
            let ckreference = CKRecord.Reference(recordID: ckrecordId, action: .deleteSelf)
            personRecord.setValue(ckreference, forKey: XYZExpense.type)

            recordsToBeSaved.append(personRecord)
        }
        
        record.setValue(personList.count, forKey: XYZExpense.nrOfPersons)
        
        let shareRecordId = expense.value(forKey: XYZExpense.shareRecordId) as? String
        
        if nil == shareRecordId || shareRecordId == "" {
            
            let ckshare = CKShare(rootRecord: record)
            recordsToBeSaved.append(ckshare)
        
            ckshares.append(ckshare)
            shareRecordIds.append(ckshare.recordID.recordName)
            
            record.setValue(ckshare.recordID.recordName, forKey: XYZExpense.shareRecordId)
        } else {
            
            ckshares.append(nil)
            shareRecordIds.append("")
        }
        
        recordsToBeSaved.append(record)
    }
    
    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
        
        OperationQueue.main.addOperation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [String]())
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
            
            for (index, expense) in expenseList.enumerated() {
                
                if shareRecordIds[index] != "" {
                    
                    guard let ckshare = ckshares[index] else {
                        
                        fatalError("Exception: CKShare is expected")
                    }
                    
                    let url = ckshare.url?.absoluteString
                    
                    expense.setValue(url, forKey: XYZExpense.shareUrl)
                    expense.setValue(shareRecordIds[index], forKey: XYZExpense.shareRecordId)
                }
            }
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func saveAccountsToiCloud(_ database: CKDatabase,
                          _ zone: CKRecordZone,
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
 
    var recordIdsToBeDeleted = [CKRecord.ID]()
    
    guard let data = iCloudZone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
        
        fatalError("Exception: data is expected for deleteRecordIdList")
    }
    
    guard let deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteRecordLiset {
        
        let customZone = CKRecordZone(zoneName: XYZAccount.type)

        let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)

        recordIdsToBeDeleted.append(ckrecordId)
    }

    saveAccountsToiCloud(database, iCloudZone, incomeListToBeSaved!, recordIdsToBeDeleted, completionblock)
}

func saveAccountsToiCloud(_ database: CKDatabase,
                          _ iCloudZone: XYZiCloudZone,
                          _ incomeList: [XYZAccount],
                          _ recordIdsToBeDeleted: [CKRecord.ID],
                          _ completionblock: @escaping () -> Void ) {
    
    var recordsToBeSaved = [CKRecord]()

    for income in incomeList {

        let recordName = income.value(forKey: XYZAccount.recordId) as? String
        let customZone = CKRecordZone(zoneName: XYZAccount.type)
        let ckrecordId = CKRecord.ID(recordName: recordName!, zoneID: customZone.zoneID)

        let record = CKRecord(recordType: XYZAccount.type, recordID: ckrecordId)

        let bank = income.value(forKey: XYZAccount.bank) as? String
        let accountNr = income.value(forKey: XYZAccount.accountNr) as? String ?? ""
        let amount = income.value(forKey: XYZAccount.amount) as? Double
        let lastUpdate = income.value(forKey: XYZAccount.lastUpdate) as? Date
        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        let repeatDate = income.value(forKey: XYZAccount.repeatDate) as? Date
        let repeatAction = income.value(forKey: XYZAccount.repeatAction) as? String ?? ""
        let sequencNr = income.value(forKey: XYZAccount.sequenceNr) as? Int
        let principal = income.value(forKey: XYZAccount.principal) as? Double ?? 0.0
        
        record.setValue(sequencNr, forKey: XYZAccount.sequenceNr)
        record.setValue(bank, forKey: XYZAccount.bank)
        record.setValue(accountNr, forKey: XYZAccount.accountNr)
        record.setValue(amount, forKey: XYZAccount.amount)
        record.setValue(lastUpdate, forKey: XYZAccount.lastUpdate)
        record.setValue(currencyCode, forKey: XYZAccount.currencyCode)
        record.setValue(principal, forKey: XYZAccount.principal)

        if nil != repeatDate {

            record.setValue(repeatDate, forKey: XYZAccount.repeatDate)
            record.setValue(repeatAction, forKey: XYZAccount.repeatAction)
        } else {
            
            record.setValue(nil, forKey: XYZAccount.repeatDate)
            record.setValue("", forKey: XYZAccount.repeatAction)
        }

        recordsToBeSaved.append(record)
    }

    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
    
        OperationQueue.main.addOperation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [String]())
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteShareRecordIdList)
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func saveBudgetsToiCloud(_ database: CKDatabase,
                         _ zone: CKRecordZone,
                         _ iCloudZone: XYZiCloudZone,
                         _ budgetList: [XYZBudget],
                         _ completionblock: @escaping () -> Void ) {
    
    var budgetListToBeSaved: [XYZBudget]?
    
    if let lastChangeTokenFetch = iCloudZone.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date {
        
        budgetListToBeSaved = [XYZBudget]()
        
        for budget in budgetList {
            
            if let lastChanged = budget.value(forKey: XYZBudget.lastRecordChange) as? Date {
                
                if lastChanged > lastChangeTokenFetch {
                    
                    budgetListToBeSaved?.append(budget)
                }
            } else {
                
                budgetListToBeSaved?.append(budget)
            }
        }
    } else {
        
        budgetListToBeSaved = budgetList
    }
    
    var recordIdsToBeDeleted = [CKRecord.ID]()
    
    guard let data = iCloudZone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
        
        fatalError("Exception: data is expected for deleteRecordIdList")
    }
    
    guard let deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteRecordLiset {
        
        let customZone = CKRecordZone(zoneName: XYZBudget.type)
        
        let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
        
        recordIdsToBeDeleted.append(ckrecordId)
    }
    
    saveBudgetsToiCloud(database, iCloudZone, budgetListToBeSaved!, recordIdsToBeDeleted, completionblock)
}

func saveBudgetsToiCloud(_ database: CKDatabase,
                         _ iCloudZone: XYZiCloudZone,
                         _ budgetList: [XYZBudget],
                         _ recordIdsToBeDeleted: [CKRecord.ID],
                         _ completionblock: @escaping () -> Void ) {
    
    var recordsToBeSaved = [CKRecord]()
    
    for budget in budgetList {
        
        let recordName = budget.value(forKey: XYZBudget.recordId) as? String
        let customZone = CKRecordZone(zoneName: XYZBudget.type)
        let ckrecordId = CKRecord.ID(recordName: recordName!, zoneID: customZone.zoneID)
        
        let record = CKRecord(recordType: XYZBudget.type, recordID: ckrecordId)
        
        let name = budget.value(forKey: XYZBudget.name) as? String
        let amount = budget.value(forKey: XYZBudget.amount) as? Double
        let date = budget.value(forKey: XYZBudget.start) as? Date
        let currency = budget.value(forKey: XYZBudget.currency) as? String
        let sequenceNr = budget.value(forKey: XYZBudget.sequenceNr) as? Int
        let length = budget.value(forKey: XYZBudget.length) as? String
        let color = budget.value(forKey: XYZBudget.color) as? String ?? ""
        let iconName = budget.value(forKey: XYZBudget.iconName) as? String ?? ""
        
        let dataAmount = budget.value(forKey: XYZBudget.historicalAmount) as? Data ?? NSData() as Data
        record.setValue(dataAmount, forKey: XYZBudget.historicalAmount)
        
        let dataStart = budget.value(forKey: XYZBudget.historicalStart) as? Data ?? NSData() as Data
        record.setValue(dataStart, forKey: XYZBudget.historicalStart)
        
        let dataLength = budget.value(forKey: XYZBudget.historicalLength) as? Data ?? NSData() as Data
        record.setValue(dataLength, forKey: XYZBudget.historicalLength)
        
        record.setValue(name, forKey: XYZBudget.name)
        record.setValue(amount, forKey: XYZBudget.amount)
        record.setValue(date, forKey: XYZBudget.start)
        record.setValue(currency, forKey: XYZBudget.currency)
        record.setValue(length, forKey: XYZBudget.length)
        record.setValue(sequenceNr, forKey: XYZBudget.sequenceNr)
        record.setValue(color, forKey: XYZBudget.color)
        record.setValue(iconName, forKey: XYZBudget.iconName)
        
        recordsToBeSaved.append(record)
    }
    
    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
        
        OperationQueue.main.addOperation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: [String]())
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
            iCloudZone.setValue(data, forKey: XYZiCloudZone.deleteShareRecordIdList)
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func registeriCloudSubscription(_ database: CKDatabase,
                                _ iCloudZones: [XYZiCloudZone]) {
    
    for icloudzone in iCloudZones {
        
        guard let name = (icloudzone.value(forKey: XYZiCloudZone.name) as? String) else {
            
            fatalError("Exception: iCloud zone name is expected")
        }
        
        let ownerName = icloudzone.value(forKey: XYZiCloudZone.ownerName) as? String ?? ""
        
        var ckrecordzone: CKRecordZone?
        
        if ownerName == "" {
            
            ckrecordzone = CKRecordZone(zoneName: name)
        } else {
            
            ckrecordzone = CKRecordZone(zoneID: CKRecordZone.ID(zoneName: name, ownerName: ownerName))
        }
        
        let id = "\((ckrecordzone?.zoneID.zoneName)!)-\((ckrecordzone?.zoneID.ownerName)!)"
        let fetchOp = CKFetchSubscriptionsOperation.init(subscriptionIDs: [id])
        
        fetchOp.fetchSubscriptionCompletionBlock = {(subscriptionDict, error) -> Void in
            
            if let _ = subscriptionDict![id] {
                
            } else {

                let subscription = CKRecordZoneSubscription.init(zoneID: (ckrecordzone?.zoneID)!, subscriptionID: id)
                let notificationInfo = CKSubscription.NotificationInfo()
                
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
                operation.qualityOfService = .utility
                operation.completionBlock = {
                    
                }
                
                operation.modifySubscriptionsCompletionBlock = { subscriptions, strings, error in
                    
                    if let _ = error {
                        
                        print("******** modify subscription completion error = \(String(describing: error))")
                    }
                }
                
                database.add(operation)
            }
        }
        
        database.add(fetchOp)
    }
}

