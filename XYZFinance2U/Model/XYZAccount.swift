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
    
    var currencyCode: String {
        
        get {
            
            return self.value(forKey: XYZAccount.currencyCode) as? String ?? Locale.current.currencyCode!
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.currencyCode)
        }
    }
    
    var lastRecordChange: Date {
        
        get {
            
            return self.value(forKey: XYZAccount.lastRecordChange) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.lastRecordChange)
        }
    }
    
    var lastUpdate: Date {
        
        get {
            
            return self.value(forKey: XYZAccount.lastUpdate) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.lastUpdate)
        }
    }
    
    var principal: Double {
        
        get {
            
            return self.value(forKey: XYZAccount.principal) as? Double ?? 0.0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.principal)
        }
    }
    
    var recordId: String {
        
        get {
            
            return self.value(forKey: XYZAccount.recordId) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.recordId)
        }
    }
    
    var repeatAction: XYZAccount.RepeatAction {
        
        get {
            
            let rawValue = self.value(forKey: XYZAccount.repeatAction) as? String ?? XYZAccount.RepeatAction.none.rawValue
            
            return XYZAccount.RepeatAction(rawValue: rawValue) ?? XYZAccount.RepeatAction.none
        }
        
        set {
            
            self.setValue(newValue.rawValue, forKey: XYZAccount.repeatAction)
        }
    }
    
    var repeatDate: Date {
        
        get {
            
            return self.value(forKey: XYZAccount.repeatDate) as? Date ?? Date.distantPast
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.repeatDate)
        }
    }
    
    var sequenceNr: Int {
        
        get {
            
            return self.value(forKey: XYZAccount.sequenceNr) as? Int ?? 0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZAccount.sequenceNr)
        }
    }
    
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
        
        self.recordId = recordName
        self.bank = bank
        self.amount = amount
        self.accountNr = accountNr
        self.lastUpdate = date
        self.sequenceNr = sequenceNr
        self.principal = principal
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {

        super.init(entity: entity, insertInto: context)
    }
}
