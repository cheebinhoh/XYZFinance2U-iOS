//
//  XYZExpenseTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/8/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZExpenseTableViewCell: UITableViewCell {
    
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
        
        amount.text = formattingCurrencyValue(of: (expense.value(forKey: XYZExpense.amount) as? Double) ?? 0.0,
                                              as: expense.value(forKey: XYZExpense.currencyCode) as? String )
        detail.text = ( expense.value(forKey: XYZExpense.detail) as? String ) ?? ""
        date.text = formattingDate((expense.value(forKey: XYZExpense.date) as? Date) ?? Date(), style: .medium )
        
        let budgetCategory = expense.value(forKey: XYZExpense.budgetCategory) as? String
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let budgetList = appDelegate?.budgetList
        let budget = budgetList?.first(where: { (budget) -> Bool in
        
            return ( budget.value(forKey: XYZBudget.name) as? String ?? "" ) == budgetCategory
        })
        
        if let _ = icon {
            
            if let iconName = budget?.value(forKey: XYZBudget.iconName) as? String, iconName != "" {
                
                icon.image = UIImage(named: iconName)
                icon.image = icon.image?.withRenderingMode(.alwaysTemplate)
                
                if #available(iOS 13.0, *) {
                    
                    icon.image?.withTintColor(UIColor.systemBlue)
                } else {
                    // Fallback on earlier versions
                }
            } else {
                
                icon.image = UIImage(named: "empty")
            }
        }
        
        let color = XYZColor(rawValue: budget?.value(forKey: XYZBudget.color) as? String ?? "")
  
        if let _ = colorView {
        
            dotColorView.isHidden = false
            dotColorView.backgroundColor = color?.uiColor()
        }

        let recurring = XYZExpense.Length(rawValue: expense.value(forKey: XYZExpense.recurring) as? String ?? XYZExpense.Length.none.rawValue )
        let theDate = (expense.value(forKey: XYZExpense.date) as? Date) ?? Date()
        switch recurring! {
            
            case .none:
                date.text = formattingDate(theDate, style: .medium )
           
            case let other:
                date.text = other.description().localized()
        }
    }
}
