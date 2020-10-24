//
//  XYZMainUITabBarController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/19/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.

import UIKit

class XYZMainUITabBarController: UITabBarController,
    UITabBarControllerDelegate {

    // MARK: - property
    
    weak var popOverNavigatorController: UINavigationController?
    weak var popOverAlertController: UIViewController?
    
    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.delegate = self
        
        /* We do not need notification action and category as identifier itself is enough for us now.
        let updateAction = UNNotificationAction(identifier: "review", title: "Review", options: [])
        let category = UNNotificationCategory(identifier: "Income", actions: [updateAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: [])
        notificationCenter.setNotificationCategories([category])
         */
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITabBar delegate
    
    // when we switch the tab, we want to create proper secondary detail view in the master-detail view.
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
  
        guard let moreNavController = tabBarController.viewControllers?[3] as? UINavigationController else {
            
            fatalError("Exception: moreNavController is expected")
        }
        
        guard let moreView = moreNavController.viewControllers.first as? XYZMoreTableViewController else {
            
            fatalError("Exception: XYZMoreTableViewController is expected")
        }
        
        moreView.reload()
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
