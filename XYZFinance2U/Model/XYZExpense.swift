//
//  XYZExpense.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import Foundation
import CoreData

@objc(XYZExpense)
class XYZExpense: NSManagedObject
{
    static let type = "type"
    static let detail = "detail"
    static let amount = "amount"
    static let date = "date"
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let persons = "persons"
    static let receipts = "receipts"
    static let hasgeolocation = "hasgeolocation"
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("expenses")

    var type = ""
    var detail = ""
    var amount = 0.0
    var date: Date = Date()
    var latitude = 0.0
    var longitude = 0.0
    var persons: Set<XYZExpensePerson>?
    var receipts: Set<XYZExpenseReceipt>?
    var hasgeolocation = false
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(type: String, detail: String, amount: Double, date: Date, latitude: Double, longitude: Double, context: NSManagedObjectContext?) {
        let aContext = context!
        let entity = NSEntityDescription.entity(forEntityName: "XYZExpense",
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        self.setValue(type, forKey: XYZExpense.type)
        self.setValue(detail, forKey: XYZExpense.detail)
        self.setValue(amount, forKey: XYZExpense.amount)
        self.setValue(date, forKey: XYZExpense.date)
        self.setValue(latitude, forKey: XYZExpense.latitude)
        self.setValue(longitude, forKey: XYZExpense.longitude)
        self.setValue(Set<XYZExpensePerson>(), forKey: XYZExpense.persons)
        self.setValue(Set<XYZExpenseReceipt>(), forKey: XYZExpense.receipts)
    }
    
    convenience init(detail: String, amount: Double, date: Date, context: NSManagedObjectContext?) {
        self.init(type: "", detail: detail, amount: amount, date: date, latitude: 0.0, longitude: 0.0, context: context)
    }
    
    func getPersons() -> Set<XYZExpensePerson>
    {
        guard let personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson>
            else
        {
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        return personList
    }
    
    func removeAllPersons()
    {
        guard let personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson>
            else
        {
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for person in personList
        {
            managedContext()?.delete(person)
        }
        
        // for some reason, deleting individual items from set does not empty them, some where are reference them or because
        // the hashable is not working, so i do not able to just use deletall
        self.setValue(Set<XYZExpensePerson>(), forKey: XYZExpense.persons)
    }
    
    @discardableResult
    func addPerson(sequenceNr: Int, name: String, email: String) -> XYZExpensePerson
    {
        var person: XYZExpensePerson?
        guard var personList = self.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson>
            else
        {
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        for existingPerson in personList
        {
            if let existingSequenceNr = existingPerson.value(forKey: XYZExpensePerson.sequenceNr) as? Int, existingSequenceNr == sequenceNr
            {
                existingPerson.setValue(name, forKey: XYZExpensePerson.name)
                existingPerson.setValue(email, forKey: XYZExpensePerson.email)
                person = existingPerson
                break
            }
        }
        
        if nil == person
        {
            person = XYZExpensePerson(expense: self, sequenceNr: sequenceNr, name: name, email: email, context: managedContext())
            
            personList.insert(person!)
        }
        
        return person!
    }
    
    @discardableResult
    func addReceipt(sequenceNr: Int, image: NSData) -> XYZExpenseReceipt
    {
        var receipt: XYZExpenseReceipt?
        guard var receiptList = self.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>
            else
        {
            fatalError("Exception: [XYZExpenseReceipt] is expected")
        }
        
        for existingReceipt in receiptList
        {
            if let existingSequenceNr = existingReceipt.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int, existingSequenceNr == sequenceNr
            {
                existingReceipt.setValue(image, forKey: XYZExpenseReceipt.image)
                receipt = existingReceipt
            }
        }
    
        if nil == receipt
        {
            receipt = XYZExpenseReceipt(expense: self, sequenceNr: sequenceNr, image: image, context: managedContext())
            receiptList.insert(receipt!)
        }
        
        return receipt!
    }
}
