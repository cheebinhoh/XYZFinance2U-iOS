//
//  XYZMainSplitViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/29/17.
//  Copyright © 2017 - 2019 - 2019 CB Hoh. All rights reserved.

import UIKit

class XYZMainSplitViewController: UISplitViewController {
    
    // MARK: - property
    
    weak var popOverNavigatorController: UINavigationController?
    weak var popOverAlertController: UIViewController?
    
    // MARK: - function

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
