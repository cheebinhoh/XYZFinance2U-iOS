//
//  BudgetExpensesTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/25/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

protocol BudgetExpenseDelegate: class {
    
    func deleteExpense(expense: XYZExpense)
}

class BudgetExpensesTableViewController: UITableViewController {

    var expenseList: [XYZExpense]?
    var sectionList = [TableSectionCell]()
    var delegate: BudgetExpenseDelegate?
    
    func loadDataIntoTableSectionCell() {
        
        sectionList = [TableSectionCell]()
        
        if let _ = expenseList, !(expenseList?.isEmpty)! {
            
            let expenseSection = TableSectionCell(identifier: "expense", title: "", cellList: [], data: expenseList)
            sectionList.append(expenseSection)
        }
    }
    
    func loadData() {
    
        loadDataIntoTableSectionCell()
        tableView.reloadData()
    }
    
    func loadData(of expenseList:[XYZExpense]?) {
        
        self.expenseList = expenseList
        loadData()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
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
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let sectionExpeneseList = sectionList[section].data as? [XYZExpense]
        
        return (sectionExpeneseList?.count)!
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewCell", for: indexPath) as? ExpenseTableViewCell else {
            
            fatalError("Exception: expenseTableViewCell is expected" )
        }
        
        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
        let expense = sectionExpenseList![indexPath.row]
        
        cell.setExpense(expense: expense)
        // Configure the cell...

        return cell
    }

    func softDeleteExpense(expense: XYZExpense) -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool ?? false
        
        if isShared {
            
            expense.setValue(true, forKey: XYZExpense.isSoftDelete)
            expense.setValue(Date(), forKey: XYZExpense.lastRecordChange)
        }
        
        if !((appDelegate?.iCloudZones.isEmpty)!) {
            
            if isShared {
                
            } else {
                
                guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
                    
                    fatalError("Exception: iCloudZoen is expected")
                }
                
                guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
                    
                    fatalError("Exception: data is expected for deleteRecordIdList")
                }
                
                guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }
                
                let recordName = expense.value(forKey: XYZExpense.recordId) as? String
                deleteRecordLiset.append(recordName!)
                
                let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
                zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
                
                guard let shareRecordNameData = zone.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data else {
                    
                    fatalError("Exception: data is expected for deleteRecordIdList")
                }
                
                guard var deleteShareRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: shareRecordNameData) as? [String]) else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }
                
                if let shareRecordName = expense.value(forKey: XYZExpense.shareRecordId) as? String {
                    
                    deleteShareRecordLiset.append(shareRecordName)
                    
                    let savedDeleteShareRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordLiset )
                    zone.setValue(savedDeleteShareRecordLiset, forKey: XYZiCloudZone.deleteShareRecordIdList)
                }
            }
        }
        
        return isShared // if it is shared, then we softdelete it by keeping
    }
    
    func updateToiCloud(_ expense: XYZExpense?) {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let iCloudZone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!)
        iCloudZone?.data = appDelegate?.expenseList
        
        if let _ = iCloudZone {
            
            fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                                 [ckrecordzone],
                                 [iCloudZone!], {
                                    
                                
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 35
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let stackView = UIStackView()
        let title = UILabel()
        let subtotal = UILabel()
        var total = 0.0
        var currencyCode = Locale.current.currencyCode
        let sectionExpenseList = sectionList[section].data as? [XYZExpense]
        
        for expense in sectionExpenseList! {
            
            let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
            total = total + amount
            
            currencyCode = expense.value(forKey: XYZExpense.currencyCode) as? String
        }
        
        //let (amount, currencyCode) = sectionTotal(section)
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 10)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = "Total"
        title.textColor = UIColor.gray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
        if let currencyCode = currencyCode {
            
            subtotal.text = formattingCurrencyValue(input: total, code: currencyCode)
            subtotal.textColor = UIColor.gray
            stackView.addArrangedSubview(subtotal)
        }
        
        return stackView
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, handler in
            
            let aContext = managedContext()
            
            var sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
            
            let oldExpense = sectionExpenseList?.remove(at: indexPath.row)
            self.sectionList[indexPath.section].data = sectionExpenseList
            self.expenseList = sectionExpenseList
            
            let isSoftDelete = self.softDeleteExpense(expense: oldExpense!)
            
            saveManageContext()
            
            if isSoftDelete {
                
                self.updateToiCloud(oldExpense!)
            } else {
                
                aContext?.delete(oldExpense!)

                
                self.updateToiCloud(nil)
            }
            
            self.loadData()
            
            self.delegate?.deleteExpense(expense: oldExpense!)

            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            appDelegate?.expenseList = loadExpenses()!
            
            guard let splitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            guard let tabbarView = splitView.viewControllers.first as? MainUITabBarController else {
                
                fatalError("Exception: MainUITabBarController is expected")
            }
            
            guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
                
                fatalError("Exception: UINavigationController is expected")
            }
            
            guard let expenseView = expenseNavController.viewControllers.first as? ExpenseTableViewController else {
                
                fatalError("Exception: ExpenseTableViewController is expected")
            }

            expenseView.reloadData()
            
            guard let budgetNavController = tabbarView.viewControllers?[2] as? UINavigationController else {
                
                fatalError("Exception: UINavigationController is expected")
            }
            
            guard let budgetView = budgetNavController.viewControllers.first as? BudgetTableViewController else {
                
                fatalError("Exception: BudgetTableViewController is expected")
            }
            
            budgetView.reloadData()
            
            handler(true)
        }
        
        commands.append(delete)
        
        return UISwipeActionsConfiguration(actions: commands)
    }

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
