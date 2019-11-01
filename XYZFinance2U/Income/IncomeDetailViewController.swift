//
//  IncomeDetailViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/19/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class IncomeDetailViewController: UIViewController {

    // MARK: property
    
    var income: XYZAccount?
    var currencyCode: String?
    var indexPath: IndexPath?
    
    @IBOutlet weak var bank: UILabel!
    @IBOutlet weak var accountNr: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var principal: UILabel!
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
        
        let copyAction = UIPreviewAction(title: "Copy balance".localized(), style: .default, handler: { (action, viewcontroller) in
            
            var balance = 0.0
            
            if let _ = self.income {
            
                balance = (self.income?.value(forKey: XYZAccount.amount) as? Double)!
            }
            
            mainSplitView.popOverAlertController  = nil
            UIPasteboard.general.string = "\(balance)"
        })
        
        let cancelAction = UIPreviewAction(title: "Cancel".localized(), style: .default, handler: { (action, viewcontroller) in
            
            mainSplitView.popOverAlertController  = nil
        })

        mainSplitView.popOverAlertController = self
        
        return [copyAction, cancelAction]
    }()
    
    // MARK: function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let _ = income {
            
            let bankValue = income?.value(forKey: XYZAccount.bank) as? String
            let accountNrValue = income?.value(forKey: XYZAccount.accountNr) as? String
            let currencyCode = income?.value(forKey: XYZAccount.currencyCode) as? String ?? Locale.current.currencyCode
            let balance = income?.value(forKey: XYZAccount.amount) as? Double
            let principalAmount = income?.value(forKey: XYZAccount.principal) as? Double ?? 0.0

            bank.text = bankValue
            accountNr.text = accountNrValue
            amount.text = formattingCurrencyValue(input: balance!, code:currencyCode)
            principal.text = formattingCurrencyValue(input: principalAmount, code:currencyCode)
            date.text = formattingDate((income?.value(forKey: XYZAccount.lastUpdate) as? Date )!, style: .medium)
        }
        
        // Do any additional setup after loading the view.
    }

    /*
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.

        print("************* didReceiveMemoryWarning")
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
