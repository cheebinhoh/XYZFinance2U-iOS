//
//  XYZBudgetTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/13/18.
//  Copyright © 2018 - 2019 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZBudgetTableViewCell: UITableViewCell {

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var length: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var dotColorView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        colorView.backgroundColor = UIColor.clear
        
        if let _ = icon {
            
            icon.image = UIImage(named: "")
        }
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
