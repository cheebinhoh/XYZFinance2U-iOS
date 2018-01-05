//
//  ExpenseTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import CoreData

// MARK: - protocol
protocol ExpenseTableViewDelegate: class {
    
    func expenseSelected(newExpense: XYZExpense?)
    func expenseDeleted(deletedExpense: XYZExpense)
}

class ExpenseTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    ExpenseDetailDelegate {
    
    // MARK: - property
    var expenseList = [XYZExpense]()
    var sectionList = [TableSectionCell]()  
    var delegate: ExpenseTableViewDelegate?
    var isPopover = false
    var isCollapsed: Bool {
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            return split.isCollapsed
        } else {
            
            return true
        }
    }
    
    // MARK: - IBAction
    @IBAction func add(_ sender: UIBarButtonItem) {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
            fatalError("Exception: ExpenseDetailTableViewController is expected" )
        }
        
        expenseDetailTableView.setPopover(delegate: self)
        isPopover = true
        
        expenseDetailNavigationController.modalPresentationStyle = .popover
        self.present(expenseDetailNavigationController, animated: true, completion: nil)
    }
    
    /* deprecated need:
    @IBAction func unwindToExpenseTableView(sender: UIStoryboardSegue)
    {
        modalEditing = false
        guard let expenseDetail = sender.source as? ExpenseDetailTableViewController, let expense = expenseDetail.expense else  
        {
            return
        }
        
        if tableView.indexPathForSelectedRow == nil
        {
            expenseList.append(expense)
        }
        
        saveManageContext()
        
        reloadData()
    }
     */
    
    //MARK: - function
    func indexPath(of expense:XYZExpense) -> IndexPath? {
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
            let sectionExpenseList = section.data as? [XYZExpense]
            for (rowIndex, cell) in (sectionExpenseList?.enumerated())! {  //(section.expenseList?.enumerated())! {
                
                if cell == expense {
                    
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    func deleteExpense(expense: XYZExpense) {
        
        if let selectedIndexPath = indexPath(of: expense) {
            
            let aContext = managedContext()
            var sectionExpenseList = sectionList[selectedIndexPath.section].data as? [XYZExpense]
            
            let oldExpense = sectionExpenseList?.remove(at: selectedIndexPath.row)
            sectionList[selectedIndexPath.section].data = sectionExpenseList
            
            guard oldExpense == expense else {
                fatalError("Exception: expense selectedd is not what is to be deleted")
            }
            
            delegate?.expenseDeleted(deletedExpense: oldExpense!)
            aContext?.delete(oldExpense!)
            saveManageContext()
            loadExpensesFromSections()
            reloadData()
        }
    }
    
    func saveExpense(expense: XYZExpense) {
        
        saveManageContext()
        reloadData()
        
        let indexPath = self.indexPath(of: expense)
        tableView.selectRow(at: indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
        delegate?.expenseSelected(newExpense: expense)
    }
    
    func saveNewExpense(expense: XYZExpense) {
        
        expenseList.append(expense)

        saveManageContext()

        reloadData()
        
        let indexPath = self.indexPath(of: expense)
        tableView.selectRow(at: indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
        delegate?.expenseSelected(newExpense: expense)
    }
    
    private func reloadData() {
        
        expenseList = sortExpenses(expenses: expenseList)
        loadExpensesIntoSections()
        tableView.reloadData()
    }
    
    private func sortExpenses(expenses: [XYZExpense]) -> [XYZExpense] {
        
        return expenses.sorted(by: { (exp1, exp2) -> Bool in
            
            let date1 = exp1.value(forKey: XYZExpense.date) as! Date
            let date2 = exp2.value(forKey: XYZExpense.date) as! Date
            
            return date1 > date2
        })
    }
    
    private func loadExpensesFromSections() {
        
        expenseList.removeAll()
        
        for section in sectionList {
            
            let sectionExpenseList = section.data as? [XYZExpense]
            for expense in sectionExpenseList! {
                
                expenseList.append(expense)
            }
        }
        
        expenseList = sortExpenses(expenses: expenseList)
    }
    
    private func loadExpensesIntoSections() {
        
        let calendar = Calendar.current
        
        // FIXME to improve performance
        sectionList = [TableSectionCell]()
        var sectionExpenseList: [XYZExpense]?
        
        for expense in expenseList {
            
            guard let date = expense.value(forKey: XYZExpense.date) as? Date else {
                continue
            }
            
            let dateFormatter = DateFormatter()
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            let yearMonth = "\(year), \(dateFormatter.shortMonthSymbols[month - 1])"

            var foundIndex = -1
            for (index, section) in sectionList.enumerated() {
                
                if section.title == yearMonth {
                    
                    foundIndex = index
                    break
                }
            }
            
            if foundIndex < 0 {
                
                if sectionList.count > 0 {
                    
                    sectionList[sectionList.count - 1].data = sectionExpenseList
                }
                
                //let newSection = SectionExpense(title: yearMonth, expenseList: [XYZExpense]())
                let newSection = TableSectionCell(identifier: yearMonth, title: yearMonth, cellList: [], data: nil)
                sectionList.append(newSection)
                foundIndex = sectionList.count - 1
                
                sectionExpenseList = [XYZExpense]()
            }
            
            sectionExpenseList?.append(expense)
        }
        
        if sectionList.count > 0 {
            
            sectionList[sectionList.count - 1].data = sectionExpenseList
        }
    }
    
    private func loadExpenses() -> [XYZExpense]? {
        
        var expenses: [XYZExpense]?
        
        let aContext = managedContext()
        let fetchRequest = NSFetchRequest<XYZExpense>(entityName: "XYZExpense")
        
        do {
            
            expenses = try aContext?.fetch(fetchRequest)
        } catch let error as NSError {
            
            print("******** Could not fetch. \(error), \(error.userInfo)")
        }
        
        let fetchRequestExpPerson = NSFetchRequest<XYZExpensePerson>(entityName: "XYZExpensePerson")
        
        do {
            
            _ = try aContext?.fetch(fetchRequestExpPerson)
        } catch let error as NSError {
            
            print("******** Could not fetch. \(error), \(error.userInfo)")
        }
        
        let fetchRequestExpReceipt = NSFetchRequest<XYZExpenseReceipt>(entityName: "XYZExpenseReceipt")
        
        do {
        
            _ = try aContext?.fetch(fetchRequestExpReceipt)
        } catch let error as NSError {
            
            print("******** Could not fetch. \(error), \(error.userInfo)")
        }
        
        return sortExpenses(expenses: expenses!)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
        
        expenseList = loadExpenses()!
        loadExpensesIntoSections()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        super.setEditing(editing, animated: animated)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionExpenseList = sectionList[section].data as? [XYZExpense]
        
        return (sectionExpenseList?.count) ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        guard let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewCell", for: indexPath) as? ExpenseTableViewCell else {
            fatalError("error on ExpenseTableViewCell cell")
        }
        
        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
        
        expenseCell.setExpense(expense: (sectionExpenseList?[indexPath.row])!)
        cell = expenseCell
        
        return cell!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Delete the row from the data source
            let aContext = managedContext()
            
            var sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
            
            let oldExpense = sectionExpenseList?.remove(at: indexPath.row)
            sectionList[indexPath.section].data = sectionExpenseList
            
            delegate?.expenseDeleted(deletedExpense: oldExpense!)
            aContext?.delete(oldExpense!)
            loadExpensesFromSections()
        } else if editingStyle == .insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            fatalError("Exception: not yet done")
        }
        
        saveManageContext()
        
        reloadData()
    }

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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sectionList[section].title
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let split = self.parent?.parent?.parent as? UISplitViewController else {
            fatalError("Exception: locate split view")
        }
        
        if split.isCollapsed {
            
            guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let expenseTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                fatalError("Exception: ExpenseDetailTableViewController is expected" )
            }
            
            expenseTableView.setPopover(delegate: self)
            let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
            
            expenseTableView.expense = sectionExpenseList?[indexPath.row]
            expenseDetailNavigationController.modalPresentationStyle = .popover
            self.present(expenseDetailNavigationController, animated: true, completion: nil)
            
            guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                fatalError("Exception: MainSplitViewController is expected")
            }
            
            mainSplitView.popOverNavigatorController = expenseDetailNavigationController
        } else {
            
            guard let detailTableViewController = delegate as? ExpenseDetailTableViewController else {
                fatalError("Exception: ExpenseDetailTableViewController is expedted" )
            }
            
            detailTableViewController.expenseDelegate = self
            
            let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
            
            delegate?.expenseSelected(newExpense: sectionExpenseList?[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 35
        } else {
            
            return 17.5
        }
    }


    // MARK: - Navigation

    /* Deprecated need:
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? ""
        {
        case "ShowExpenseDetail":
            guard let expenseDetailView = segue.destination as? ExpenseDetailTableViewController else
            {
                fatalError("Exception: Unexpected error on casting segue.destination to ExpenseDetailTableViewController")
            }
            
            if let accountDetail = sender as? ExpenseTableViewCell
            {
                guard let indexPath = tableView.indexPath(for: accountDetail) else
                {
                    fatalError("Unexpeted error in getting indexPath for prepare from table view controller");
                }
                
                expenseDetailView.expense = sectionList[indexPath.section].expenseList?[indexPath.row]
            }
            
            if let _ = expenseDetailView.expense
            {
                expenseDetailView.navigationItem.title = ""
            }
            else
            {
                expenseDetailView.navigationItem.title = "New"
            }
            
            modalEditing = true
            
        default:
            fatalError("Unexpected error on default for prepare from table view controller")
        }
    }
     */
 
    // MARK: - splitview delegate
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseDetailTableViewController = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
            fatalError("Exception: ExpenseDetailTableViewController is expected")
        }
        
        expenseDetailTableViewController.navigationItem.title = ""
        self.delegate = expenseDetailTableViewController
        
        return expenseDetailNavigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        self.delegate = nil
        secondaryViewController.navigationItem.title = "New"
        
        for expense in expenseList {
            
            let indexPath = self.indexPath(of: expense)
            tableView.deselectRow(at: indexPath!, animated: false)
        }
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let expenseDetailTableViewController = navigationController.viewControllers.first as? ExpenseDetailTableViewController {
                
                expenseDetailTableViewController.expenseDelegate = self
                expenseDetailTableViewController.isPushinto = true
                
                if !isPopover && expenseDetailTableViewController.modalEditing {
                    
                    expenseDetailTableViewController.isPushinto = false
                    expenseDetailTableViewController.isPopover = true
                    navigationController.modalPresentationStyle = .popover

                    guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                        fatalError("Exception: MainSplitViewController is expected")
                    }
                    
                    mainSplitView.popOverNavigatorController = navigationController
                    
                    OperationQueue.main.addOperation {
                        
                       self.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        isPopover = false
        
        return true
    }
    
    /* Deprecated need: we do not need to prevent landscape mode as we use PopOver view for adding Expense
    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask
    {
        return modalEditing ? UIInterfaceOrientationMask.portrait : UIInterfaceOrientationMask.all
    }
     */
    
}
