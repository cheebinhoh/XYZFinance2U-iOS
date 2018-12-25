//
//  XYZExchangeRate.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/20/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import os.log
import Foundation
import CoreData
import CloudKit

@objc(XYZExchangeRate)
class XYZExchangeRate : NSManagedObject {

    // MARK: - static
    
    static let type = "XYZExchangeRate"

    static let base = "base"
    static let date = "date"
    static let rate = "rate"
    static let recordId = "recordId"
    static let target = "target"

    
    // MARK: - property

    var base: String = ""
    var date: Date = Date()
    var rate: Double = 0.0
    var recordId: String = ""
    var target: String = ""

    
    // MARK: - function
    
    init(recordId: String,
         base: String,
         target: String,
         rate: Double,
         date: Date,
         context: NSManagedObjectContext?) {
        
        let aContext = context!
        
        let entity = NSEntityDescription.entity(forEntityName: XYZExchangeRate.type,
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        self.setValue(recordId, forKey: XYZExchangeRate.recordId)
        self.setValue(base, forKey: XYZExchangeRate.base)
        self.setValue(target, forKey: XYZExchangeRate.target)
        self.setValue(rate, forKey: XYZExchangeRate.rate)
        self.setValue(date, forKey: XYZExchangeRate.date)
    }
    
    /* DEPRECATED
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
    */
}
