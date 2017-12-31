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
        
        amount.text = formattingCurrencyValue(input: (expense.value(forKey: XYZExpense.amount) as? Double) ?? 0.0 )
        date.text = formattingDate(date: (expense.value(forKey: XYZExpense.date) as? Date) ?? Date() )
        detail.text = ( expense.value(forKey: XYZExpense.detail) as? String ) ?? ""
    }
}
