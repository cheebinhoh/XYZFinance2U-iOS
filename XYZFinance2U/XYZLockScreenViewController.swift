//
//  XYZLockScreenViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/27/17.
//  Copyright © 2017 - 2019 - 2019 Chee Bin Hoh. All rights reserved.

import UIKit

class XYZLockScreenViewController: UIViewController {

    // MARK: - property
    
    weak var mainTableViewController: XYZIncomeTableViewController?
    
    // MARK: - outlet
    
    @IBOutlet weak var unlock: UILabel!
    @IBOutlet weak var unlockButton: UIButton!
    
    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //let tap = UITapGestureRecognizer(target: self, action: #selector(touchToUnlock(_:)))
        //self.unlock.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - target-action
    
    @objc
    @IBAction func touchToUnlock(_ sender: UITapGestureRecognizer) {
        
        mainTableViewController?.authenticate()
    }

    @IBAction func unlock(_ sender: Any) {
        
        mainTableViewController?.authenticate()
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
