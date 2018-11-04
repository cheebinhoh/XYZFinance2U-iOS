//
//  XYZAccount.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CloudKit

@objc(XYZAccount)
class XYZAccount : NSManagedObject {
    
    enum RepeatAction: String {
        
        case none = "none"
        case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        func description() -> String {
            
            return self.rawValue
        }
    }
    
    // MARK: - static property
    
    static let type = "XYZAccount"

    static let accountNr = "accountNr"
    static let amount = "amount"
    static let bank = "bank"
    static let currencyCode = "currencyCode"
    static let lastRecordChange = "lastRecordChange"
    static let lastUpdate = "lastUpdate"
    static let recordId = "recordId"
    static let repeatDate = "repeatDate"
    static let repeatAction = "repeatAction"
    static let sequenceNr = "sequenceNr"


    // MARK: - property
    
    var accountNr: String = ""
    var amount: Double = 0.0
    var bank: String = ""
    var currencyCode: String = Locale.current.currencyCode!
    var lastRecordChange: Date = Date()
    var lastUpdate: Date = Date()
    var recordId: String = ""
    var repeatAction: String = ""
    var repeatDate: Date = Date()
    var sequenceNr = 0
    
    
    // MARK: - function
    
    init(id: String?, sequenceNr: Int,
         bank: String, accountNr: String,
         amount: Double,
         date: Date,
         context: NSManagedObjectContext?) {
        
        let aContext = context!

        let entity = NSEntityDescription.entity(forEntityName: XYZAccount.type,
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        var recordName = ""
        
        if nil == id {
            
            recordName = UUID.init().uuidString
        } else {
            
            recordName = id!
        }
        
        self.setValue(recordName, forKey: XYZAccount.recordId)
        self.setValue(bank, forKey: XYZAccount.bank)
        self.setValue(amount, forKey:XYZAccount.amount)
        self.setValue(accountNr, forKey: XYZAccount.accountNr)
        self.setValue(date, forKey: XYZAccount.lastUpdate)
        self.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    /* DEPRECATED
    func saveToiCloud() {
        
        let recordName = self.value(forKey: XYZAccount.recordId) as? String
        let ckrecordId = CKRecordID(recordName: recordName!)
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.fetch(withRecordID: ckrecordId, completionHandler: { (existingRecord, error) in
            
            var record = existingRecord
            
            if nil != error {

                record = CKRecord(recordType: XYZAccount.type, recordID: ckrecordId)
            } else {

                // do nothing
            }
            
            let bank = self.value(forKey: XYZAccount.bank) as? String
            let accountNr = self.value(forKey: XYZAccount.accountNr) as? String ?? ""
            let amount = self.value(forKey: XYZAccount.amount) as? Double
            let lastUpdate = self.value(forKey: XYZAccount.lastUpdate) as? Date
            let currencyCode = self.value(forKey: XYZAccount.currencyCode) as? String
            let repeatDate = self.value(forKey: XYZAccount.repeatDate) as? Date
            let repeatAction = self.value(forKey: XYZAccount.repeatAction) as? String
            
            record?.setValue(bank, forKey: XYZAccount.bank)
            record?.setValue(accountNr, forKey: XYZAccount.accountNr)
            record?.setValue(amount, forKey: XYZAccount.amount)
            record?.setValue(lastUpdate, forKey: XYZAccount.lastUpdate)
            record?.setValue(currencyCode, forKey: XYZAccount.currencyCode)

            let uploadDate = Date()
            record?.setValue(uploadDate, forKey: XYZAccount.lastRecordUpload)
            
            if nil != repeatDate {
                
                record?.setValue(repeatDate, forKey: XYZAccount.repeatDate)
                record?.setValue(repeatAction, forKey: XYZAccount.repeatAction)
            }
        
            let modifyOperation = CKModifyRecordsOperation(recordsToSave: [record!], recordIDsToDelete: [])
            modifyOperation.savePolicy = .ifServerRecordUnchanged
            modifyOperation.modifyRecordsCompletionBlock = { ( saveRecords, deleteRecords, error ) in
                
                if nil != error {
                    
                    print("-------- error on saving to icloud \(String(describing: error))")
                } else {
                    
                    print("-------- save done for records" )
                }
            }
            
            let blockOperation = BlockOperation(block: {
                
                self.setValue(uploadDate, forKey: XYZAccount.lastRecordUpload)
                saveManageContext()
            })
            
            blockOperation.addDependency(modifyOperation)
            OperationQueue.main.addOperation(blockOperation)
            
            database.add(modifyOperation)
        })
    }
     */
}
