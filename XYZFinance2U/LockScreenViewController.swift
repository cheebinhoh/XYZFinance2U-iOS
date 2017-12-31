//
//  LockScreenViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

class LockScreenViewController: UIViewController {

    // MARK: - property
    
    weak var mainTableViewController: IncomeTableViewController?
    
    // MARK: - outlet
    
    @IBOutlet weak var unlock: UILabel!

    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(touchToUnlock(_:)))
        self.unlock.addGestureRecognizer(tap)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
