//
//  XYZiCloudUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/9/19.
//  Copyright © 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import CloudKit

let cloudkitshareRecordType = "cloudkit.share"

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

func createUpdateAccount(record: CKRecord,
                         incomeList: [XYZAccount],
                         context: NSManagedObjectContext) -> [XYZAccount] {

    let recordName = record.recordID.recordName
    let bank = record[XYZAccount.bank] as? String
    let accountNr = record[XYZAccount.accountNr] as? String
    let amount = record[XYZAccount.amount] as? Double
    let lastUpdate = record[XYZAccount.lastUpdate] as? Date
    let currencyCode = record[XYZAccount.currencyCode] as? String
    let repeatDate = record[XYZAccount.repeatDate] as? Date
    let repeatAction = record[XYZAccount.repeatAction] as? String
    let principal = record[XYZAccount.principal] as? Double ?? 0.0
    let sequenceNr = record[XYZAccount.sequenceNr] as? Int
    
    var outputIncomeList: [XYZAccount] = incomeList
    var incomeToBeUpdated: XYZAccount?
    
    incomeToBeUpdated = outputIncomeList.first { (income) -> Bool in

        return income.recordId == recordName
    }

    
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
    
    incomeToBeUpdated?.sequenceNr = sequenceNr!
    incomeToBeUpdated?.amount = amount!
    incomeToBeUpdated?.lastUpdate = lastUpdate!
    incomeToBeUpdated?.currencyCode = currencyCode!
    incomeToBeUpdated?.recordId = recordName
    
    if repeatDate != nil {
        
        incomeToBeUpdated?.repeatDate = repeatDate!
        
        if let ra = XYZAccount.RepeatAction(rawValue: repeatAction ?? "") {
            
            incomeToBeUpdated?.repeatAction = ra
        } else {
            
            incomeToBeUpdated?.repeatAction = XYZAccount.RepeatAction.none
        }
    }

    // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
    incomeToBeUpdated?.lastRecordChange = Date()

    return outputIncomeList
}

func createUpdateExpense(record: CKRecord,
                         expenseList: [XYZExpense],
                         oldChangeToken: Data,
                         isShared: Bool,
                         unprocessedCKrecords: [CKRecord],
                         context: NSManagedObjectContext) -> ([XYZExpense], [CKRecord]) {
    
    var outputExpenseList: [XYZExpense] = expenseList
    var outputUnprocessedCkrecords: [CKRecord] = unprocessedCKrecords

    switch record.recordType {
    
        case XYZExpensePerson.type:
            let parentckreference = record[XYZExpense.type] as? CKRecord.Reference
          
            let expense = expenseList.first {
                
                let recordid = $0.value(forKey: XYZExpense.recordId) as? String
                
                return recordid == parentckreference?.recordID.recordName
            }
        
            if let expense = expense {
                
                let sequenceNr = record[XYZExpensePerson.sequenceNr] as? Int
                let name = record[XYZExpensePerson.name] as? String
                let email = record[XYZExpensePerson.email] as? String
                let paid = record[XYZExpensePerson.paid] as? Bool
                
                expense.addPerson(sequenceNr: sequenceNr!, name: name!, email: email!, paid: paid!, context: context)
            } else {
                
                outputUnprocessedCkrecords.append(record)
            }
            
        case XYZExpense.type:
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

            expenseToBeUpdated = outputExpenseList.first(where: { (expense) -> Bool in

                guard let recordId = expense.value(forKey: XYZExpense.recordId) as? String else {
                    
                    fatalError("Exception: record is expected")
                }
                
                return recordId == recordName
            })
            
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
                
                let data = try! NSKeyedArchiver.archivedData(withRootObject: locationData, requiringSecureCoding: false)
                
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
            
        case cloudkitshareRecordType:
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
            
        default:
            fatalError("Exception: \(record.recordType) is not supported")
    }// switch record.recordType
    
    return (outputExpenseList, outputUnprocessedCkrecords)
}

func createUpdateBudget(record: CKRecord,
                        budgetList: [XYZBudget],
                        context: NSManagedObjectContext) -> [XYZBudget] {
    
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
    
    budgetToBeUpdated = outputBudgetList.first(where: { (budget) -> Bool in
        
        return budget.recordId == recordName
    })
    
    if nil == budgetToBeUpdated {
        
        budgetToBeUpdated = XYZBudget(id: recordName, name: name!, amount: amount!, currency: currency!, length: XYZBudget.Length(rawValue: length!)!, start: start!, sequenceNr: sequenceNr!, context: context)
        
        outputBudgetList.append(budgetToBeUpdated!)
    }
    
    budgetToBeUpdated?.name = name ?? ""
    budgetToBeUpdated?.amount = amount!
    budgetToBeUpdated?.currency = currency!
    budgetToBeUpdated?.length = XYZBudget.Length(rawValue: length!) ?? XYZBudget.Length.none
    budgetToBeUpdated?.sequenceNr = sequenceNr!
    budgetToBeUpdated?.color = color
    budgetToBeUpdated?.historicalStart = dataStart
    budgetToBeUpdated?.historicalAmount = dataAmount
    budgetToBeUpdated?.historicalLength = dataLength
    budgetToBeUpdated?.iconName = iconName
    
    // the record change is updated but we save the last token fetch after that, so we are still up to date after fetching
    budgetToBeUpdated?.lastRecordChange = Date()
    
    return outputBudgetList
}

func fetchiCloudZoneChange(database: CKDatabase,
                           zones: [CKRecordZone],
                           icloudZones: [XYZiCloudZone],
                           completionblock: @escaping () -> Void ) {
 
    let aContext = managedContext()
    var changedZoneIDs: [CKRecordZone.ID] = []
    var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
    // [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneOptions]()
    var unprocessedCkrecords = [CKRecord]()
    
    for zone in zones {
        
        changedZoneIDs.append(zone.zoneID)
        
        var changeToken: CKServerChangeToken? = nil
        
        for icloudzone in icloudZones {
         
            if icloudzone.name == zone.zoneID.zoneName {
                
                let data = icloudzone.changeToken
                
                if data.count > 0 {
                
                    changeToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
                } else {
                    
                }
                
                break
            }
        }
        
        let option = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        option.previousServerChangeToken = changeToken
        
        optionsByRecordZoneID[zone.zoneID] = option
    }
    
    let opZoneChange = CKFetchRecordZoneChangesOperation(recordZoneIDs: changedZoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID)

    opZoneChange.recordChangedBlock = { (record) in
        
        let ckrecordzone = CKRecordZone(zoneName: record.recordID.zoneID.zoneName)
        let icloudZone = GetiCloudZone(of: ckrecordzone,
                                       share: CKContainer.default().sharedCloudDatabase == database,
                                       icloudZones: icloudZones)
        
        let zoneName = icloudZone?.name ?? ""
        
        switch zoneName {
            
            case XYZAccount.type:
                guard var incomeList = icloudZone?.data as? [XYZAccount] else {
                    
                    fatalError("Exception: incomeList is expected")
                }
            
                incomeList = createUpdateAccount(record: record, incomeList: incomeList, context: aContext!)
                icloudZone?.data = incomeList
            
            case XYZExpense.type:
                guard var expenseList = icloudZone?.data as? [XYZExpense] else {
                    
                    fatalError("Exception: expense is expected")
                }
         
                let changeToken = icloudZone?.changeToken
                
                (expenseList, unprocessedCkrecords) = createUpdateExpense(record: record,
                                                                          expenseList: expenseList,
                                                                          oldChangeToken: changeToken!,
                                                                          isShared: CKContainer.default().sharedCloudDatabase == database,
                                                                          unprocessedCKrecords:unprocessedCkrecords,
                                                                          context: aContext!)
                
                icloudZone?.data = expenseList
            
            case XYZBudget.type:
                guard var budgetList = icloudZone?.data as? [XYZBudget] else {
                    
                    fatalError("Exception: incomeList is expected")
                }
                
                budgetList = createUpdateBudget(record: record, budgetList: budgetList, context: aContext!)
                icloudZone?.data = budgetList
            
            default:
                fatalError("Exception: zone type \(String(describing: zoneName)) is not supported")
        }
    } // opZoneChange.recordChangedBlock = { (record) ...
    
    opZoneChange.recordWithIDWasDeletedBlock = { (recordId, recordType) in
    
        for icloudZone in icloudZones {
            
            if icloudZone.name == recordId.zoneID.zoneName {

                switch recordType {
                    
                    case XYZAccount.type:
                        guard var incomeList = icloudZone.data as? [XYZAccount] else {
                            
                            fatalError("Exception: [XYZAccount] is expected")
                        }
                    
                        for (index, income) in incomeList.enumerated() {
                            
                            if income.recordId == recordId.recordName {
                                
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
                            
                            if budget.recordId == recordId.recordName {
                                
                                aContext?.delete(budget)
                                budgetList.remove(at: index)
                                
                                break
                            }
                        }
                        
                        icloudZone.data = budgetList
                    
                    case cloudkitshareRecordType:
                        break
                    
                    default:
                        fatalError("Exception: \(recordType) is not supported")
                } // switch recordType {
            } // if let zName = icloudZone.value( ...
        } // for icloudZone in icloudZones
    } // opZoneChange.recordWithIDWasDeletedBlock = { (recordId, ...
    
    opZoneChange.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
        
        OperationQueue.main.addOperation {
            
            for icloudzone in icloudZones {
                
                if icloudzone.name == zoneId.zoneName {
                    
                    var hasChangeToken = true;
                    
                    let data = icloudzone.changeToken
                    if data.count > 0 {
                        
                        let previousChangeToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
                        hasChangeToken = previousChangeToken != token!
                    }
                    
                    if hasChangeToken {
                        
                        let lastTokenFetchDate = Date()
                        
                        let archivedChangeToken = try! NSKeyedArchiver.archivedData(withRootObject: token!, requiringSecureCoding: false)
                        icloudzone.changeToken = archivedChangeToken
                        icloudzone.changeTokenLastFetch = lastTokenFetchDate
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
                                
                                if icloudZone.name == zoneId.zoneName {
                                    
                                    if icloudZone.inShareDB
                                        && database == CKContainer.default().sharedCloudDatabase {
                                        
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
            } // switch ckerror!
            
            return
        } // if let _ = error
        
        OperationQueue.main.addOperation {
            
            for icloudzone in icloudZones {
                
                if icloudzone.name == zoneId.zoneName {
                    
                    var hasChangeToken = true;
              
                    let data = icloudzone.changeToken
                    
                    if data.count > 0 {
                        
                        let previousChangeToken = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
                        hasChangeToken = previousChangeToken != changeToken!
                    }
                    
                    if hasChangeToken {

                        let lastTokenFetchDate = Date()
                        
                        let archivedChangeToken = try! NSKeyedArchiver.archivedData(withRootObject: changeToken!, requiringSecureCoding: false)
                        icloudzone.changeToken = archivedChangeToken
                        icloudzone.changeTokenLastFetch = lastTokenFetchDate
                    }
                    
                    break
                }
                
                saveManageContext() // save changed token and data
            }
        }
    } // opZoneChange.recordZoneFetchCompletionBlock = { (zoneId,
    
    opZoneChange.fetchRecordZoneChangesCompletionBlock = { (error) in

        if let _ = error {
            
            return
        }
        
        completionblock()
    }
    
    database.add(opZoneChange)
}

func GetiCloudZone(of zone: CKRecordZone,
                   share inShare: Bool,
                   icloudZones: [XYZiCloudZone]) -> XYZiCloudZone? {
    
    for icloudzone in icloudZones {
        
        if zone.zoneID.zoneName == icloudzone.name {

            if icloudzone.inShareDB == inShare {
            
                return icloudzone
            }
        }
    }
    
    return nil
}

func pushChangeToiCloudZone(database: CKDatabase,
                            zones: [CKRecordZone],
                            icloudZones: [XYZiCloudZone],
                            completionblock: @escaping () -> Void) {
    
    for zone in zones {
        
        let name = zone.zoneID.zoneName
        guard let iCloudZone = GetiCloudZone(of: zone,
                                             share: CKContainer.default().sharedCloudDatabase == database,
                                             icloudZones: icloudZones) else {
            
            continue
        }
            
        switch name {
            
            case XYZAccount.type:
                guard let incomeList = iCloudZone.data as? [XYZAccount] else {
                    
                    fatalError("Exception: [XYZAccount] is expected")
                }
                
                saveAccountsToiCloud(database: database, zone: zone, iCloudZone: iCloudZone, incomeList: incomeList, completionblock: {
                    
                    OperationQueue.main.addOperation {
                        
                        fetchiCloudZoneChange(database: database, zones: [zone], icloudZones: icloudZones, completionblock: {
                            
                        })
                        
                        completionblock()
                    }
                })
            
            case XYZExpense.type:
                guard let expenseList = iCloudZone.data as? [XYZExpense] else {
                    
                    fatalError("Exception: [XYZAccount] is expected")
                }
            
                saveExpensesToiCloud(database: database, zone: zone, iCloudZone: iCloudZone, expenseList: expenseList, completionblock: {
                    
                    OperationQueue.main.addOperation {

                        fetchiCloudZoneChange(database: database, zones: [zone], icloudZones: icloudZones, completionblock: {
                    
                            completionblock()
                        })
                    }
                })

            case XYZBudget.type:
                guard let budgetList = iCloudZone.data as? [XYZBudget] else {
                    
                    fatalError("Exception: [XYZBudget] is expected")
                }
                
                saveBudgetsToiCloud(database: database, zone: zone, iCloudZone: iCloudZone, budgetList: budgetList, completionblock: {
                    
                    OperationQueue.main.addOperation {
                        
                        fetchiCloudZoneChange(database: database, zones: [zone], icloudZones: icloudZones, completionblock: {
                            
                        })
                        
                        completionblock()
                    }
                })
            
            default:
                fatalError("Exception: zone \(name) is not supported")
        } // switch name
    } // for zone in zones
}

func fetchAndUpdateiCloud(database: CKDatabase,
                          zones: [CKRecordZone],
                          iCloudZones: [XYZiCloudZone],
                          completionblock: @escaping () -> Void) {
    
    if !iCloudZones.isEmpty {
        
        fetchiCloudZoneChange(database: database, zones: zones, icloudZones: iCloudZones, completionblock: {
            
            //we should only write to icloud if we do have changed after last token change
            OperationQueue.main.addOperation {
                
                pushChangeToiCloudZone(database: database, zones: zones, icloudZones: iCloudZones, completionblock: completionblock)
            }
        })
    }
}

func saveExpensesToiCloud(database: CKDatabase,
                          zone: CKRecordZone,
                          iCloudZone: XYZiCloudZone,
                          expenseList: [XYZExpense],
                          completionblock: @escaping () -> Void ) {
    
    var expenseListToBeSaved: [XYZExpense]?
    
    //if let lastChangeTokenFetch = iCloudZone.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date {
    
    let lastChangeTokenFetch = iCloudZone.changeTokenLastFetch
    
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
    //} else {
        
    //    expenseListToBeSaved = expenseList
    //}
    
    var recordIdsToBeDeleted = [CKRecord.ID]()
    
    let data = iCloudZone.deleteRecordIdList

    guard let deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteRecordList {
        
        if deleteRecordName != "" {
            
            let customZone = CKRecordZone(zoneName: XYZExpense.type)
            let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
            
            recordIdsToBeDeleted.append(ckrecordId)
        }
    }
    
    // delete share record
    let shareData = iCloudZone.deleteShareRecordIdList

    guard let deleteShareRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(shareData) as? [String] else {
        
        fatalError("Exception: deleteShareRecordList is expected as [String]")
    }

    for deleteRecordName in deleteShareRecordList {
        
        if deleteRecordName != "" {
            
            let customZone = CKRecordZone(zoneName: XYZExpense.type)
            let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
            
            recordIdsToBeDeleted.append(ckrecordId)
        }
    }

    saveExpensesToiCloud(database: database,
                         iCloudZone: iCloudZone,
                         expenseList: expenseListToBeSaved!,
                         recordIdsToBeDeleted: recordIdsToBeDeleted,
                         completionblock: completionblock)
}

func saveExpensesToiCloud(database: CKDatabase,
                          iCloudZone: XYZiCloudZone,
                          expenseList: [XYZExpense],
                          recordIdsToBeDeleted: [CKRecord.ID],
                          completionblock: @escaping () -> Void ) {
    
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
            
            if let cllocation = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CLLocation {
            
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
    } // for expense in expenseList
    
    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
        
        OperationQueue.main.addOperation {
            
            let data = try! NSKeyedArchiver.archivedData(withRootObject: [String](), requiringSecureCoding: false)
            iCloudZone.deleteRecordIdList = data
            
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

func saveAccountsToiCloud(database: CKDatabase,
                          zone: CKRecordZone,
                          iCloudZone: XYZiCloudZone,
                          incomeList: [XYZAccount],
                          completionblock: @escaping () -> Void ) {
    
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
    
    let data = iCloudZone.deleteRecordIdList
    
    guard let deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }
    
    for deleteRecordName in deleteRecordList {
        
        let customZone = CKRecordZone(zoneName: XYZAccount.type)

        let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)

        recordIdsToBeDeleted.append(ckrecordId)
    }

    saveAccountsToiCloud(database: database,
                         iCloudZone: iCloudZone,
                         incomeList: incomeListToBeSaved!,
                         recordIdsToBeDeleted: recordIdsToBeDeleted,
                         completionblock: completionblock)
}

func saveAccountsToiCloud(database: CKDatabase,
                          iCloudZone: XYZiCloudZone,
                          incomeList: [XYZAccount],
                          recordIdsToBeDeleted: [CKRecord.ID],
                          completionblock: @escaping () -> Void ) {
    
    var recordsToBeSaved = [CKRecord]()

    for income in incomeList {

        let recordName = income.recordId
        let customZone = CKRecordZone(zoneName: XYZAccount.type)
        let ckrecordId = CKRecord.ID(recordName: recordName, zoneID: customZone.zoneID)

        let record = CKRecord(recordType: XYZAccount.type, recordID: ckrecordId)

        let bank = income.bank
        let accountNr = income.accountNr
        let amount = income.amount
        let lastUpdate = income.lastUpdate
        let currencyCode = income.currencyCode
        let repeatDate = income.repeatDate
        let repeatAction = income.repeatAction
        let sequencNr = income.sequenceNr
        let principal = income.principal
        
        record.setValue(sequencNr, forKey: XYZAccount.sequenceNr)
        record.setValue(bank, forKey: XYZAccount.bank)
        record.setValue(accountNr, forKey: XYZAccount.accountNr)
        record.setValue(amount, forKey: XYZAccount.amount)
        record.setValue(lastUpdate, forKey: XYZAccount.lastUpdate)
        record.setValue(currencyCode, forKey: XYZAccount.currencyCode)
        record.setValue(principal, forKey: XYZAccount.principal)

        if repeatDate != Date.distantPast {

            record.setValue(repeatDate, forKey: XYZAccount.repeatDate)
            record.setValue(repeatAction.rawValue, forKey: XYZAccount.repeatAction)
        } else {
            
            record.setValue(nil, forKey: XYZAccount.repeatDate)
            record.setValue("", forKey: XYZAccount.repeatAction)
        }

        recordsToBeSaved.append(record)
    } // for income in incomeList

    let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: recordIdsToBeDeleted)
    opToSaved.savePolicy = .allKeys
    opToSaved.completionBlock = {
    
        OperationQueue.main.addOperation {
            
            let data = try! NSKeyedArchiver.archivedData(withRootObject: [String](), requiringSecureCoding: false)
            iCloudZone.deleteRecordIdList = data
            iCloudZone.deleteShareRecordIdList = data
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func saveBudgetsToiCloud(database: CKDatabase,
                         zone: CKRecordZone,
                         iCloudZone: XYZiCloudZone,
                         budgetList: [XYZBudget],
                         completionblock: @escaping () -> Void ) {
    
    var budgetListToBeSaved: [XYZBudget]?
    
    //if let lastChangeTokenFetch = iCloudZone.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date {
    
    let lastChangeTokenFetch = iCloudZone.changeTokenLastFetch
    
        budgetListToBeSaved = [XYZBudget]()
        
        for budget in budgetList {
            
            if budget.lastRecordChange > lastChangeTokenFetch {
                
                budgetListToBeSaved?.append(budget)
            }
        }
    //} else {
        
    //    budgetListToBeSaved = budgetList
    //}
    
    var recordIdsToBeDeleted = [CKRecord.ID]()
    
    let data = iCloudZone.deleteRecordIdList

    guard let deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
        
        fatalError("Exception: deleteRecordList is expected as [String]")
    }

    for deleteRecordName in deleteRecordList {
        
        let customZone = CKRecordZone(zoneName: XYZBudget.type)
        
        let ckrecordId = CKRecord.ID(recordName: deleteRecordName, zoneID: customZone.zoneID)
        
        recordIdsToBeDeleted.append(ckrecordId)
    }
    
    
    saveBudgetsToiCloud(database: database,
                        iCloudZone: iCloudZone,
                        budgetList: budgetListToBeSaved!,
                        recordIdsToBeDeleted: recordIdsToBeDeleted,
                        completionblock: completionblock)
}

func saveBudgetsToiCloud(database: CKDatabase,
                         iCloudZone: XYZiCloudZone,
                         budgetList: [XYZBudget],
                         recordIdsToBeDeleted: [CKRecord.ID],
                         completionblock: @escaping () -> Void ) {
    
    var recordsToBeSaved = [CKRecord]()
    
    for budget in budgetList {
        
        let recordName = budget.recordId
        let customZone = CKRecordZone(zoneName: XYZBudget.type)
        let ckrecordId = CKRecord.ID(recordName: recordName, zoneID: customZone.zoneID)
        
        let record = CKRecord(recordType: XYZBudget.type, recordID: ckrecordId)
        
        let name = budget.name
        let amount = budget.amount
        let date = budget.start
        let currency = budget.currency
        let sequenceNr = budget.sequenceNr
        let length = budget.length.rawValue
        let color = budget.color
        let iconName = budget.iconName
        
        let dataAmount = budget.historicalAmount
        record.setValue(dataAmount, forKey: XYZBudget.historicalAmount)
        
        let dataStart = budget.historicalStart
        record.setValue(dataStart, forKey: XYZBudget.historicalStart)
        
        let dataLength = budget.historicalLength
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
            
            let data = try! NSKeyedArchiver.archivedData(withRootObject: [String](), requiringSecureCoding: false)
            iCloudZone.deleteRecordIdList = data
            iCloudZone.deleteShareRecordIdList = data
            
            saveManageContext() // save the iCloudZone to indicate that deleteRecordIdList is executed.
            
            completionblock()
        }
    }
    
    database.add(opToSaved)
}

func registeriCloudSubscription(database: CKDatabase,
                                iCloudZones: [XYZiCloudZone]) {
    
    for icloudzone in iCloudZones {
        
        let name = icloudzone.name
        
        let ownerName = icloudzone.ownerName
        
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
                        
                    }
                }
                
                database.add(operation)
            }
        }
        
        database.add(fetchOp)
    } // for icloudzone in iCloudZones
}

