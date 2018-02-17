//
//  XYZBudget.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import Foundation
import os.log
import CoreData
import CloudKit

@objc(XYZBudget)
class XYZBudget : NSManagedObject {

    enum Length: String {
        
        case none = "none"
        case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        func description() -> String {
            
            switch self {
                
            case .none:
                return "none"
            
            case .hourly:
                return "hourly"
                
            case .daily:
                return "daily"
                
            case .weekly:
                return "weekly"
                
            case .biweekly:
                return "biweekly"
                
            case .monthly:
                return "monthly"
                
            case .yearly:
                return "yearly"
            }
        }
    }
    
    // MARK: - static property
    
    static let type = "XYZBudget"
    static let name = "name"
    static let amount = "amount"
    static let currency = "currency"
    static let length = "length"
    static let start = "start"
    static let recordId = "recordId"
    static let lastRecordChange = "lastRecordChange"
    static let sequenceNr = "sequenceNr"
    
    var name: String = ""
    var amount: Double = 0.0
    var start: Date = Date()
    var length: Length = .none
    var lastRecordChange: Date = Date()
    var recordId: String = ""
    var currency: String = Locale.current.currencyCode ?? ""
    var sequenceNr: Int = 0
    
    // MARK: - function
    
    init(id: String?,
         name: String,
         amount: Double,
         currency: String,
         length: XYZBudget.Length,
         start: Date,
         sequenceNr: Int,
         context: NSManagedObjectContext?) {
        
        let aContext = context!
        
        let entity = NSEntityDescription.entity(forEntityName: XYZBudget.type,
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        var recordName = ""
        
        if nil == id {
            
            recordName = UUID.init().uuidString
        } else {
            
            recordName = id!
        }
        
        self.setValue(recordName, forKey: XYZBudget.recordId)
        self.setValue(name, forKey: XYZBudget.name)
        self.setValue(amount, forKey: XYZBudget.amount)
        self.setValue(length.rawValue, forKey: XYZBudget.length)
        self.setValue(currency, forKey: XYZBudget.currency)
        self.setValue(start, forKey: XYZBudget.start)
        self.setValue(sequenceNr, forKey: XYZBudget.sequenceNr)
        self.setValue(Date(), forKey: XYZBudget.lastRecordChange)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
