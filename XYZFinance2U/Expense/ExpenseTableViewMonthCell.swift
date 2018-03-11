//
//  ExpenseTableViewMonthCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 3/10/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class ExpenseTableViewMonthCell: UITableViewCell {

    var index: Int?
    var highlightIndex: Int?
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBAction func button(_ sender: Any) {
        
        let newIndex = stackView.arrangedSubviews.index(of: sender as! UIView)
        
        if nil == index || index! != newIndex {
            
            index = newIndex
        } else {
        
            index = nil
        }
        
        drawSelectionState()
    }
    
    func drawSelectionState() {

        for (indexPos, subview) in stackView.arrangedSubviews.enumerated() {
            
            if let button = subview as? UIButton {
                
                var backgroundColor = UIColor.clear
                var textColor = UIColor.lightGray
                
                if let _ = index, index == indexPos {
                    
                    backgroundColor = UIColor.black
                    textColor = UIColor.white
                }
                
                button.setTitleColor(textColor, for: .normal)
                button.backgroundColor = backgroundColor
            }
        }
        
        stackView.setNeedsDisplay()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        drawSelectionState()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
