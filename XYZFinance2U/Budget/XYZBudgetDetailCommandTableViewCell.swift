//
//  XYZBudgetDetailCommandTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/17/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol XYZBudgetDetailCommandDelegate: class {
    
    func executeCommand(sender: XYZBudgetDetailCommandTableViewCell)
}

class XYZBudgetDetailCommandTableViewCell: UITableViewCell {

    // MARK: - property
    
    weak var delegate: XYZBudgetDetailCommandDelegate?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var command: UILabel!
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setCommand(command: String) {
        
        self.command.text = command
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchToRun(_:)))
        self.command.addGestureRecognizer(tap)
    }
    
    // MARK: - IBAction
    
    @objc
    @IBAction func touchToRun(_ sender: UITapGestureRecognizer) {
        
        self.delegate?.executeCommand(sender: self)
    }
    
}
