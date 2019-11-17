//
//  XYZIncomeTotalTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

class XYZIncomeTotalTableViewCell: UITableViewCell {

    // MARK: IBOutlet
    
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var currency: UILabel!
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setAmount(amount: Double, code: String) {
        
        self.amount.text = formattingCurrencyValue(of: amount, as: code )
    }
}
