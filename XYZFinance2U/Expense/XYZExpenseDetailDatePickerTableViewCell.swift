//
//  XYZExpenseDetailDatePickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/11/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol XYZExpenseDetailDatePickerTableViewCellDelegate: class {
    
    func dateDidPick(_ sender:XYZExpenseDetailDatePickerTableViewCell)
}

class XYZExpenseDetailDatePickerTableViewCell: UITableViewCell {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - property
    
    var date: Date?
    weak var delegate: XYZExpenseDetailDatePickerTableViewCellDelegate?
    
    // MARK: function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
    }

    func setDate(_ date: Date) {
        
        self.date = date
        datePicker.date = date
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
