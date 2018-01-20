//
//  XYZExchangeRate.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/20/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import Foundation
import os.log
import CoreData
import CloudKit

@objc(XYZExchangeRate)
class XYZExchangeRate : NSManagedObject {

    static let type = "XYZExchangeRate"
    static let recordId = "recordId"
    static let base = "base"
    static let target = "target"
    static let rate = "rate"
    static let date = "date"
    
    var recordId: String = ""
    var base: String = ""
    var target: String = ""
    var rate: Double = 0.0
    var date: Date = Date()
    
    init(_ recordId: String,
         _ base: String,
         _ target: String,
         _ rate: Double,
         _ date: Date,
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
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
