//
//  ExpenseDetailLocationPickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/25/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol ExpenseDetailLocationPickerDelegate: class {
    
    func locationTouchUp(_ sender: ExpenseDetailLocationPickerTableViewCell)
}

class ExpenseDetailLocationPickerTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: ExpenseDetailLocationPickerDelegate?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var location: UILabel!

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(locationTouchUp(_:)))
        location.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - IBAction
    
    @objc
    @IBAction func locationTouchUp(_ sender: UITapGestureRecognizer) {
        
        delegate?.locationTouchUp(self)
    }
}
