//
//  XYZBudgetDetailDatePickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/16/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

protocol XYZBudgetDetailDatePickerTableViewCellDelegate : AnyObject {
    
    func dateDidPick(sender:XYZBudgetDetailDatePickerTableViewCell)
}

class XYZBudgetDetailDatePickerTableViewCell: UITableViewCell {

    // MARK: - IBOutlet
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // MARK: - property
    
    weak var delegate: XYZBudgetDetailDatePickerTableViewCellDelegate?
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
