//
//  XYZAccount.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import Foundation
import os.log
import CoreData

@objc(XYZAccount)
class XYZAccount : NSManagedObject
{
    static let bank = "bank"
    static let accountNr = "accountNr"
    static let amount = "amount"
    static let lastUpdate = "lastUpdate"
    static let sequenceNr = "sequenceNr"
    
    var bank: String = ""
    var accountNr: String = ""
    var amount: Double = 0.0
    var lastUpdate: Date = Date()
    var sequenceNr = 0
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("accounts")
    
    init(sequenceNr: Int, bank: String, accountNr: String, amount: Double, date: Date, context: NSManagedObjectContext?)
    {
        let aContext = context!
        let entity = NSEntityDescription.entity(forEntityName: "XYZAccount",
                                                in: aContext)!
        super.init(entity: entity, insertInto: aContext)
        
        self.setValue(bank, forKey: XYZAccount.bank)
        self.setValue(amount, forKey:XYZAccount.amount)
        self.setValue(accountNr, forKey: XYZAccount.accountNr)
        self.setValue(date, forKey: XYZAccount.lastUpdate)
        self.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
