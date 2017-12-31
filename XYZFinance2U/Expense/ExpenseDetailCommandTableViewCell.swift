//
//  ExpenseDetailCommandTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/22/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol ExpenseDetailCommandDelegate: class {
    
    func executeCommand(_ sender: ExpenseDetailCommandTableViewCell)
}

class ExpenseDetailCommandTableViewCell: UITableViewCell {

    // MARK: - property
    
    var delegate: ExpenseDetailCommandDelegate?

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
        
        self.delegate?.executeCommand(self)
    }
}
