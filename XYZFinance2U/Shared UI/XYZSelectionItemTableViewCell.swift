//
//  XYZSelectionItemTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/3/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class XYZSelectionItemTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    var color = UIColor.clear
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        colorView.backgroundColor = color
        // Configure the view for the selected state
    }

}
