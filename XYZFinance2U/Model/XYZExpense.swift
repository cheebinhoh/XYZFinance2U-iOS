//
//  XYZExpense.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

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
    static let hasLocation = "hasLocation"
    static let isShared = "isShared"
    static let isSoftDelete = "isSoftDelete"
    static let lastRecordChange = "lastRecordChange"
    static let loction = "location"
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
    
    var amount = 0.0
    var budgetCategory = ""
    var currencyCode: String = Locale.current.currencyCode!
    var date: Date = Date()
    var detail = ""
    var hasLocation = false
    var isShared = false
    var isSoftDelete = false
    var lastRecordChange = Date()
    var location = CLLocation()
    var persons: Set<XYZExpensePerson>?
    var preChangeToken = NSData()
    var receipts: Set<XYZExpenseReceipt>?
    var recordId: String = ""
    var shareRecordId: String = ""
    var shareUrl: String = ""
    var recurring: Length = .none
    var recurringStopDate: Date = Date()
    
    // MARK: - function
    
    func getOccurenceDates(until: Date) -> [Date] {
        
        var outputDate = [Date]()
        let recurring = XYZExpense.Length(rawValue: self.value(forKey: XYZExpense.recurring) as! String)
        
        switch recurring {
            
            case .none:
                let date = self.value(forKey: XYZExpense.date) as? Date
                outputDate.append(date!)
            
            default:
                var date = self.value(forKey: XYZExpense.date) as? Date

                var stopDate = until
                let recurringStopDate = self.value(forKey: XYZExpense.recurringStopDate) as? Date ?? date
                if recurringStopDate! > date! {
                    
                    stopDate = min(stopDate, recurringStopDate!)
                }

                let dateDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date!)
                date = Calendar.current.date(from: dateDateComponents)!

                repeat {
                    outputDate.append(date!)
                    
                    switch recurring! {
                        case .none:
                            date = Calendar.current.date(byAdding: .day,
                                                         value:1,
                                                         to: stopDate)
                        
                        case .daily:
                            date = Calendar.current.date(byAdding: .day,
                                                         value:1,
                                                         to: date!)
                        
                        case .weekly:
                            date = Calendar.current.date(byAdding: .weekday,
                                                         value:7,
                                                         to: date!)
                        case .biweekly:
                            date = Calendar.current.date(byAdding: .weekday,
                                                         value:14,
                                                         to: date!)
                        
                        case .monthly:
                            date = Calendar.current.date(byAdding: .month,
                                                         value:1,
                                                         to: date!)
                        
                        case .halfyearly:
                            date = Calendar.current.date(byAdding: .month,
                                                         value:7,
                                                         to: date!)
                        
                        case .yearly:
                            date = Calendar.current.date(byAdding: .year,
                                                         value:1,
                                                         to: date!)
                    }
                }
                while date! <= stopDate
        }
        
        return outputDate.sorted(by: { (date1, date2) -> Bool in
        
            return date1 >= date2
        })
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
    
        self.setValue(recordName, forKey: XYZExpense.recordId)
        self.setValue(detail, forKey: XYZExpense.detail)
        self.setValue(amount, forKey: XYZExpense.amount)
        self.setValue(date, forKey: XYZExpense.date)
        self.setValue(Set<XYZExpensePerson>(), forKey: XYZExpense.persons)
        self.setValue(Set<XYZExpenseReceipt>(), forKey: XYZExpense.receipts)
        self.setValue(NSData(), forKey: XYZExpense.preChangeToken)
        self.setValue(false, forKey: XYZExpense.isSoftDelete)
        self.setValue(Locale.current.currencyCode, forKey: XYZExpense.currencyCode)
        self.setValue("", forKey: XYZExpense.budgetCategory)
    }
    
    func getPersons() -> Set<XYZExpensePerson> {
        
        guard let personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        return personList
    }
    
    func removeAllPersons() {
        
        guard let personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for person in personList {
            
            managedContext()?.delete(person)
        }
        
        // for some reason, deleting individual items from set does not empty them, some where are reference them or because
        // the hashable is not working, so i do not able to just use deleteall
        self.setValue(Set<XYZExpensePerson>(), forKey: XYZExpense.persons)
    }
    
    @discardableResult
    func removePerson(sequenceNr: Int,
                      context: NSManagedObjectContext?) -> XYZExpensePerson? {
        
        var personRemoved: XYZExpensePerson?
        
        guard var personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for person in personList {
                       
            if let personSequenceNr = person.value(forKey: XYZExpensePerson.sequenceNr) as? Int,
                personSequenceNr == sequenceNr {
                
                personRemoved = person
                personList.remove(person)
                context?.delete(personRemoved!)
                
                self.setValue(personList, forKey: XYZExpense.persons)
                
                break
            }
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
        
        guard var personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for existingPerson in personList {
            
            if let existingSequenceNr = existingPerson.value(forKey: XYZExpensePerson.sequenceNr) as? Int,
                existingSequenceNr == sequenceNr {
                
                if let existingName = existingPerson.value(forKey: XYZExpensePerson.name) as? String,
                    existingName != name {
                    
                    hasChange = true
                } else if let existingEmail = existingPerson.value(forKey: XYZExpensePerson.email) as? String,
                    existingEmail != email {
                    
                    hasChange = true
                } else if let existingPaid = existingPerson.value(forKey: XYZExpensePerson.paid) as? Bool,
                    existingPaid != paid {
                
                    hasChange = true
                }
                
                existingPerson.setValue(name, forKey: XYZExpensePerson.name)
                existingPerson.setValue(email, forKey: XYZExpensePerson.email)
                existingPerson.setValue(paid, forKey: XYZExpensePerson.paid)
                person = existingPerson
                
                break
            }
        }
        
        if nil == person {
            
            hasChange = true
            person = XYZExpensePerson(expense: self, sequenceNr: sequenceNr, name: name, email: email, context: context)
            person?.setValue(paid, forKey: XYZExpensePerson.paid)
            
            personList.insert(person!)
            
            self.setValue(personList, forKey: XYZExpense.persons)
        }
        
        return (person!, hasChange)
    }
    
    @discardableResult
    func addReceipt(sequenceNr: Int,
                    image: NSData) -> (XYZExpenseReceipt, Bool) {
        
        var hasChange = false
        var receipt: XYZExpenseReceipt?
        
        guard var receiptList = self.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>  else {
            
            fatalError("Exception: [XYZExpenseReceipt] is expected")
        }
        
        for existingReceipt in receiptList {
            
            if let existingSequenceNr = existingReceipt.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int,
                existingSequenceNr == sequenceNr {
                
                let imageData = existingReceipt.value(forKey: XYZExpenseReceipt.image) as? NSData
                
                hasChange = imageData != image // this is not 100% accurate as data might be different
                                               // at various time of compress image.
                
                existingReceipt.setValue(image, forKey: XYZExpenseReceipt.image)
                receipt = existingReceipt
                
                break
            }
        }
    
        if nil == receipt {
            
            hasChange = true
            receipt = XYZExpenseReceipt(expense: self, sequenceNr: sequenceNr, image: image, context: managedContext())
            receiptList.insert(receipt!)
            
            self.setValue(receiptList, forKey: XYZExpense.receipts)
        }
        
        return (receipt!, hasChange)
    }
}
