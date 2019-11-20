//
//  XYZExpenseTableViewMonthCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 3/10/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol XYZExpenseTableViewMonthChange: class {
    
    func change(_ monthYear: Date!)
}

class XYZExpenseTableViewMonthCell: UITableViewCell {

    var index: Int?
    var highlightIndex: Int?
    var buttonText = [String]()
    var date: Date?
    var delegate: XYZExpenseTableViewMonthChange?
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBAction func button(_ sender: Any) {
        
        let count = stackView.arrangedSubviews.count
        let newIndex = stackView.arrangedSubviews.firstIndex(of: sender as! UIView)
        var monthYear: Date? 
        
        if nil == index || index! != newIndex! {
            
            if newIndex! <= 0 {
                
                //let prevMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: date!)
                //setDate(prevMonthDate!)
                
                //index = nil
            } else if newIndex! >= (count - 1) {
            
                //let nextMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: date!)
                //setDate(nextMonthDate!)
                
                //index = nil
            } else {
            
                let monthGap = newIndex! - 3

                monthYear = Calendar.current.date(byAdding: .month, value: monthGap, to: date!)
                index = newIndex
            }
        } else {
        
            index = nil
        }
        
        drawSelectionState()
        delegate?.change(monthYear)
    }
    
    func drawSelectionState() {

        let count = stackView.arrangedSubviews.count
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM, YY"
        let currentMonthYear = formatter.string(from: Date())
        
        for (indexPos, subview) in stackView.arrangedSubviews.enumerated() {
            
            if let button = subview as? UIButton, indexPos > 0 && indexPos < (count - 1)  {
                
                let title = buttonText[indexPos - 1]
                var backgroundColor = UIColor.clear
                var textColor = UIColor.darkText
                
                if let _ = index, index == indexPos {
                    
                    backgroundColor = UIColor.black
                    textColor = UIColor.white
                    
                    if title == currentMonthYear {
                        
                        backgroundColor = UIColor.red
                    }
                } else {
                    
                    if title == currentMonthYear {
                        
                        textColor = UIColor.red
                    }
                }
                
                button.setTitle(title, for: .normal)
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
        
        index = nil
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
