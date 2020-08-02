//
//  XYZSettingTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 - 2019 Chee Bin Hoh. All rights reserved.
//

import UIKit

protocol XYZSettingTextTableViewCellDelegate: class {
    
    func switchChanged(_ yesno: Bool, _ sender:XYZSettingTableViewCell)
}

class XYZSettingTableViewCell: UITableViewCell {
    
    // MARK: - outlet
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var stack: UIStackView!
    var delegate: XYZSettingTextTableViewCellDelegate?
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - function
    func addUISwitch() {
        
        let cgpoint = CGPoint(x: 0.0, y: 0.0)
        let frame = CGRect(origin: cgpoint , size: CGSize(width: 20, height: 35))
        let uiswitch = UISwitch(frame: frame)
        
        uiswitch.addTarget(self, action: #selector(switchChanged(_:)), for: UIControl.Event.valueChanged)
        
        optionSwitch = uiswitch
        self.stack.addArrangedSubview(uiswitch)
    }
    
    func removeUISwitch() {
        
        if let _ = optionSwitch {
            
            self.stack.removeArrangedSubview(optionSwitch)
            optionSwitch.removeFromSuperview()
        }
    }
    
    @objc
    func switchChanged(_ value: UISwitch) {
        
        delegate?.switchChanged(value.isOn, self)
        // Do something
    }
    
}
