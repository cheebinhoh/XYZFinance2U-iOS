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

struct TableSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]() 
    var data: Any?
}

func formattingDate(date: Date) -> String {
    
    let dateFormatter = DateFormatter();
    
    dateFormatter.dateStyle = .medium
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

func formattingCurrencyValue(input: Double) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(input: value)
}

func formattingCurrencyValue(input: String) -> String {
    
    let processedInput = formattingDoubleValue(input: input)
    let formatter = NumberFormatter()

    let amountAsDouble = Double(processedInput) ?? 0.0
    let amountASNSNumber = NSNumber(value: amountAsDouble)
    
    formatter.locale = Locale.current
    formatter.numberStyle = .currency
    
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
        
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
}

