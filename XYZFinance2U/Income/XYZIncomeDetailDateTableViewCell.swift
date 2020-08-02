//
//  XYZIncomeDetailDateTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/24/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol XYZIncomeDetailDateTableViewCellDelegate : class {
    
    func dateInputTouchUp(sender:XYZIncomeDetailDateTableViewCell)
}

class XYZIncomeDetailDateTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: XYZIncomeDetailDateTableViewCellDelegate?
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
