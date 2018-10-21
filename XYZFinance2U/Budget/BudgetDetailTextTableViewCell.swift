//
//  BudgetDetailTextTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/16/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol BudgetDetailTextTableViewCellDelegate : class {
    
    func textDidEndEditing(_ sender:BudgetDetailTextTableViewCell)
    func textDidBeginEditing(_ sender:BudgetDetailTextTableViewCell)
}

class BudgetDetailTextTableViewCell: UITableViewCell,
    UITextFieldDelegate {

    // MARK: - property
    
    var monetory = false
    weak var delegate: BudgetDetailTextTableViewCellDelegate?
    var currencyCode: String = Locale.current.currencyCode!
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.input.delegate = self
        self.input.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

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
    
    func enableMonetaryEditing(_ enanble: Bool, _ currencyCode: String) {
        
        monetory = enanble
        
        if enanble {
            
            self.currencyCode = currencyCode
            input.addDoneToolbar(onDone: nil)
            input.clearButtonMode = .never
            input.keyboardType = .numberPad
            input.text = formattingCurrencyValue(input: 0.0, code: self.currencyCode)
            input.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        } else {
            
            input.keyboardType = .default
            input.text = ""
            input.addTarget(nil, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    // MARK: - IBAction
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        
        if monetory {
            
            var text = textField.text ?? "0.00"
            
            text = formattingDoubleValue(input: text)
            text = formattingAndProcessDoubleValue(input: text)
            text = formattingCurrencyValue(input: text, code: currencyCode)
            textField.text = text
            delegate?.textDidEndEditing(self)
        }
        else
        {
    
            delegate?.textDidEndEditing(self)
        }
    }
}
