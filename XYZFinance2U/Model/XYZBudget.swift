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
        //DEPRECATED:
        //case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        case yearly = "yearly"
        
        func description() -> String {
            
            switch self {
                
            case .none:
                return "none"
            
            //DEPRECATED:
            //case .hourly:
            //    return "hourly"
                
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
    
    var currentStart: Date? {
        
        var value: Date? = nil
        let date = self.currentEnd
        let length = XYZBudget.Length(rawValue: self.value(forKey: XYZBudget.length) as? String ?? "none")
        
        switch length! {
            case .none:
                break
            
            case .daily:
                value = Calendar.current.date(byAdding: .day,
                                              value:-1,
                                              to: date!)
            
            case .weekly:
                value = Calendar.current.date(byAdding: .weekOfYear,
                                              value:-1,
                                              to: date!)
            
            case .biweekly:
                value = Calendar.current.date(byAdding: .weekOfYear,
                                              value:-2,
                                              to: date!)
            
            case .monthly:
                value = Calendar.current.date(byAdding: .month,
                                              value:-1,
                                              to: date!)
            
            case .yearly:
                value = Calendar.current.date(byAdding: .year,
                                              value:-1,
                                              to: date!)
        }
        
        return value
    }
    
    var currentEnd: Date? {
        
        let start = self.value(forKey: XYZBudget.start) as? Date ?? Date()
        let length = XYZBudget.Length(rawValue: self.value(forKey: XYZBudget.length) as? String ?? "none")
        var value: Date? = nil
        let currentDate = max(Date(), start)

        switch length! {
            case .none:
                break
            
            case .daily:
                let startDateComponent = Calendar.current.dateComponents([.day], from: start)
                let currentDateComponent = Calendar.current.dateComponents([.day], from: currentDate)
                value = Calendar.current.date(byAdding: .day,
                                              value:currentDateComponent.day! - startDateComponent.day! + 1,
                                              to: start)
            
            case .weekly:
                let startDateComponent = Calendar.current.dateComponents([.weekOfYear], from: start)
                let currentDateComponent = Calendar.current.dateComponents([.weekOfYear], from: currentDate)
                value = Calendar.current.date(byAdding: .weekOfYear,
                                              value:currentDateComponent.weekOfYear! - startDateComponent.weekOfYear! + 1,
                                              to: start)
            
            case .biweekly:
                let startDateComponent = Calendar.current.dateComponents([.weekOfYear], from: start)
                let currentDateComponent = Calendar.current.dateComponents([.weekOfYear], from: currentDate)
                value = Calendar.current.date(byAdding: .weekOfYear,
                                              value:currentDateComponent.weekOfYear! - startDateComponent.weekOfYear! + 2,
                                              to: start)
            
            case .monthly:
                let startDateComponent = Calendar.current.dateComponents([.month], from: start)
                let currentDateComponent = Calendar.current.dateComponents([.month], from: currentDate)
                value = Calendar.current.date(byAdding: .month,
                                              value:currentDateComponent.month! - startDateComponent.month! + 1,
                                              to: start)
            
            case .yearly:
                let startDateComponent = Calendar.current.dateComponents([.year], from: start)
                let currentDateComponent = Calendar.current.dateComponents([.year], from: currentDate)
                value = Calendar.current.date(byAdding: .year,
                                              value:currentDateComponent.year! - startDateComponent.year! + 1,
                                              to: start)
        }
        
        if let _ = value {
            
            return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: value!))
        } else {
            
            return value
        }
    }
    
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
