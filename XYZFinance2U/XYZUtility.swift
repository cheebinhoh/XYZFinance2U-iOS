//
//  XYZUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/30/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import Foundation
import CoreData
import UIKit
import CloudKit

struct TableSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]() 
    var data: Any?
}

func formattingDate(date: Date, _ style: DateFormatter.Style) -> String {
    
    let dateFormatter = DateFormatter();
    
    dateFormatter.dateStyle = style
    return dateFormatter.string(from: date)
}

func formattingDateTime(date: Date) -> String {
    
    let dateFormatter = DateFormatter();
    
    // FIXME, we will need to think about localization
    dateFormatter.dateFormat = "MMM-dd, yyyy 'at' hh:mm a"
    
    return dateFormatter.string(from: date)
}


func formattingAndProcessDoubleValue(input: String) -> String {
    
    var processedInput = ""
    var afterPoint = false
    var numberOfDigitsAfterPoint = 0
    let digitSet = CharacterSet.decimalDigits
    let numberOfFixedDecimalPoints = 2
    
    let lastChar = input[input.index(before: input.endIndex)]
    
    if ( Locale.current.decimalSeparator ?? "" == "\(lastChar)" ) {
        
        processedInput = shiftingDecimalPoint(input: input)
        numberOfDigitsAfterPoint = numberOfFixedDecimalPoints
    } else {
        
        for c in input.unicodeScalars {
            
            if !digitSet.contains(c) {
                
                afterPoint = true
                continue
            } else {
                
                if afterPoint {
                    
                    numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
                }
                
                processedInput += "\(c)"
            }
        }
    }

    var doubleValue = Double(processedInput) ?? 0.0
    
    while numberOfDigitsAfterPoint != numberOfFixedDecimalPoints {
        
        doubleValue = doubleValue / 100
        
        if numberOfDigitsAfterPoint < numberOfFixedDecimalPoints {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint + 1
        } else {
            
            numberOfDigitsAfterPoint = numberOfDigitsAfterPoint - 1
        }
    }
    
    return "\(doubleValue)"
}

func shiftingDecimalPoint(input: String) -> String {
    
    var processedInput = ""
    let reversedInput = input.reversed()
    var decimalPointFound = false
    
    for c in String(reversedInput).unicodeScalars {
        
        if ( Locale.current.decimalSeparator ?? "" == "\(c)" ) {
            
            if ( decimalPointFound ) {
                
                continue
            } else {
                
                if ( processedInput.isEmpty ) {
                    
                    processedInput = processedInput + "00"
                }
            }
            
            decimalPointFound = true
        }

        processedInput = processedInput + "\(c)"
    }
    
    return String(processedInput.reversed())
}

func formattingDoubleValueAsDouble(input: String) -> Double {
    
    return Double(formattingDoubleValue(input: input)) ?? 0.0
}

func formattingDoubleValue(input: String) -> String {
    
    var processedInput = ""
    var startWithDecimalDigit = false
    let digitSet = CharacterSet.decimalDigits
    
    var inputToBeProcessed = input
    
    for c in inputToBeProcessed.unicodeScalars {
        
        if startWithDecimalDigit {
            
            if digitSet.contains(c) || ( Locale.current.decimalSeparator ?? "" == "\(c)" ) {
                
                processedInput += "\(c)"
            }
        } else if !digitSet.contains(c) {
            
            continue
        } else {
            
            startWithDecimalDigit = true
            processedInput += "\(c)"
        }
    }
    
    return processedInput
}

func formattingCurrencyValue(input: Double, _ code: String?) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(input: value, code)
}

func formattingCurrencyValue(input: String, _ code: String?) -> String {
    
    let processedInput = formattingDoubleValue(input: input)
    let formatter = NumberFormatter()

    let amountAsDouble = Double(processedInput) ?? 0.0
    let amountASNSNumber = NSNumber(value: amountAsDouble)
    
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    
    guard let formattedAmount = formatter.string(from: amountASNSNumber) else {
        
        return ""
    }
    
    return formattedAmount
}

func managedContext() -> NSManagedObjectContext? {
    
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        
        fatalError("Exception: AppDelegate is expected")
    }
    
    return appDelegate.persistentContainer.viewContext
}

func saveManageContext() {
    
    let aContext = managedContext()
    
    do {
        
        try aContext?.save()
    } catch let nserror as NSError {
        
        fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
    }
}

func loadAccounts() -> [XYZAccount]? {
    
    var output: [XYZAccount]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZAccount>(entityName: "XYZAccount")
    
    do {
        
        output = try aContext?.fetch(fetchRequest)
        
        output = output?.sorted() {
            (acc1, acc2) in
            
            return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
        }
    } catch let error as NSError {
        
        print("Could not fetch. \(error), \(error.userInfo)")
    }
    
    let delegate = UIApplication.shared.delegate as? AppDelegate
    
    if (delegate?.icloudEnable)! {
        
        /*
        // process icloud records
        for income in output! {
            
            income.saveToiCloud()
        }
    
        // save subscription
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.fetchAllSubscriptions(completionHandler: { (subscriptions, error) in
        
            if nil != error {
                
                print("-------- error on fetching subscriptions = \(String(describing: error))")
            } else {
                
                if let subscriptions = subscriptions {
                    
                    for subscription in subscriptions {
                        
                        database.delete(withSubscriptionID: subscription.subscriptionID, completionHandler: { (str, error) in
                        
                            if nil != error {
                                
                                print("------- error on deleting subscription = \(String(describing: error))")
                            }
                        })
                    }
                }
            }
        })
        
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: XYZAccount.type, predicate: predicate, options: .firesOnRecordUpdate)
        let notification = CKNotificationInfo()
        notification.title = "Income update"
        notification.alertBody = "There is update to Incomes"
        notification.soundName = "default"
        subscription.notificationInfo = notification
        
        database.save(subscription, completionHandler: { (subscription, error) in
            
            if nil != error {
                
                print("------- error on saving subscription \(String(describing: error))")
            }
        })
        
        */
    } else {
        
        // nothing here
    }
    
    return output
}

