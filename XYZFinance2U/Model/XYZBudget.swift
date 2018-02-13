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

    enum Interval: Int {
        
        case none
        case hourly
        case daily
        case weekly
        case biweekly
        case monthly
        case yearly
        
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
    static let interval = "interval"
    static let recordId = "recordId"
    static let lastRecordChange = "lastRecordChange"
    
    var name: String = ""
    var amount: Double = 0.0
    var interval: Interval = .none
    var lastRecordChange: Date = Date()
    var recordId: String = ""
    var currency: String = Locale.current.currencyCode ?? ""
    
    // MARK: - function
    
    init(id: String?,
         name: String,
         amount: Double,
         currency: String,
         interval: Interval,
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
        self.setValue(interval.rawValue, forKey: XYZBudget.interval)
        self.setValue(currency, forKey: XYZBudget.currency)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
