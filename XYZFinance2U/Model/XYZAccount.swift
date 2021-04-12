//
//  XYZAccount.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CloudKit

@objc(XYZAccount)
class XYZAccount : NSManagedObject {
    
    enum RepeatAction: String {
        
        case none
        case hourly
        case daily
        case weekly
        case biweekly
        case monthly
        case yearly
        
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
    static let principal = "principal"
    static let recordId = "recordId"
    static let repeatAction = "repeatAction"
    static let repeatDate = "repeatDate"
    static let sequenceNr = "sequenceNr"

    // MARK: - property
    
    var accountNr: String {
    
        get {
            
            return self.value(forKey: XYZAccount.accountNr) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.accountNr)
        }
    }
    
    var amount: Double {
        
        get {
            
            return self.value(forKey: XYZAccount.amount) as? Double ?? 0.0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.amount)
        }
    }
    
    var bank: String {
    
        get {
            
            return self.value(forKey: XYZAccount.bank) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.bank)
        }
    }
    
    var currencyCode: String = Locale.current.currencyCode!
    var lastRecordChange = Date()
    var lastUpdate = Date()
    var principal = 0.0
    var recordId = ""
    var repeatAction = ""
    var repeatDate = Date()
    var sequenceNr = 0
    
    // MARK: - function
    
    init(id: String?,
         sequenceNr: Int,
         bank: String,
         accountNr: String,
         amount: Double,
         principal: Double,
         date: Date,
         context: NSManagedObjectContext?) {

        let recordName = id ?? UUID.init().uuidString
        let entity = NSEntityDescription.entity(forEntityName: XYZAccount.type,
                                                in: context!)!
        
        super.init(entity: entity, insertInto: context!)
        
        self.setValue(recordName, forKey: XYZAccount.recordId)
        self.bank = bank
        self.amount = amount
        self.accountNr = accountNr
        self.setValue(date, forKey: XYZAccount.lastUpdate)
        self.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
        self.setValue(principal, forKey: XYZAccount.principal)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}
