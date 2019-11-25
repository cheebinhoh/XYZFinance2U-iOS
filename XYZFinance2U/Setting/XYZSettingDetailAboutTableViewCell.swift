//
//  XYZSettingDetailAboutTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/6/18.
//  Copyright © 2018 - 2019 CB Hoh. All rights reserved.
//

import UIKit

class XYZSettingDetailAboutTableViewCell: UITableViewCell {

    // MARK: - IBOutlet

    @IBOutlet weak var content: UITextView!

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        content.textContainer.maximumNumberOfLines = 0
        content.isScrollEnabled = false
        content.sizeToFit()
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
