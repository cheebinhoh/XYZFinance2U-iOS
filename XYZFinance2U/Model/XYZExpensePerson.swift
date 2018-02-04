//
//  XYZExpensePerson.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/16/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
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
    static let sequenceNr = "sequenceNr"
    static let paid = "paid"
    
    // MARK: - property
    
    var name  = ""
    var email = ""
    var expense: XYZExpense?
    var sequenceNr = 0
    var paid = false
    
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
        
        let aContext = context!
        let entity = NSEntityDescription.entity(forEntityName: XYZExpensePerson.type,
                                                in: aContext)!
        
        super.init(entity: entity, insertInto: aContext)
        
        self.setValue(sequenceNr, forKey: XYZExpensePerson.sequenceNr)
        self.setValue(expense, forKey: XYZExpensePerson.expense)
        self.setValue(name, forKey: XYZExpensePerson.name)
        self.setValue(email, forKey: XYZExpensePerson.email)
    }
}
