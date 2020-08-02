//
//  XYZTextTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/25/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

@objc
protocol XYZTextTableViewCellDelegate : class {

    func textDidBeginEditing(sender: XYZTextTableViewCell)
    func textDidEndEditing(sender: XYZTextTableViewCell)
    @objc optional func switchChanged(_ yesno: Bool, sender: XYZTextTableViewCell)
}

class XYZTextTableViewCell: UITableViewCell,
    UITextFieldDelegate {

    // MARK: - property
    weak var delegate: XYZTextTableViewCellDelegate?
    var monetory = false
    var currencyCode = Locale.current.currencyCode!
    var isEditable = true
    
    // MARK: - IBOutlet
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var stack: UIStackView!

    // MARK: - function
    
    func addUISwitch() {
        
        let cgpoint = CGPoint(x: 0.0, y: 0.0)
        let frame = CGRect(origin: cgpoint, size: CGSize(width: 20, height: 35))
        let uiswitch = UISwitch(frame: frame)
        
        uiswitch.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        
        optionSwitch = uiswitch
        self.stack.addArrangedSubview(uiswitch)
    }
    
    @objc
    func switchChanged(_ switchValue: UISwitch) {
        
        delegate?.switchChanged!(switchValue.isOn, sender: self)
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
        
        delegate?.textDidBeginEditing(sender: self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        delegate?.textDidEndEditing(sender: self)
    }
    
    func enableMonetaryEditing(_ enable: Bool, of currencyCode: String? = nil) {
        
        monetory = enable
        
        if enable {
            
            self.currencyCode = currencyCode ?? Locale.current.currencyCode!
            input.addDoneToolbar(onDone: nil)
            input.clearButtonMode = .never
            input.keyboardType = .numberPad
            input.text = formattingCurrencyValue(of: 0.0, as: self.currencyCode)
        } else {
            
            input.keyboardType = .default
        }
    }
    
    func disableMonetaryEditing() {
        
        monetory = false
        input.keyboardType = .default
        currencyCode = ""
    }
    
    // MARK: - IBAction
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        
        if monetory {
            
            var text = textField.text ?? "0.00"
            
            text = formattingDoubleValue(of: text)
            text = formattingAndProcessDoubleValue(of: text)
            text = formattingCurrencyValue(of: text, as: currencyCode)
            textField.text = text
        }
        
        delegate?.textDidEndEditing(sender: self)
    }
}
