//
//  ExpenseDetailSelectionTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/9/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class ExpenseDetailSelectionTableViewCell: UITableViewCell {

    @IBOutlet weak var selection: UILabel!
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setSelection(_ selection: String) {
        
        self.selection.text = selection
    }
}
