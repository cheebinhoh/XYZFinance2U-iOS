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
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "biweekly"
        case monthly = "monthly"
        case halfyearly = "half yearly"
        case yearly = "yearly"
        
        func index() -> Int {
            
            switch self {
                
                case .none:
                    return 0
                
                case .daily:
                    return 1

                case .weekly:
                    return 2
                
                case .biweekly:
                    return 3

                case .monthly:
                    return 4
                
                case .halfyearly:
                    return 5
                
                case .yearly:
                    return 6
            }
        }
        
        func description() -> String {
            
            return self.rawValue
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
    static let color = "color"
    static let historicalAmount = "historicalAmount"
    static let historicalStart = "historicalStart"
    static let historicalLength = "historicalLength"
    
    var name: String = ""
    var amount: Double = 0.0
    var start: Date = Date()
    var length: Length = .none
    var lastRecordChange: Date = Date()
    var recordId: String = ""
    var currency: String = Locale.current.currencyCode ?? ""
    var sequenceNr: Int = 0
    var color: String = ""
    var historicalAmount = NSData()
    var historicalStart = NSData()
    var historicalLength = NSData()
    
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
            
            case .halfyearly:
                value = Calendar.current.date(byAdding: .month,
                                              value:-6,
                                              to: date!)
            
            case .yearly:
                value = Calendar.current.date(byAdding: .year,
                                              value:-1,
                                              to: date!)
        }

        return value
    }
    
    var currentEnd: Date? {
        
        let effectivebudget = self.getEffectiveBudgetDateAmount()
        var start = effectivebudget.Start ?? Date() //self.value(forKey: XYZBudget.start) as? Date ?? Date()
        let length = XYZBudget.Length(rawValue: self.value(forKey: XYZBudget.length) as? String ?? "none")
        var value: Date? = nil
        let currentDate = max(Date(), start)

        if let _ = effectivebudget.Start, length! != .none {
            
            repeat {
                
                if let _ = value {
                    
                    start = value!
                }
                
                switch length! {
                    case .none:
                        fatalError("Exception: .none is not expected here")
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
                    
                    case .halfyearly:

                        value = Calendar.current.date(byAdding: .month,
                                                      value:6,
                                                      to: start)
                    
                    case .yearly:
                        let startDateComponent = Calendar.current.dateComponents([.year], from: start)
                        let currentDateComponent = Calendar.current.dateComponents([.year], from: currentDate)
                        value = Calendar.current.date(byAdding: .year,
                                                      value:currentDateComponent.year! - startDateComponent.year! + 1,
                                                      to: start)
                }
            } while value! < currentDate
        }
        
        if let _ = value {
            
            return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month, .day], from: value!))
        } else {
            
            return value
        }
    }
    
    func getEffectiveBudgetDateAmount() -> (Length: String?, Start: Date?, Amount: Double?) {
        
        let dataAmount = self.value(forKey: XYZBudget.historicalAmount) as? Data ?? NSData() as Data
        let historicalAmount = (NSKeyedUnarchiver.unarchiveObject(with: dataAmount) as? [Double]) ?? [Double]()
        
        let dataStart = self.value(forKey: XYZBudget.historicalStart) as? Data ?? NSData() as Data
        let historicalStart = (NSKeyedUnarchiver.unarchiveObject(with: dataStart) as? [Date]) ?? [Date]()
        
        let dataLength = self.value(forKey: XYZBudget.historicalLength) as? Data ?? NSData() as Data
        let historicalLength = (NSKeyedUnarchiver.unarchiveObject(with: dataLength) as? [String]) ?? [String]()
        
        let length = self.value(forKey: XYZBudget.length) as? String ?? ""
        let amount = self.value(forKey: XYZBudget.amount) as? Double ?? 0.0
        let start = self.value(forKey: XYZBudget.start) as? Date ?? Date()
        
        return XYZBudget.getEffectiveBudgetDateAmount(length: length, start: start, amount: amount,
                                                      lengths: historicalLength.reversed(),
                                                      starts: historicalStart.reversed(),
                                                      amounts: historicalAmount.reversed())
    }
    
    static func getEffectiveBudgetDateAmount(length: String,
                                             start: Date,
                                             amount: Double,
                                             lengths: [String],
                                             starts: [Date],
                                             amounts: [Double]) -> (String?, Date?, Double?) {
        
        var retLength: String?
        var retAmount: Double?
        var retStart: Date?
        let now = Date()
        
        if now >= start {
            
            retStart = start
            retAmount = amount
            retLength = length
        } else {
            
            for (index, startElem) in starts.enumerated() {
                
                if now >= startElem {
                    retStart = startElem
                    retAmount = amounts[index]
                    retLength = lengths[index]
                    
                    break
                }
            }
        }
        
        return (retLength, retStart, retAmount)
    }
    
    func getAllBudgetDateAmount() -> (Int, [String], [Date], [Double]) {
        
        var dates = [Date]()
        var amounts = [Double]()
        var lengths = [String]()

        let dataAmount = self.value(forKey: XYZBudget.historicalAmount) as? Data ?? NSData() as Data
        amounts = (NSKeyedUnarchiver.unarchiveObject(with: dataAmount) as? [Double] ) ?? [Double]()
        
        let dataStart = self.value(forKey: XYZBudget.historicalStart) as? Data ?? NSData() as Data
        dates = (NSKeyedUnarchiver.unarchiveObject(with: dataStart) as? [Date] ) ?? [Date]()
        
        let dataLength = self.value(forKey: XYZBudget.historicalLength) as? Data ?? NSData() as Data
        lengths = (NSKeyedUnarchiver.unarchiveObject(with: dataLength) as? [String] ) ?? [String]()
        
        let date = self.value(forKey: XYZBudget.start) as? Date
        dates.append(date!)
        
        let amount = self.value(forKey: XYZBudget.amount) as? Double
        amounts.append(amount!)
        
        let length = self.value(forKey: XYZBudget.length) as? String
        lengths.append(length!)
        
        return (dates.count, lengths, dates, amounts)
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
        self.setValue("", forKey: XYZBudget.color)
        
        let dataAmount = NSKeyedArchiver.archivedData(withRootObject: [Double]() )
        self.setValue(dataAmount, forKey: XYZBudget.historicalAmount)
        
        let dataDate = NSKeyedArchiver.archivedData(withRootObject: [Date]() )
        self.setValue(dataDate, forKey: XYZBudget.historicalStart)
        
        let dataLength = NSKeyedArchiver.archivedData(withRootObject: [String]() )
        self.setValue(dataLength, forKey: XYZBudget.historicalLength)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
