//
//  XYZExpenseReceipt.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/16/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import Foundation
import CoreData

@objc(XYZExpenseReceipt)
class XYZExpenseReceipt: NSManagedObject
{
    static let sequenceNr = "sequenceNr"
    static let image = "image"
    static let expense = "expense"
    
    var sequenceNr = 0
    var image = NSData()
    var expense: XYZExpense?
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(expense: XYZExpense, sequenceNr: Int, image: NSData, context: NSManagedObjectContext?) {
        let aContext = context!
        let entity = NSEntityDescription.entity(forEntityName: "XYZExpenseReceipt",
                                                in: aContext)!
        
        super.init(entity: entity, insertInto: aContext)
        self.setValue(expense, forKey: XYZExpenseReceipt.expense)
        self.setValue(sequenceNr, forKey: XYZExpenseReceipt.sequenceNr)
        self.setValue(image, forKey: XYZExpenseReceipt.image)
    }
}
