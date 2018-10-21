//
//  ExpenseDetailLocationTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/25/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol ExpenseDetailLocationDelegate: class {
    
    func locationSwitch(_ yesno: Bool, _ sender: ExpenseDetailLocationTableViewCell)
}

class ExpenseDetailLocationTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: ExpenseDetailLocationDelegate?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var location: UISwitch!

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        location.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - IBAction
    
    @objc
    func switchChanged(_ locationSwitch: UISwitch) {
        
        let value = locationSwitch.isOn
        
        delegate?.locationSwitch(value, self)
        // Do something
    }
}
