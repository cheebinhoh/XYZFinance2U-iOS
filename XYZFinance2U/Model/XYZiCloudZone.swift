//
//  XYZiCloudZone.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/11/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

//  XYZiCloudZone class models state of iCloud zones. It stores last change token of the zone in iCloud, date time
//  and it also has a non-persistent link to data load from the iCloud zone.

import Foundation
import CoreData

@objc(XYZiCloudZone)
class XYZiCloudZone: NSManagedObject {
    
    // MARK: - static property
    
    static let type = "XYZiCloudZone"
    static let changeToken = "changeToken"
    static let name = "name"
    static let changeTokenLastFetch = "changeTokenLastFetch"
    static let deleteRecordIdList = "deleteRecordIdList"
    
     // MARK: - property
    
    var name = ""
    var changeToken = NSData()
    var changeTokenLastFetch = Date()
    
    // it stores non-persistent list of XYZAccount load from cloud data and iCloud (it is supposed to be the
    // merge of both source)
    var data: Any?
    
    // it stores non-persistent list of record id for XYZAccount that is deleted.
    var deleteRecordIdList = NSData()
    
    // MARK: - function
    
    init(name: String, context: NSManagedObjectContext?) {
        
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
