//
//  XYZMainUITabBarController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/19/17.
//  Copyright © 2017 - 2019 CB Hoh. All rights reserved.

import UIKit

class XYZMainUITabBarController: UITabBarController,
    UITabBarControllerDelegate {

    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.delegate = self

        guard let split = self.parent as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected")
        }
        
        guard let navController = self.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        if let incomeRoot = navController.viewControllers.first as? XYZIncomeTableViewController {
            
            split.delegate = incomeRoot
        } else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected")
        }
        
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
        
        var masterViewNavController: UINavigationController?
        
        guard let split = self.parent as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected")
        }

        if !split.isCollapsed && split.viewControllers.count > 1 {
            
            masterViewNavController = split.viewControllers.last as? UINavigationController
            
            guard nil != masterViewNavController else {
                
                fatalError("Exception: UINavigationController is expected")
            }
        }
        
        guard let navController = viewController as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        if let incomeRoot = navController.viewControllers.first as? XYZIncomeTableViewController {
            
            split.delegate = incomeRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? XYZIncomeDetailTableViewController {
                
                // empty
            } else {
                
                guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "incomeDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: error on instantiating IncomeDetailNavigationController")
                }
                
                guard let incomeDetailTableViewController = incomeDetailNavigationController.viewControllers.first as? XYZIncomeDetailTableViewController else {
                    
                    fatalError("Exception: XYZIncomeDetailTableViewController is expected")
                }
                
                incomeDetailTableViewController.navigationItem.title = ""
                incomeRoot.delegate = incomeDetailTableViewController

                masterViewNavController?.setViewControllers([incomeDetailTableViewController], animated: false)
            }
        } else if let expenseRoot = navController.viewControllers.first as? XYZExpenseTableViewController  {
            
            split.delegate = expenseRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? XYZExpenseDetailTableViewController {
                
                // empty
            } else {
                
                guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: error on instantiating ExpenseDetailNavigationController")
                }
                
                guard let expenseDetailTableViewController = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
                    
                    fatalError("Exception: XYZExpenseDetailTableViewController is expected")
                }
                
                expenseDetailTableViewController.navigationItem.title = ""
                expenseRoot.delegate = expenseDetailTableViewController

                masterViewNavController?.setViewControllers([expenseDetailTableViewController], animated: false)
            }
        } else if let budgetRoot = navController.viewControllers.first as? XYZBudgetTableViewController {
            
            split.delegate = budgetRoot
            
            budgetRoot.reloadData()
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? XYZBudgetDetailTableViewController {
                
                // empty
            } else {
                
                guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "budgetDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: error on instantiating budgetDetailNavigationController")
                }
                
                guard let budgetDetailTableViewController = budgetDetailNavigationController.viewControllers.first as? XYZBudgetDetailTableViewController else {
                    
                    fatalError("Exception: XYZBudgetDetailTableViewController is expected")
                }
                
                budgetDetailTableViewController.navigationItem.title = ""
                budgetRoot.delegate = budgetDetailTableViewController
                
                masterViewNavController?.setViewControllers([budgetDetailTableViewController], animated: false)
            }
        } else if let settingRoot = navController.viewControllers.first as? XYZSettingTableViewController {
            
            split.delegate = settingRoot
            
            if nil == masterViewNavController {
                
                // empty
            } else if let _ = masterViewNavController?.viewControllers.last as? XYZSettingDetailTableViewController {
                
                // empty
            } else {
                
                guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "settingDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: error on instantiating settingDetailNavigationController")
                }
                
                guard let settingDetailTableViewController = settingDetailNavigationController.viewControllers.first as? XYZSettingDetailTableViewController else {
                    
                    fatalError("Exception: XYZSettingDetailTableViewController is expected")
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
