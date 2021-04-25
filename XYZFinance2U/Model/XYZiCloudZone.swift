//
//  XYZiCloudZone.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/11/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
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
    static let changeTokenLastFetch = "changeTokenLastFetch"
    static let deleteRecordIdList = "deleteRecordIdList"
    static let deleteShareRecordIdList = "deleteShareRecordIdList"
    static let inShareDB = "inShareDB"
    static let name = "name"
    static let ownerName = "ownerName"
    
     // MARK: - property
    
    var name: String {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.name) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.name)
        }
    }
    
    var ownerName: String {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.ownerName) as? String ?? ""
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.ownerName)
        }
    }
    
    var inShareDB: Bool {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.inShareDB) as? Bool ?? false
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.inShareDB)
        }
    }
    
    var changeToken: Data {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.changeToken) as? Data ?? (NSData() as Data)
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.changeToken)
        }
    }
    
    var changeTokenLastFetch: Date {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date ?? Date()
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.changeTokenLastFetch)
        }
    }
    
    // it stores non-persistent list of XYZAccount load from cloud data and iCloud (it is supposed to be the
    // merge of both source)
    var data: Any?
    
    // it stores non-persistent list of record id for XYZAccount that is deleted.
    var deleteRecordIdList: Data {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data ?? (NSData() as Data)
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.deleteRecordIdList)
        }
    }
    
    var deleteShareRecordIdList: Data {
        
        get {
            
            return self.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data ?? (NSData() as Data)
        }
        
        set {
            
            self.setValue(newValue, forKey: XYZiCloudZone.deleteShareRecordIdList)
        }
    }
    
    // MARK: - function
    
    init(name: String,
         owner: String,
         context: NSManagedObjectContext?) {
        
        let entity = NSEntityDescription.entity(forEntityName: XYZiCloudZone.type,
                                                in: context!)!
        super.init(entity: entity, insertInto: context!)
        
        self.name = name
        self.ownerName = owner
        
        let data = try! NSKeyedArchiver.archivedData(withRootObject: [String](), requiringSecureCoding: false)
        
        self.deleteRecordIdList = data
        self.deleteShareRecordIdList = data
        self.changeToken = NSData() as Data
    }

    override init(entity: NSEntityDescription,
                  insertInto context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertInto: context)
    }
}
