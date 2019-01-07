//
//  XYZTextTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/25/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

@objc
protocol XYZTextTableViewCellDelegate : class {
    
    func textDidEndEditing(_ sender:XYZTextTableViewCell)
    func textDidBeginEditing(_ sender:XYZTextTableViewCell)
    @objc optional func switchChanged(_ yesno: Bool, _ sender: XYZTextTableViewCell)
}

class XYZTextTableViewCell: UITableViewCell,
    UITextFieldDelegate {

    // MARK: - property
    var monetory = false
    weak var delegate: XYZTextTableViewCellDelegate?
    var currencyCode: String = Locale.current.currencyCode!
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var stack: UIStackView!
    var isEditable = true
    
    // MARK: - function
    
    func addUISwitch() {
        
        let cgpoint = CGPoint(x: 0.0, y: 0.0)
        let frame = CGRect(origin: cgpoint , size: CGSize(width: 20, height: 35))
        let uiswitch = UISwitch(frame: frame)
        
        uiswitch.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        
        optionSwitch = uiswitch
        self.stack.addArrangedSubview(uiswitch)
    }
    
    @objc
    func switchChanged(_ locationSwitch: UISwitch) {
        
        let value = locationSwitch.isOn
        
        delegate?.switchChanged!(value, self)
        // Do something
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        return isEditable
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.input.delegate = self
        input.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        } else {
            
            input.keyboardType = .default
            input.text = ""
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
        else {
            
            delegate?.textDidEndEditing(self)
        }
    }

}