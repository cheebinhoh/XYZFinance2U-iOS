//
//  XYZSelectionTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/31/18.
//  Copyright © 2018 - 2019 CB Hoh. All rights reserved.
//

import UIKit

class XYZSelectionTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var selection: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
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
        
        self.selection.text = selection.localized()
    }
    
    func setSeletionTextColor(_ color: UIColor) {
    
        self.selection.textColor = color
    }

}
