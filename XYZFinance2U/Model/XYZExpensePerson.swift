//
//  XYZExpensePerson.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/16/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import Foundation
import CoreData

@objc(XYZExpensePerson)
class XYZExpensePerson: NSManagedObject
{
    // MARK: - static property
    
    static let type = "XYZExpensePerson"
    
    static let name = "name"
    static let email = "email"
    static let expense = "expense"
    static let paid = "paid"
    static let sequenceNr = "sequenceNr"
    
    // MARK: - property
    
    var expense: XYZExpense? {
        
        get {
            
            return self.value(forKey: XYZExpensePerson.expense) as? XYZExpense
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpensePerson.expense)
        }
    }
    
    var name: String {
        
        get {
            
            return self.value(forKey: XYZExpensePerson.name) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpensePerson.name)
        }
    }
    
    var email: String {
        
        get {
            
            return self.value(forKey: XYZExpensePerson.email) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpensePerson.email)
        }
    }
    
    var paid: Bool {
        
        get {
            
            return self.value(forKey: XYZExpensePerson.paid) as? Bool ?? false
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpensePerson.paid)
        }
    }
    
    var sequenceNr: Int {
        
        get {
            
            return self.value(forKey: XYZExpensePerson.sequenceNr) as? Int ?? 0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpensePerson.sequenceNr)
        }
    }
    
    // MARK: - function
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    init(expense: XYZExpense,
         sequenceNr: Int,
         name: String,
         email: String,
         context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entity(forEntityName: XYZExpensePerson.type,
                                                in: context!)!
        
        super.init(entity: entity, insertInto: context!)
        
        self.sequenceNr = sequenceNr
        self.expense = expense
        self.name = name
        self.email = email
    }
}
