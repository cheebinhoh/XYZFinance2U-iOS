//
//  IncomeDetailDatePickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/24/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol IncomeDetailDatePickerTableViewCellDelegate : class {
    
    func dateDidPick(_ sender:IncomeDetailDatePickerTableViewCell)
}

class IncomeDetailDatePickerTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlet
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - property
    
    weak var delegate: IncomeDetailDatePickerTableViewCellDelegate?
    var date: Date?
    
    // MARK: - function
    
    func setDate(_ date: Date)
    {
        self.date = date
        datePicker.date = date
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - IBAction
    
    @IBAction func datePick(_ sender: UIDatePicker) {
        
        date = sender.date
        delegate?.dateDidPick(self)
    }
}
