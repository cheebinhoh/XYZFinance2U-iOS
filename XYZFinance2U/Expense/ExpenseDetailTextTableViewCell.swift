//
//  ExpenseTextTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/10/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol ExpenseDetailTextTableViewCellDelegate: class {
    
    func textDidEndEditing(_ sender:ExpenseDetailTextTableViewCell)
    func textDidBeginEditing(_ sender:ExpenseDetailTextTableViewCell)
}

class ExpenseDetailTextTableViewCell: UITableViewCell,
    UITextFieldDelegate {
    
    // MARK: - property
    
    @IBOutlet weak var input: UITextField!
    weak var delegate: ExpenseDetailTextTableViewCellDelegate?

    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        
        self.input.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - textfield delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        delegate?.textDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        
        delegate?.textDidEndEditing(self)
    }
    
    func enableMonetaryEditing(_ enanble: Bool) {
        
        if enanble {
            
            input.clearButtonMode = .never
            input.keyboardType = .numberPad
            input.text = formattingCurrencyValue(input: 0.0, nil)
            input.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        } else {
            
            input.keyboardType = .default
            input.text = ""
            input.addTarget(nil, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        var text = textField.text ?? "0.00"
        
        text = formattingDoubleValue(input: text)
        text = formattingAndProcessDoubleValue(input: text)
        text = formattingCurrencyValue(input: text, nil)
        textField.text = text
        delegate?.textDidEndEditing(self)
    }
}
