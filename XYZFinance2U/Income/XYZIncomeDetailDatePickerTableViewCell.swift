//
//  XYZIncomeDetailDatePickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/24/17.
//  Copyright © 2017 - 2019 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol XYZIncomeDetailDatePickerTableViewCellDelegate : class {
    
    func dateDidPick(sender:XYZIncomeDetailDatePickerTableViewCell)
}

class XYZIncomeDetailDatePickerTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - property
    
    weak var delegate: XYZIncomeDetailDatePickerTableViewCellDelegate?
    var date: Date?
    
    // MARK: - function
    
    func setDate(_ date: Date) {
        
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
        delegate?.dateDidPick(sender: self)
    }
}
