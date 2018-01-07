//
//  IncomeDetailSelectionTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/3/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class IncomeDetailSelectionTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selection: UILabel!
    
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
