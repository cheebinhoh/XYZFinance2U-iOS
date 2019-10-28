//
//  BudgetDetailDateTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/16/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol BudgetDetailDateTableViewCellDelegate : class {
    
    func dateInputTouchUp(sender:BudgetDetailDateTableViewCell)
}

class BudgetDetailDateTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: BudgetDetailDateTableViewCellDelegate?
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
