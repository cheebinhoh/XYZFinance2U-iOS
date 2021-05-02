//
//  XYZUtility.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/30/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit

let exchangeAPIWebSiteList = ["https://www.exchangerate.host"] //, "https://exchangeratesapi.io"]
let exchangeAPIHostList = ["https://api.exchangerate.host"] //, "https://api.exchangeratesapi.io"]
let totalIncomeCurrencyCodeKey = "totalincomecurrencycode"
let showTotalIncomeKey = "showtotalincome"
let requiredAuthenticationKey = "requiredauthentication"
var cksharesFoundButNoRootRecord = [CKShare]()

protocol XYZTableViewReloadData {
    
    func reloadData()
}

extension UIColor {
    
    static var placeholderGray: UIColor {
        
        return UIColor(red: 0.0, green: 0.0, blue: 0.0980392, alpha: 0.22)
    }
}

extension String {
    
    func localized() -> String {
        
        return NSLocalizedString(self, comment:"")
    }
}

extension Int {
    
    mutating func repeatUntilZero(block: (_ value: Int) -> Void) {
        
        while self != 0 {
            
            block(self)
            
            if self > 0 {
                
                self = self - 1
            } else {
                
                self = self + 1
            }
        }
    }
}

// MARK: - type

struct TableSectionCell {
    
    let identifier: String
    let title: String?
    var cellList = [String]() 
    var data: Any?
}

enum XYZColor: String {
    
    case none = ""
    case black = "Black"
    case blue = "Blue"
    case brown = "Brown"
    case cyan = "Cyan"
    case green = "Green"
    case magenta = "Magenta"
    case orange = "Orange"
    case purple = "Purple"
    case red = "Red"
    case yellow = "Yellow"
    case white = "White"
    
    func description() -> String {
        
        return self.rawValue
    }
    
    func uiColor() -> UIColor {
        
        switch self {
            
            case .none:
                return UIColor.clear
            
            case .black:
                return UIColor.black
            
            case .blue:
                return UIColor.blue
            
            case .brown:
                return UIColor.brown
            
            case .cyan:
                return UIColor.cyan
            
            case .green:
                return UIColor.green
            
            case .magenta:
                return UIColor.magenta
            
            case .orange:
                return UIColor.orange
            
            case .purple:
                return UIColor.purple
            
            case .red:
                return UIColor.red
            
            case .yellow:
                return UIColor.yellow
            
            case .white:
                return UIColor.white
        }
    }
}

// MARK: - formatting

func formattingDate(_ date: Date,
                    style: DateFormatter.Style) -> String {
    
    let dateFormatter = DateFormatter();
    
    dateFormatter.dateStyle = style
    
    return dateFormatter.string(from: date)
}

func formattingDateTime(_ date: Date) -> String {
    
    let dateFormatter = DateFormatter();
    
    // FIXME, we will need to think about localization
    dateFormatter.dateFormat = "MMM-dd, yyyy 'at' hh:mm a"
    
    return dateFormatter.string(from: date)
}

func formattingAndProcessDoubleValue(of input: String) -> String {
    
    var processedInput = ""
    var afterPoint = false
    var numberOfDigitsAfterPoint = 0
    let digitSet = CharacterSet.decimalDigits
    let numberOfFixedDecimalPoints = 2
    
    if ( input.isEmpty )
    {
        return "0.00"
    }
    
    let lastChar = input[input.index(before: input.endIndex)]
    
    if Locale.current.decimalSeparator ?? "" == "\(lastChar)" {
        
        processedInput = shiftingDecimalPoint(of: input)
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

func shiftingDecimalPoint(of input: String) -> String {
    
    var processedInput = ""
    var decimalPointFound = false
    let reversedInput = input.reversed()

    for c in String(reversedInput).unicodeScalars {
        
        if Locale.current.decimalSeparator ?? "" == "\(c)" {
            
            if ( decimalPointFound ) {
                
                continue
            } else {
                
                if processedInput.isEmpty {
                    
                    processedInput = processedInput + "00"
                }
            }
            
            decimalPointFound = true
        }

        processedInput = processedInput + "\(c)"
    }
    
    return String(processedInput.reversed())
}

func formattingDoubleValueAsDouble(of input: String) -> Double {
    
    return Double(formattingDoubleValue(of: input)) ?? 0.0
}

func formattingDoubleValue(of input: String) -> String {
    
    var processedInput = ""
    var startWithDecimalDigit = false
    var startWithNegativeSign = false
    let digitSet = CharacterSet.decimalDigits
    
    let inputToBeProcessed = input
    
    for c in inputToBeProcessed.unicodeScalars {
        
        if !startWithNegativeSign && c == "-" {
          
            startWithNegativeSign = true
        } else if startWithDecimalDigit {
            
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
    
    return startWithNegativeSign ? "-\(processedInput)" : processedInput
}

func formattingCurrencyValue(of input: Double,
                             as code: String?) -> String {
    
    let value = "\(input)"
    
    return formattingCurrencyValue(of: value, as: code)
}

func formattingCurrencyValue(of input: String,
                             as code: String?) -> String {
    
    let processedInput = formattingDoubleValue(of: input)
    
    let formatter = NumberFormatter()

    let amountAsDouble = Double(processedInput) ?? 0.0
    let amountASNSNumber = NSNumber(value: amountAsDouble)
    
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2

    guard let formattedAmount = formatter.string(from: amountASNSNumber) else {
        
        return ""
    }
    
    return formattedAmount
}

// MARK: - core data

func getBudgets(of currency: String) -> [XYZBudget] {

    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    return (appDelegate?.budgetList.filter({ (budget) -> Bool in
        
        return currency == ""
               || budget.currency == currency
    }))!
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

func sortBudgets(_ budgetList: [XYZBudget]) -> [XYZBudget] {
    
    return budgetList.sorted() { (acc1, acc2) in
        
        return acc1.sequenceNr < acc2.sequenceNr 
    }
}

func sortAcounts(_ incomeList: [XYZAccount]) -> [XYZAccount] {
    
    return incomeList.sorted() { (acc1, acc2) in
        
        return acc1.sequenceNr < acc2.sequenceNr
    }
}

func sortExpenses(_ expenses: [XYZExpense]) -> [XYZExpense] {
    
    return expenses.sorted(by: { (exp1, exp2) -> Bool in

        return exp1.date > exp2.date
    })
}

func loadAccounts() -> [XYZAccount]? {
    
    var output: [XYZAccount]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZAccount>(entityName: "XYZAccount")
    
    if let unsorted = try? aContext?.fetch(fetchRequest) {
        
        output = sortAcounts(unsorted)
    }
    
    return output
}

func loadExpenses() -> [XYZExpense]? {
    
    var expenses: [XYZExpense]?
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZExpense>(entityName: "XYZExpense")
    
    expenses = try? aContext?.fetch(fetchRequest)
    
    let fetchRequestExpPerson = NSFetchRequest<XYZExpensePerson>(entityName: "XYZExpensePerson")
    
    _ = try? aContext?.fetch(fetchRequestExpPerson)
    
    let fetchRequestExpReceipt = NSFetchRequest<XYZExpenseReceipt>(entityName: "XYZExpenseReceipt")
    
    _ = try? aContext?.fetch(fetchRequestExpReceipt)
    
    return sortExpenses(expenses!)
}

func loadBudgets() -> [XYZBudget]? {
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZBudget>(entityName: XYZBudget.type)
    
    return try? aContext?.fetch(fetchRequest)
}

func loadiCloudZone() -> [XYZiCloudZone]? {
    
    let aContext = managedContext()
    let fetchRequest = NSFetchRequest<XYZiCloudZone>(entityName: XYZiCloudZone.type)
  
    return try? aContext?.fetch(fetchRequest)
}


