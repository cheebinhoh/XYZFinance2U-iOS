//
//  ExpenseDetailViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/27/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class ExpenseDetailViewController: UIViewController {

    // MARK: - property
    
    var expense: XYZExpense?
    var indexPath: IndexPath?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var date: UILabel!
    
    // MARK: 3d touch
    
    override var previewActionItems : [UIPreviewActionItem] {
        
        return previewActions
    }
    
    lazy var previewActions: [UIPreviewActionItem] = {

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        let copyAction = UIPreviewAction(title: "Copy share url", style: .default, handler: { (action, viewcontroller) in
            
            if let expense = self.expense {
                
                if let url = expense.value(forKey: XYZExpense.shareUrl) as? String {
                    
                    UIPasteboard.general.string = "\(url)"
                }
            }

            mainSplitView.popOverAlertController = nil
        })
        
        let cancelAction = UIPreviewAction(title: "Cancel", style: .default, handler: { (action, viewcontroller) in
            
            mainSplitView.popOverAlertController = nil
        })
        
        mainSplitView.popOverAlertController = self
        
        return [copyAction, cancelAction]
    }()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let _ = expense {
            
            let detailValue = expense?.value(forKey: XYZExpense.detail) as? String
            let amountValue = expense?.value(forKey: XYZExpense.amount) as? Double
            let dateValue = expense?.value(forKey: XYZExpense.date) as? Date

            detail.text = detailValue!
            amount.text = formattingCurrencyValue(input: amountValue!, code: Locale.current.currencyCode)
            date.text = formattingDate(date: dateValue!, style: .medium)
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
