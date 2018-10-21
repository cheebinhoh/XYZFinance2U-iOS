//
//  IncomeDetailSwitchTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/1/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol IncomeDetailSwitchDelegate : class {
    
    func optionUpdate(_ sender: IncomeDetailSwitchTableViewCell, option: Bool)
}

class IncomeDetailSwitchTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switchOption: UISwitch!
    
    // MARK: - property
    
    weak var delegate: IncomeDetailSwitchDelegate?
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        switchOption.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - functions
    
    func setOption(_ optionText: String, default option: Bool) {
        
        label.text = optionText
        switchOption.isOn = option
    }
    
    // MARK: - IBAction
    
    @objc
    func switchChanged(_ switchOption: UISwitch) {
        
        let value = switchOption.isOn
        
        delegate?.optionUpdate(self, option: value )
        // Do something
    }
}
