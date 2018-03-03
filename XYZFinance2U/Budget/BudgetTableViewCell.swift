//
//  BudgetTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/13/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class BudgetTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var length: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var spendAmount: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    var color = UIColor.clear
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorView.backgroundColor = color
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
