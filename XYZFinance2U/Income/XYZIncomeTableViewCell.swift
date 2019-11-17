//
//  XYZIncomeTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

class XYZIncomeTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var bank: UILabel!
    @IBOutlet weak var account: UILabel!
    @IBOutlet weak var amount: UILabel!
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
