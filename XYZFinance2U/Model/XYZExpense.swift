//
//  XYZExpense.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CoreLocation

@objc(XYZExpense)
class XYZExpense: NSManagedObject {
    
    enum Length: String {
        
        case none
        case daily
        case weekly
        case biweekly
        case monthly
        case halfyearly = "half yearly"
        case yearly
        
        func description() -> String {
            
            return self.rawValue
        }
    }
    
    // MARK: - static property

    static let type = "XYZExpense"

    static let amount = "amount"
    static let budgetCategory = "budgetCategory"
    static let currencyCode = "currencyCode"
    static let date = "date"
    static let detail = "detail"
    static let isShared = "isShared"
    static let isSoftDelete = "isSoftDelete"
    static let lastRecordChange = "lastRecordChange"
    static let nrOfPersons = "nrOfPersons"
    static let nrOfReceipts = "nrOfReceipts"
    static let preChangeToken = "preChangeToken"
    static let persons = "persons"
    static let receipts = "receipts"
    static let recordId = "recordId"
    static let recurring = "recurring"
    static let recurringStopDate = "recurringStopDate"
    static let shareRecordId = "shareRecordId"
    static let shareUrl = "shareUrl"

    // MARK: - property
    
    var amount: Double {
        
        get {
            
            return self.value(forKey: XYZExpense.amount) as? Double ?? 0.0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.amount)
        }
    }
    
    var budgetCategory: String {
        
        get {
            
            return self.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.budgetCategory)
        }
    }
    
    var currencyCode: String {
        
        get {
            
            return self.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode!
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.currencyCode)
        }
    }
    
    var date: Date {
        
        get {
            
            return self.value(forKey: XYZExpense.date) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.date)
        }
    }
    
    var detail: String {
        
        get {
            
            return self.value(forKey: XYZExpense.detail) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.detail)
        }
    }
    
    var isShared: Bool {
        
        get {
            
            return self.value(forKey: XYZExpense.isShared) as? Bool ?? false
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.isShared)
        }
    }
    
    var isSoftDelete: Bool {
    
        get {
            
            return self.value(forKey: XYZExpense.isSoftDelete) as? Bool ?? false
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.isSoftDelete)
        }
    }
    
    var lastRecordChange: Date {
        
        get {
            
            return self.value(forKey: XYZExpense.lastRecordChange) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.lastRecordChange)
        }
    }
    
    var persons: Set<XYZExpensePerson>? {
        
        get {
            
            return self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson>
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.persons)
        }
    }
    
    var preChangeToken: Data {
        
        get {
            
            return self.value(forKey: XYZExpense.preChangeToken) as? Data ?? NSData() as Data
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.preChangeToken)
        }
    }
    
    var receipts: Set<XYZExpenseReceipt>? {
        
        get {
            
            return self.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.receipts)
        }
    }
    
    var recordId: String {
        
        get {
            
            return self.value(forKey: XYZExpense.recordId) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.recordId)
        }
    }
    
    var shareRecordId: String {
        
        get {
            
            return self.value(forKey: XYZExpense.shareRecordId) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.shareRecordId)
        }
    }
    
    var shareUrl: String {
        
        get {
            
            return self.value(forKey: XYZExpense.shareUrl) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.shareUrl)
        }
    }
    
    var recurring: Length {
        
        get {
            
            return Length(rawValue: self.value(forKey: XYZExpense.recurring) as? String ?? Length.none.rawValue ) ?? Length.none
        }
        
        set {
            
            self.setValue(newValue.rawValue, forKey: XYZExpense.recurring)
        }
    }
    
    var recurringStopDate: Date {
        
        get {
            
            return self.value(forKey: XYZExpense.recurringStopDate) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpense.recurringStopDate)
        }
    }
    
    // MARK: - function
    
    func getOccurenceDates(until: Date) -> [Date] {
        
        var outputDate = [Date]()
        let recurring = self.recurring
        
        switch recurring {
            
            case .none:
                outputDate.append(self.date)
            
            default:
                var date = self.date

                var stopDate = until
                let recurringStopDate = self.recurringStopDate
                if recurringStopDate > date {
                    
                    stopDate = min(stopDate, recurringStopDate)
                }

                let dateDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
                date = Calendar.current.date(from: dateDateComponents)!

                repeat {
                    outputDate.append(date)
                    
                    switch recurring {
                        case .none:
                            date = Calendar.current.date(byAdding: .day,
                                                         value:1,
                                                         to: stopDate)!
                        
                        case .daily:
                            date = Calendar.current.date(byAdding: .day,
                                                         value:1,
                                                         to: date)!
                        
                        case .weekly:
                            date = Calendar.current.date(byAdding: .weekday,
                                                         value:7,
                                                         to: date)!
                        case .biweekly:
                            date = Calendar.current.date(byAdding: .weekday,
                                                         value:14,
                                                         to: date)!
                        
                        case .monthly:
                            date = Calendar.current.date(byAdding: .month,
                                                         value:1,
                                                         to: date)!
                        
                        case .halfyearly:
                            date = Calendar.current.date(byAdding: .month,
                                                         value:7,
                                                         to: date)!
                        
                        case .yearly:
                            date = Calendar.current.date(byAdding: .year,
                                                         value:1,
                                                         to: date)!
                    }
                }
                while date <= stopDate
        }
        
        return outputDate.sorted(by: >= )
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    init(id: String?,
         detail: String,
         amount: Double,
         date: Date,
         context: NSManagedObjectContext?) {
    
        let recordName = id ?? UUID.init().uuidString
        let entity = NSEntityDescription.entity(forEntityName: XYZExpense.type,
                                                in: context!)!
        super.init(entity: entity, insertInto: context!)
    
        self.recordId = recordName
        self.detail = detail
        self.amount = amount
        self.date = date
        self.persons = Set<XYZExpensePerson>()
        self.receipts = Set<XYZExpenseReceipt>()
        self.preChangeToken = NSData() as Data
        self.isSoftDelete = false
        self.currencyCode = Locale.current.currencyCode!
        self.budgetCategory = ""
    }
    
    func getPersons() -> Set<XYZExpensePerson> {
        
        guard let personList = self.persons else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        return personList
    }
    
    func removeAllPersons() {
        
        guard let personList = self.persons else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for person in personList {
            
            managedContext()?.delete(person)
        }
        
        // for some reason, deleting individual items from set does not empty them, some where are reference them or because
        // the hashable is not working, so i do not able to just use deleteall
        self.persons = Set<XYZExpensePerson>()
    }
    
    @discardableResult
    func removePerson(sequenceNr: Int,
                      context: NSManagedObjectContext?) -> XYZExpensePerson? {
        
        var personRemoved: XYZExpensePerson?
        
        guard var personList = self.persons else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        personRemoved = personList.first(where: { (person) -> Bool in
            
            return person.sequenceNr == sequenceNr
        })
        
        if let _ = personRemoved {
            
            personList.remove(personRemoved!)
            context?.delete(personRemoved!)
             
            self.persons = personList
        }
        
        return personRemoved
    }
    
    @discardableResult
    func addPerson(sequenceNr: Int,
                   name: String,
                   email: String,
                   paid: Bool) -> (XYZExpensePerson, Bool) {
        
        return addPerson(sequenceNr: sequenceNr, name: name, email: email, paid: paid, context: managedContext()!)
    }
    
    @discardableResult
    func addPerson(sequenceNr: Int,
                   name: String,
                   email: String,
                   paid: Bool,
                   context: NSManagedObjectContext?) -> (XYZExpensePerson, Bool) {
        
        var hasChange = false
        var person: XYZExpensePerson?
        
        guard var personList = self.persons else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for existingPerson in personList {
            
            if existingPerson.sequenceNr == sequenceNr {
                
                if existingPerson.name != name {
                    
                    hasChange = true
                } else if existingPerson.email != email {
                    
                    hasChange = true
                } else if existingPerson.paid != paid {
                
                    hasChange = true
                }
                
                existingPerson.name = name
                existingPerson.email = email
                existingPerson.paid = paid
                person = existingPerson
                
                break
            }
        }
        
        if nil == person {
            
            hasChange = true
            person = XYZExpensePerson(expense: self, sequenceNr: sequenceNr, name: name, email: email, context: context)
            person?.paid = paid
            
            personList.insert(person!)
            
            self.persons = personList
        }
        
        return (person!, hasChange)
    }
    
    @discardableResult
    func addReceipt(sequenceNr: Int,
                    image: NSData) -> (XYZExpenseReceipt, Bool) {
        
        var hasChange = false
        var receipt: XYZExpenseReceipt?
        
        guard var receiptList = self.receipts  else {
            
            fatalError("Exception: [XYZExpenseReceipt] is expected")
        }
        
        for existingReceipt in receiptList {
            
            if existingReceipt.sequenceNr == sequenceNr {
                
                let imageData = existingReceipt.image as NSData
                
                hasChange = imageData != image // this is not 100% accurate as data might be different
                                               // at various time of compress image.
                
                existingReceipt.image = image as Data
                receipt = existingReceipt
                
                break
            }
        }
    
        if nil == receipt {
            
            hasChange = true
            receipt = XYZExpenseReceipt(expense: self, sequenceNr: sequenceNr, image: image, context: managedContext())
            receiptList.insert(receipt!)
            
            self.receipts = receiptList
        }
        
        return (receipt!, hasChange)
    }
}
