//
//  BudgetTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class BudgetTableViewController: UITableViewController {

    var sectionList = [TableSectionCell]()
    var currencyCodes = [String]()
    
    func loadBudgetsIntoSection() {
        
        sectionList = [TableSectionCell]()
        currencyCodes = [String]()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let budgetList = (appDelegate?.budgetList)!
        
        for budget in budgetList {
            
            let currency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
            
            if !currencyCodes.contains(currency!) {
                
                let newSection = TableSectionCell(identifier: currency!, title: currency, cellList: [], data: [XYZBudget]())
                sectionList.append(newSection)
                
                currencyCodes.append(currency!)
            }
            
            var sectionBudgetList = sectionList[sectionList.count - 1].data as? [XYZBudget]
            sectionBudgetList?.append(budget)
            sectionList[sectionList.count - 1].data = sectionBudgetList
        }
        
        // debug
        print("-------- # of sections = \(sectionList.count)")
        for section in sectionList {
            
            let currency = section.title
            let sectionBudgetList = section.data as? [XYZBudget]
            
            print("-------- section = \(String(describing: currency))")
            for budget in sectionBudgetList! {
            
                let name = budget.value(forKey: XYZBudget.name)
                let amount = budget.value(forKey: XYZBudget.amount)
                let start = budget.value(forKey: XYZBudget.start)
                let length = XYZBudget.Length(rawValue: budget.value(forKey: XYZBudget.length) as? String ?? "")
                
                
                print("-------- name = \(String(describing: name)), amount = \(String(describing: amount)), length = \(String(describing: length)), start = \(String(describing: start))")
            }
        }
        
        /*
        else {
            
            _ = XYZBudget(id: nil, name: "grocery", amount: 600.0, currency: Locale.current.currencyCode!, length: .monthly, start: Date(),  context: managedContext())
            
            _ = XYZBudget(id: nil, name: "xfinity", amount: 120.0, currency: Locale.current.currencyCode!, length: .monthly, start: Date(), context: managedContext())
            
            _ = XYZBudget(id: nil, name: "insurance", amount: 1500.0, currency: "MYR", length: .monthly, start: Date(), context: managedContext())
        
            saveManageContext()
        } */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        navigationItem.leftBarButtonItem = self.editButtonItem
        
        loadBudgetsIntoSection()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
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
