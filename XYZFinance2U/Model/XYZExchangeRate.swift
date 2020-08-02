//
//  XYZExchangeRate.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/20/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
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

    var base = ""
    var date = Date()
    var rate = 0.0
    var recordId = ""
    var target = ""

    // MARK: - function
    
    init(recordId: String,
         base: String,
         target: String,
         rate: Double,
         date: Date,
         context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entity(forEntityName: XYZExchangeRate.type,
                                                in: context!)!
        super.init(entity: entity, insertInto: context!)
        
        self.setValue(recordId, forKey: XYZExchangeRate.recordId)
        self.setValue(base, forKey: XYZExchangeRate.base)
        self.setValue(target, forKey: XYZExchangeRate.target)
        self.setValue(rate, forKey: XYZExchangeRate.rate)
        self.setValue(date, forKey: XYZExchangeRate.date)
    }
    
    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
