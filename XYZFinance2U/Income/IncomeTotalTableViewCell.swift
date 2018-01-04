//
//  IncomeTotalTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

class IncomeTotalTableViewCell: UITableViewCell {

    // MARK: IBOutlet
    
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

    func setAmount(amount: Double) {
        
        self.amount.text = formattingCurrencyValue(input: amount, nil )
    }
}
