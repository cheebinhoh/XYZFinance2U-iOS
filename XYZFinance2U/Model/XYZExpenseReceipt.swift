//
//  XYZExpenseReceipt.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/16/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import Foundation
import CoreData

@objc(XYZExpenseReceipt)
class XYZExpenseReceipt: NSManagedObject
{
    // MARK: - static property
    
    static let type = "XYZExpenseReceipt"
    
    static let expense = "expense"
    static let image = "image"
    static let sequenceNr = "sequenceNr"
    
    // MARK: - property
    
    var expense: XYZExpense? {
        
        get {
            
            return self.value(forKey: XYZExpenseReceipt.expense) as? XYZExpense
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpenseReceipt.expense)
        }
    }
    
    var image: Data {
        
        get {
            
            return self.value(forKey: XYZExpenseReceipt.image) as? Data ?? NSData() as Data
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpenseReceipt.image)
        }
    }
    
    var sequenceNr: Int {
        
        get {
            
            return self.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int ?? 0
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZExpenseReceipt.sequenceNr)
        }
    }
    
    // MARK: - function
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    
    init(expense: XYZExpense,
         sequenceNr: Int,
         image: NSData,
         context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entity(forEntityName: XYZExpenseReceipt.type,
                                                in: context!)!
        
        super.init(entity: entity, insertInto: context!)
        self.expense = expense
        self.sequenceNr = sequenceNr
        self.image = image as Data
    }
}
