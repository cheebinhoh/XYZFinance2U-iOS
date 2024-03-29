//
//  XYZIncomeDetailViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/19/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZIncomeDetailViewController: UIViewController {

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
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        return previewActions
    }
    
    lazy var previewActions: [UIPreviewActionItem] = {

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected" )
        }
        
        let copyAction = UIPreviewAction(title: "Copy balance".localized(), style: .default, handler: { (action, viewcontroller) in
            
            let balance = self.income?.amount ?? 0.0
            
            tabBarController.popOverAlertController  = nil
            UIPasteboard.general.string = "\(balance)"
        })
        
        let cancelAction = UIPreviewAction(title: "Cancel".localized(), style: .default, handler: { (action, viewcontroller) in
            
            tabBarController.popOverAlertController  = nil
        })

        tabBarController.popOverAlertController = self
        
        return [copyAction, cancelAction]
    }()
    
    // MARK: function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if let income = income {
            
            let bankValue = income.bank
            let accountNrValue = income.accountNr
            let currencyCode = income.currencyCode
            let balance = income.amount
            let principalAmount = income.principal

            bank.text = bankValue
            accountNr.text = accountNrValue
            amount.text = formattingCurrencyValue(of: balance, as: currencyCode)
            principal.text = formattingCurrencyValue(of: principalAmount, as: currencyCode)
            date.text = formattingDate(income.lastUpdate, style: .medium)
        }
        
        // Do any additional setup after loading the view.
    }

    /*
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
