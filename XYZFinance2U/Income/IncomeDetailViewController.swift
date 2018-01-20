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
    var income: [XYZAccount]?
    
    // MARK: 3d touch
    
    override var previewActionItems : [UIPreviewActionItem] {
        
        return previewActions
    }
    
    lazy var previewActions: [UIPreviewActionItem] = {

        let copyAction = UIPreviewAction(title: "Copy", style: .default, handler: { (action, viewcontroller) in
            
        })
        
        return [copyAction]
    }()
    
    // MARK: function
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
