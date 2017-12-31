//
//  MainUITabBarController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/19/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

class MainUITabBarController: UITabBarController,
    UITabBarControllerDelegate {

    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.delegate = self

        guard let split = self.parent as? UISplitViewController else {
            fatalError("Exception: locate split view")
        }
        
        guard let navController = self.viewControllers?.first as? UINavigationController else {
            fatalError("Exception: navigation controller is expected")
        }
        
        if let incomeRoot = navController.viewControllers.first as? IncomeTableViewController {
            
            split.delegate = incomeRoot
        } else {
            
            fatalError("Exception: IncomeTableViewController is expected")
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITabBar delegate
    
    // when we switch the tab, we want to create proper secondary detail view in the master-detail view.
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        guard let split = self.parent as? UISplitViewController else {
            fatalError("Exception: locate split view")
        }
    
        var masterViewNavController: UINavigationController?
        
        if !split.isCollapsed && split.viewControllers.count > 1 {
            
            masterViewNavController = split.viewControllers.last as? UINavigationController
            
            guard nil != masterViewNavController else {
                fatalError("Exception: UINavigationController is expected")
            }
        }
        
        guard let navController = viewController as? UINavigationController else {
            fatalError("Exception: UINavigationController is expected")
        }
        
        if let incomeRoot = navController.viewControllers.first as? IncomeTableViewController {
            
            split.delegate = incomeRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? IncomeDetailTableViewController {
                
                // empty
            } else {
                
                guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "IncomeDetailNavigationController") as? UINavigationController else {
                    fatalError("Exception: IncomeDetailNavigationController is expected")
                }
                
                guard let incomeDetailTableViewController = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
                    fatalError("Exception: IncomeDetailTableViewController is expected")
                }
                
                incomeDetailTableViewController.navigationItem.title = ""
                incomeRoot.delegate = incomeDetailTableViewController

                masterViewNavController?.setViewControllers([incomeDetailTableViewController], animated: false)
            }
        } else if let expenseRoot = navController.viewControllers.first as? ExpenseTableViewController  {
            
            split.delegate = expenseRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? ExpenseDetailTableViewController {
                
                // empty
            } else {
                
                guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                    fatalError("Exception: ExpenseDetailNavigationController is expected")
                }
                
                guard let expenseDetailTableViewController = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                    fatalError("Exception: ExpenseDetailTableViewController is expected")
                }
                
                expenseDetailTableViewController.navigationItem.title = ""
                expenseRoot.delegate = expenseDetailTableViewController

                masterViewNavController?.setViewControllers([expenseDetailTableViewController], animated: false)
            }
        } else if let settingRoot = navController.viewControllers.first as? SettingTableViewController {
            
            split.delegate = settingRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? SettingDetailTableViewController {
                
                // empty
            } else {
                
                guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingDetailNavigationController") as? UINavigationController else {
                    fatalError("Exception: SettingDetailEmptyViewController is expected")
                }
                
                guard let settingDetailTableViewController = settingDetailNavigationController.viewControllers.first as? SettingDetailTableViewController else {
                    fatalError("Exception: SettingDetailTableViewController is expected")
                }
                
                settingRoot.delegate = settingDetailTableViewController
                masterViewNavController?.setViewControllers([settingDetailTableViewController], animated: false)
            }
        }
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
