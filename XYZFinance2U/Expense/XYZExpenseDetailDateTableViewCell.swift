//
//  XYZExpenseDetailDateTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/10/17.
//  Copyright © 2017 - 2019 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol XYZExpenseDetailDateTableViewCellDelegate: class {
    
    func dateInputTouchUp(_ sender:XYZExpenseDetailDateTableViewCell)
}

class XYZExpenseDetailDateTableViewCell: UITableViewCell {
    
    // MARK: - property
    weak var delegate: XYZExpenseDetailDateTableViewCellDelegate?
    var enableEditing = true
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var dateInput: UILabel!
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(dateInputTouchUp(_:)))
        dateInput.addGestureRecognizer(tap)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    // MARK: - IBAction
    
    @objc
    @IBAction func dateInputTouchUp(_ sender: UITapGestureRecognizer) {
        
        if enableEditing {
            
            delegate?.dateInputTouchUp(self)
        }
    }

}
