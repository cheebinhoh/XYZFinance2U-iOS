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

func fetchiCloudZoneChange(_ zones: [CKRecordZone],
                           _ icloudZones: [XYZiCloudZone],
                           _ completionblock: @escaping () -> Void ) {
    
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
                
                let data = icloudzone.value(forKey: XYZiCloudZone.changeToken) as? Data
                changeToken = (NSKeyedUnarchiver.unarchiveObject(with: data!) as? CKServerChangeToken)
                
                break
            }
        }
        
        let option = CKFetchRecordZoneChangesOptions()
        option.previousServerChangeToken = changeToken
        
        optionsByRecordZoneID[zone.zoneID] = option
    }
    
    saveManageContext()
    
    let opZoneChange = CKFetchRecordZoneChangesOperation(recordZoneIDs: changedZoneIDs, optionsByRecordZoneID: optionsByRecordZoneID )
    
    opZoneChange.recordChangedBlock = { (record) in
        print("Record changed:", record)
        
    }
    
    opZoneChange.recordWithIDWasDeletedBlock = { (recordId, str) in
        print("Record deleted:", recordId)
        
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
            
            for zone in icloudZones {
                
                if let zName = zone.value(forKey: XYZiCloudZone.name) as? String, zName == zoneId.zoneName {
                    
                    print("-------- change token \(changeToken!)")
                    let archivedChangeToken = NSKeyedArchiver.archivedData(withRootObject: changeToken! )
                    zone.setValue(archivedChangeToken, forKey: XYZiCloudZone.changeToken)
                    zone.setValue(Date(), forKey: XYZiCloudZone.changeTokenLastFetch)
                    
                    saveManageContext()
                    
                    break
                }
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

func saveAccountsToiCloud(_ completionblock: @escaping () -> Void ) {
    
    let container = CKContainer.default()
    let database = container.privateCloudDatabase
    
    if let incomeList = loadAccounts() {
     
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

            record.setValue(bank, forKey: XYZAccount.bank)
            record.setValue(accountNr, forKey: XYZAccount.accountNr)
            record.setValue(amount, forKey: XYZAccount.amount)
            record.setValue(lastUpdate, forKey: XYZAccount.lastUpdate)
            record.setValue(currencyCode, forKey: XYZAccount.currencyCode)

            let uploadDate = Date()
            record.setValue(uploadDate, forKey: XYZAccount.lastRecordUpload)

            if nil != repeatDate {

                record.setValue(repeatDate, forKey: XYZAccount.repeatDate)
                record.setValue(repeatAction, forKey: XYZAccount.repeatAction)
            }

            recordsToBeSaved.append(record)
        }

        let opToSaved = CKModifyRecordsOperation(recordsToSave: recordsToBeSaved, recordIDsToDelete: nil)
        opToSaved.savePolicy = .allKeys
        opToSaved.completionBlock = {

            completionblock()
        }
        
        database.add(opToSaved)
    }
}

func loadAccounts() -> [XYZAccount]? {
    
    var output: [XYZAccount]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZAccount>(entityName: "XYZAccount")
    
    do {
        
        output = try aContext?.fetch(fetchRequest)
        
        output = output?.sorted() {
            (acc1, acc2) in
            
            return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
        }
    } catch let error as NSError {
        
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    let delegate = UIApplication.shared.delegate as? AppDelegate
    
    if (delegate?.icloudEnable)! {
        
        /*
        // process icloud records
        for income in output! {
            
            income.saveToiCloud()
        }
    
        // save subscription
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.fetchAllSubscriptions(completionHandler: { (subscriptions, error) in
        
            if nil != error {
                
                print("-------- error on fetching subscriptions = \(String(describing: error))")
            } else {
                
                if let subscriptions = subscriptions {
                    
                    for subscription in subscriptions {
                        
                        database.delete(withSubscriptionID: subscription.subscriptionID, completionHandler: { (str, error) in
                        
                            if nil != error {
                                
                                print("------- error on deleting subscription = \(String(describing: error))")
                            }
                        })
                    }
                }
            }
        })
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: XYZAccount.type, predicate: predicate, options: .firesOnRecordUpdate)
        let notification = CKNotificationInfo()
        notification.title = "Income update"
        notification.alertBody = "There is update to Incomes"
        notification.soundName = "default"
        subscription.notificationInfo = notification
        
        database.save(subscription, completionHandler: { (subscription, error) in
            
            if nil != error {
                
                print("------- error on saving subscription \(String(describing: error))")
            }
        })
        
        */
    } else {
        
        // nothing here
    }
    
    return output
}

