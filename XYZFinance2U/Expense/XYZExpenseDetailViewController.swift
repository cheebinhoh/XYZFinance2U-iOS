//
//  XYZExpenseDetailViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/27/18.
//  Copyright © 2018 - 2019 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZExpenseDetailViewController: UIViewController {

    // MARK: - property
    
    var expense: XYZExpense?
    var indexPath: IndexPath?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var date: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let _ = expense {
            
            let detailValue = expense?.value(forKey: XYZExpense.detail) as? String
            let amountValue = expense?.value(forKey: XYZExpense.amount) as? Double
            let dateValue = expense?.value(forKey: XYZExpense.date) as? Date

            detail.text = detailValue!
            amount.text = formattingCurrencyValue(of: amountValue!, as: Locale.current.currencyCode)
            date.text = formattingDate(dateValue!, style: .medium)
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
