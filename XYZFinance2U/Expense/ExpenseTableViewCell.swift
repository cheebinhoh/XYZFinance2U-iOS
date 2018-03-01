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
    
    // MARK: - function
    override func awakeFromNib() {
        
        super.awakeFromNib()
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
        
        
        let recurring = XYZExpense.Length(rawValue: expense.value(forKey: XYZExpense.recurring) as? String ?? XYZExpense.Length.none.rawValue )
        let theDate = (expense.value(forKey: XYZExpense.date) as? Date) ?? Date()
        switch recurring! {
            
            case .none:
                date.text = formattingDate(date: theDate, style: .medium )
            
            case .daily:
                date.text = "daily since \(formattingDate(date: theDate, style: .medium ))"
            
            case .biweekly:
                let f = DateFormatter()
                date.text = "biweekly at \(f.weekdaySymbols[Calendar.current.component(.weekday, from: theDate)])"
            
            case .weekly:
                let f = DateFormatter()
                date.text = "weekly at \(f.weekdaySymbols[Calendar.current.component(.weekday, from: theDate)])"
            
            case .monthly:
                let f = DateFormatter()
                f.dateFormat = "MMMM, YYYY"
                
                date.text = "monthly since \(f.string(from: (expense.value(forKey: XYZExpense.date) as? Date) ?? Date()))"
            
            case .yearly:
                let f = DateFormatter()
                f.dateFormat = "YYYY"
                
                date.text = "yearly since \(f.string(from: theDate))"
        }
    }
}
