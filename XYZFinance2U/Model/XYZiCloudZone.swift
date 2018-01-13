//
//  XYZiCloudZone.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/11/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import Foundation
import CoreData

@objc(XYZiCloudZone)
class XYZiCloudZone: NSManagedObject {
    
    static let type = "XYZiCloudZone"
    static let changeToken = "changeToken"
    static let name = "name"
    static let changeTokenLastFetch = "changeTokenLastFetch"
    static let deleteRecordIdList = "deleteRecordIdList"
    
    var name = ""
    var changeToken = NSData()
    var changeTokenLastFetch = Date()
    var data: Any?
    var deleteRecordIdList = NSData()
    
    init(name: String, context: NSManagedObjectContext?)
    {
        let aContext = context!
        let entity = NSEntityDescription.entity(forEntityName: XYZiCloudZone.type,
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        self.setValue(name, forKey: XYZiCloudZone.name)
        
        let data = NSKeyedArchiver.archivedData(withRootObject: [String]() )
        self.setValue(data, forKey: XYZiCloudZone.deleteRecordIdList)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
