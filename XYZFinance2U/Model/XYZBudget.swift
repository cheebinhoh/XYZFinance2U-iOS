//
//  XYZBudget.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CloudKit

@objc(XYZBudget)
class XYZBudget: NSManagedObject {

    enum Length: String, CaseIterable {
        
        case none
        case daily
        case weekly
        case biweekly
        case monthly
        case halfyearly = "half yearly"
        case yearly
        
        var index: Int {
            
            return Length.allCases.firstIndex(of: self)!
        }
        
        func description() -> String {
            
            return self.rawValue
        }
    }
    
    // MARK: - static property
    
    static let type = "XYZBudget"
  
    static let amount = "amount"
    static let color = "color"
    static let currency = "currency"
    static let historicalAmount = "historicalAmount"
    static let historicalLength = "historicalLength"
    static let historicalStart = "historicalStart"
    static let iconName = "iconName"
    static let lastRecordChange = "lastRecordChange"
    static let length = "length"
    static let name = "name"
    static let recordId = "recordId"
    static let sequenceNr = "sequenceNr"
    static let start = "start"
    
    var amount: Double {
        
        get {
            
            return self.value(forKey: XYZBudget.amount) as? Double ?? 0.0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.amount)
        }
    }
    
    var color: String {
        
        get {
            
            return self.value(forKey: XYZBudget.color) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.color)
        }
    }
    
    var currency: String {
        
        get {
            
            return self.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode!
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.currency)
        }
    }
    
    var historicalAmount: Data {
        
        get {
            
            return self.value(forKey: XYZBudget.historicalAmount) as? Data ?? NSData() as Data
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.historicalAmount)
        }
    }
    
    var historicalStart: Data {
        
        get {
            
            return self.value(forKey: XYZBudget.historicalStart) as? Data ?? NSData() as Data
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.historicalStart)
        }
    }
    
    var historicalLength: Data {
        
        get {
            
            return self.value(forKey: XYZBudget.historicalLength) as? Data ?? NSData() as Data
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.historicalLength)
        }
    }
    
    var iconName: String {
        
        get {
            
            return self.value(forKey: XYZBudget.iconName) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.iconName)
        }
    }
    
    var lastRecordChange: Date {
        
        get {
            
            return self.value(forKey: XYZBudget.lastRecordChange) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.lastRecordChange)
        }
    }
    
    var length: Length {
        
        get {
            
            let rawValue = self.value(forKey: XYZBudget.length) as? String ?? XYZBudget.Length.none.rawValue
            
            return XYZBudget.Length(rawValue: rawValue)!
        }
        
        set {
            
            self.setValue(newValue.rawValue, forKey: XYZBudget.length)
        }
    }
    
    var name: String {
        
        get {
            
            return self.value(forKey: XYZBudget.name) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.name)
        }
    }
    
    var recordId: String {
        
        get {
            
            return self.value(forKey: XYZBudget.recordId) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.recordId)
        }
    }
    
    var sequenceNr: Int {
        
        get {
            
            return self.value(forKey: XYZBudget.sequenceNr) as? Int ?? 0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.sequenceNr)
        }
    }
    
    var start: Date {
    
        get {
            
            return self.value(forKey: XYZBudget.start) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZBudget.start)
        }
    }

    var currentStart: Date? {
        
        var value: Date? = nil
        let effectivebudget = self.getEffectiveBudgetDateAmount()
        
        if let length = XYZBudget.Length(rawValue: effectivebudget.length ?? XYZBudget.Length.none.rawValue) {
        
            switch length {
                
                case .none:
                    let startComponents = Calendar.current.dateComponents([.day, .month, .year], from: effectivebudget.start!)
                    let startDateOnly = Calendar.current.date(from: startComponents)
                    value = startDateOnly!
                
                default:
                    let todayComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
                    let today = Calendar.current.date(from: todayComponents)
                    let afterToday = Calendar.current.date(byAdding: .day, value: 1, to: today!)
                    
                    let startComponents = Calendar.current.dateComponents([.day, .month, .year], from: effectivebudget.start!)
                    let startDateOnly = Calendar.current.date(from: startComponents)
                    
                    let untilDate = afterToday
                    
                    value = startDateOnly
                    var endOfStart = XYZBudget.getEndDate(of: value!, in: length) ?? untilDate
                    
                    while (endOfStart! < untilDate!) {
                        
                        value = endOfStart
                        endOfStart = XYZBudget.getEndDate(of: value!, in: length) ?? untilDate
                    }
            }
 
        } else if let currentEnd = self.currentEnd {
            
            var dateComponents = DateComponents()
            
            dateComponents.year = 2018
            dateComponents.month = 1
            dateComponents.day = 1
            dateComponents.timeZone = Calendar.current.timeZone
            dateComponents.hour = 0
            dateComponents.minute = 0
            
            value = min(Calendar.current.date(from: dateComponents)!, currentEnd)
        }

        return value
    }
    
    var currentEnd: Date? {
        
        let effectivebudget = self.getEffectiveBudgetDateAmount()
        let length = XYZBudget.Length(rawValue: effectivebudget.length ?? XYZBudget.Length.none.rawValue )
        
        if let start = effectivebudget.start {
            
            let todayComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
            let today = Calendar.current.date(from: todayComponents)
            let afterToday = Calendar.current.date(byAdding: .day, value: 1, to: today!)
            
            let startComponents = Calendar.current.dateComponents([.day, .month, .year], from: start)
            let startDateOnly = Calendar.current.date(from: startComponents)
            
            let untilDate = afterToday
            
            var endOfStart = XYZBudget.getEndDate(of: startDateOnly!, in: length!) ?? untilDate
            
            while (endOfStart! < untilDate!) {
                
                endOfStart = XYZBudget.getEndDate(of: endOfStart!, in: length!) ?? untilDate
            }

            return endOfStart
        } else {
            
            let start = self.start
            let startComponents = Calendar.current.dateComponents([.day, .month, .year], from: start)
            let startDateOnly = Calendar.current.date(from: startComponents)
 
            let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
            var dateOnly = Calendar.current.date(from: dateComponents)
            dateOnly = Calendar.current.date(byAdding: .day, value: 1, to: dateOnly!)
            
            let allbudgets = self.getAllBudgetDateAmount()
            let nextBudgetStart = allbudgets.starts[0]

            return max(startDateOnly!, dateOnly!, nextBudgetStart)
        }
    }
    
    static func getEndDate(of start: Date,
                           in length: XYZBudget.Length) -> Date? {
        
        switch length {
            
            case .none:
                let yearAfterToday = Calendar.current.date(byAdding: .year,
                                                            value:1,
                                                            to: Date())
                let yearAfterStart = Calendar.current.date(byAdding: .year,
                                                            value:1,
                                                            to: start)
                return max(yearAfterToday!, yearAfterStart!)
            
            case .daily:
                return Calendar.current.date(byAdding: .day,
                                             value:1,
                                             to: start)
            
            case .weekly:
                return Calendar.current.date(byAdding: .weekOfYear,
                                             value:1,
                                             to: start)
            
            case .biweekly:
                return Calendar.current.date(byAdding: .weekOfYear,
                                              value:2,
                                              to: start)
            
            case .monthly:
                return Calendar.current.date(byAdding: .month,
                                             value:1,
                                             to: start)
            
            case .halfyearly:
                return Calendar.current.date(byAdding: .month,
                                             value:6,
                                             to: start)
            
            case .yearly:
                return Calendar.current.date(byAdding: .year,
                                             value:1,
                                             to: start)
        }
    }
    
    func getEffectiveBudgetDateAmount() -> (length: String?,
                                                start: Date?,
                                                amount: Double?) {
        
        let dataAmount = self.historicalAmount
        let historicalAmount = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataAmount) as? [Double] ?? [Double]()
        
        let dataStart = self.historicalStart
        let historicalStart = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataStart) as? [Date] ?? [Date]()
        
        let dataLength = self.historicalLength
        let historicalLength = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataLength) as? [String] ?? [String]()
        
        let length = self.length.rawValue
        let amount = self.amount
        let start = self.start
        
        return XYZBudget.getEffectiveBudgetDateAmount(length: length, start: start, amount: amount,
                                                      lengths: historicalLength!.reversed(),
                                                      starts: historicalStart!.reversed(),
                                                      amounts: historicalAmount!.reversed())
    }
    
    static func getEffectiveBudgetDateAmount(length: String,
                                             start: Date,
                                             amount: Double,
                                             lengths: [String],
                                             starts: [Date],
                                             amounts: [Double]) -> (length: String?,
                                                                        start: Date?,
                                                                        amount: Double?) {
        
        var retLength: String?
        var retAmount: Double?
        var retStart: Date?
        let now = Date()
        
        if now >= start {

            retStart = start
            retAmount = amount
            retLength = length
        } else {
            
            let index = starts.firstIndex(where: { now >= $0 })
            if let index = index {

                retStart = starts[index]
                retAmount = amounts[index]
                retLength = lengths[index]
            }
        }
                                                                            
        return (retLength ?? length, retStart ?? start, retAmount ?? amount) 
    }
    
    func getAllBudgetDateAmount() -> (count: Int,
                                        lengths: [String],
                                        starts: [Date],
                                        amounts: [Double]) {
        
        var dates = [Date]()
        var amounts = [Double]()
        var lengths = [String]()

        let dataAmount = self.historicalAmount
        amounts = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataAmount) as? [Double] ?? [Double]()
  
        let dataStart = self.historicalStart
        dates = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataStart) as? [Date] ?? [Date]()
            
        let dataLength = self.historicalLength
        lengths = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataLength) as? [String] ?? [String]()
 
        let date = self.start
        dates.append(date)
    
        let amount = self.amount
        amounts.append(amount)
        
        let length = self.length.rawValue
        lengths.append(length)
                                            
        dates = dates.map({ (date) -> Date in
            
            let dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: date)
            return Calendar.current.date(from: dateComponent)!
        })
        
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

        let recordName = id ?? UUID.init().uuidString
        let entity = NSEntityDescription.entity(forEntityName: XYZBudget.type,
                                                in: context!)!
        super.init(entity: entity, insertInto: context!)
        
        self.recordId = recordName
        self.name = name
        self.amount = amount
        self.length = length
        self.currency = currency
        self.start = start
        self.sequenceNr = sequenceNr
        self.lastRecordChange = Date()
        
        // optional ...
        self.color = ""
        self.iconName = ""
        
        let dataAmount = try! NSKeyedArchiver.archivedData(withRootObject: [Double](), requiringSecureCoding: false)
        self.historicalAmount = dataAmount
        
        let dataDate = try! NSKeyedArchiver.archivedData(withRootObject: [Date](), requiringSecureCoding: false)
        self.historicalStart = dataDate
        
        let dataLength = try! NSKeyedArchiver.archivedData(withRootObject: [String](), requiringSecureCoding: false)
        self.historicalLength = dataLength
    }

    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
