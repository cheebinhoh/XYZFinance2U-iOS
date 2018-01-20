//
//  ExchangeRateTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/20/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class ExchangeRateTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var base2target: UILabel!
    @IBOutlet weak var rate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
