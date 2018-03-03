//
//  BudgetDetailSelectionTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/16/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class BudgetDetailSelectionTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selection: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - function
    func setLabel(_ label: String) {
        
        self.label.text = label
    }
    
    func setSelection(_ selection: String) {
        
        self.selection.text = selection
    }

}
