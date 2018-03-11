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
    var buttonText = [String]()
    var date: Date?
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBAction func button(_ sender: Any) {
        
        let count = stackView.arrangedSubviews.count
        let newIndex = stackView.arrangedSubviews.index(of: sender as! UIView)
        
        if nil == index || index! != newIndex! {
            
            if newIndex! <= 0 {
                
                let prevMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: date!)
                setDate(prevMonthDate!)
                
                index = nil
            } else if newIndex! >= (count - 1) {
            
                let nextMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: date!)
                setDate(nextMonthDate!)
                
                index = nil
            } else {
            
                index = newIndex
            }
        } else {
        
            index = nil
        }
        
        drawSelectionState()
    }
    
    func drawSelectionState() {

        let count = stackView.arrangedSubviews.count
        
        for (indexPos, subview) in stackView.arrangedSubviews.enumerated() {
            
            if let button = subview as? UIButton, indexPos > 0 && indexPos < (count - 1)  {
                
                var backgroundColor = UIColor.clear
                var textColor = UIColor.darkText
                
                if let _ = index, index == indexPos {
                    
                    backgroundColor = UIColor.black
                    textColor = UIColor.white
                }
                
                button.setTitle(buttonText[indexPos - 1], for: .normal)
                button.setTitleColor(textColor, for: .normal)
                button.backgroundColor = backgroundColor
            }
        }
        
        stackView.setNeedsDisplay()
    }
    
    func setDate(_ date: Date) {
        
        self.date = date
        buttonText = [String]()
        
        var count = 0
        while count < 3 {
            
            let thisDate = Calendar.current.date(byAdding: .month, value: -1 * count, to: date)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM, YY"
            
            buttonText.insert( "\(formatter.string(from: thisDate!))", at: 0)

            count = count + 1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setDate(Date())
        
        drawSelectionState()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
