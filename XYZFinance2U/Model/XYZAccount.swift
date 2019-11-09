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
    var principal: Double = 0.0
    var recordId: String = ""
    var repeatAction: String = ""
    var repeatDate: Date = Date()
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
        self.setValue(bank, forKey: XYZAccount.bank)
        self.setValue(amount, forKey:XYZAccount.amount)
        self.setValue(accountNr, forKey: XYZAccount.accountNr)
        self.setValue(date, forKey: XYZAccount.lastUpdate)
        self.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
        self.setValue(principal, forKey: XYZAccount.principal)
    }
    
     override init(entity: NSEntityDescription,
                   insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
