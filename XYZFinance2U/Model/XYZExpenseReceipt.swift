//
//  XYZExpenseReceipt.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/16/17.
//  Copyright © 2017 - 2019 Chee Bin Hoh. All rights reserved.
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
    
    var expense: XYZExpense?
    var image = NSData()
    var sequenceNr = 0
    
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
        self.setValue(expense, forKey: XYZExpenseReceipt.expense)
        self.setValue(sequenceNr, forKey: XYZExpenseReceipt.sequenceNr)
        self.setValue(image, forKey: XYZExpenseReceipt.image)
    }
}
