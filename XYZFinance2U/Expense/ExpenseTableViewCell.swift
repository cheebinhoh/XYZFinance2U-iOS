//
//  ExpenseTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/8/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var dotColorView: UIView!
    @IBOutlet weak var cellContentView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    var monthYearDate: Date?
    
    // MARK: - function
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        colorView?.backgroundColor = UIColor.clear
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setExpense(expense: XYZExpense) {
        
        amount.text = formattingCurrencyValue(input: (expense.value(forKey: XYZExpense.amount) as? Double) ?? 0.0, code: expense.value(forKey: XYZExpense.currencyCode) as? String )
        detail.text = ( expense.value(forKey: XYZExpense.detail) as? String ) ?? ""
        date.text = formattingDate(date: (expense.value(forKey: XYZExpense.date) as? Date) ?? Date(), style: .medium )
        
        let budgetCategory = expense.value(forKey: XYZExpense.budgetCategory) as? String
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let budgetList = appDelegate?.budgetList
        let budget = budgetList?.first(where: { (budget) -> Bool in
        
            return ( budget.value(forKey: XYZBudget.name) as? String ?? "" ) == budgetCategory
        })
        
        if let _ = budget, let iconName = budget?.value(forKey: XYZBudget.iconName) as? String, iconName != "" {
            
            icon.image = UIImage(named: iconName)
        } else {
            
            icon.image = UIImage(named: "empty")
        }
        
        let color = XYZColor(rawValue: budget?.value(forKey: XYZBudget.color) as? String ?? "")
  
        if let _ = colorView {
        
            dotColorView.backgroundColor = color?.uiColor()
        }
        
        let recurring = XYZExpense.Length(rawValue: expense.value(forKey: XYZExpense.recurring) as? String ?? XYZExpense.Length.none.rawValue )
        let theDate = (expense.value(forKey: XYZExpense.date) as? Date) ?? Date()
        switch recurring! {
            
            case .none:
                date.text = formattingDate(date: theDate, style: .medium )
            
            case .daily:
                date.text = "daily: since \(formattingDate(date: theDate, style: .medium ))"
            
            case .biweekly:
                let f = DateFormatter()
                date.text = "biweekly: \(f.weekdaySymbols[Calendar.current.component(.weekday, from: theDate)])"
            
            case .weekly:
                let f = DateFormatter()
                date.text = "weekly: \(f.weekdaySymbols[Calendar.current.component(.weekday, from: theDate)])"
            
            case .monthly:
                
                let occurrenceDates = expense.getOccurenceDates(until: Date())
                var nowDate: Date?
                let monthYearDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: monthYearDate!)
                for occurence in occurrenceDates {
                    
                    let nowDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: occurence)
                    if nowDateComponents.month! == monthYearDateComponents.month!
                        && nowDateComponents.year! == monthYearDateComponents.year! {
                        
                        nowDate = occurence
                    }
                }
                
                date.text = "monthly: \(formattingDate(date: nowDate!, style: .medium ))"
            
            case .halfyearly:
                let occurrenceDates = expense.getOccurenceDates(until: Date())
                var nowDate: Date?
                let monthYearDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: monthYearDate!)
          
                for occurence in occurrenceDates {
                    
                    let nowDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: occurence)
                    if nowDateComponents.month! == monthYearDateComponents.month!
                        && nowDateComponents.year! == monthYearDateComponents.year! {
                        
                        nowDate = occurence
                    }
                }
                
                date.text = "half yearly: \(formattingDate(date: nowDate!, style: .medium ))"
            
            case .yearly:
                let f = DateFormatter()
                f.dateFormat = "YYYY"

                let theDateComponents = Calendar.current.dateComponents([.day], from: theDate)
                
                let nowDate = Calendar.current.date(byAdding: .day, value: theDateComponents.day! - 1, to: monthYearDate!)
                date.text = "yearly: \(formattingDate(date: nowDate!, style: .medium ))"
        }
    }
}
