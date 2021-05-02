//
//  XYZBudgetDetailDateTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/16/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

protocol XYZBudgetDetailDateTableViewCellDelegate: AnyObject {
    
    func dateInputTouchUp(sender:XYZBudgetDetailDateTableViewCell)
}

class XYZBudgetDetailDateTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: XYZBudgetDetailDateTableViewCellDelegate?
    var enableEditing = true
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var dateInput: UILabel!
    @IBOutlet weak var label: UILabel!
    
    // MARK: - function
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dateInputTouchUp(_:)))
        dateInput.addGestureRecognizer(tap)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - IBAction
    @objc
    @IBAction func dateInputTouchUp(_ sender: UITapGestureRecognizer) {
        
        if enableEditing {
            
            delegate?.dateInputTouchUp(sender: self)
        }
    }
}
