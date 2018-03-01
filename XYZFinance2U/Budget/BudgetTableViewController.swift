//
//  BudgetTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit
import CloudKit

protocol BudgetSelectionDelegate: class {
    
    func budgetSelected(newBudget: XYZBudget?)
    func budgetDeleted(deletedBudget: XYZBudget)
}

class BudgetTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    ExpenseDetailDelegate,
    BudgetDetailDelegate {
    
    func cancelExpense() {

    }
    
    
    func saveNewExpense(expense: XYZExpense) {

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList.append(expense)
        
        saveManageContext()

        guard let splitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: MainSplitViewController is expected")
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
        
        expenseView.updateToiCloud(expense)
        expenseView.reloadData()
        reloadData()
    }
    
    func saveExpense(expense: XYZExpense) {
        fatalError("Exception: it is not supposed to be here")
    }
    
    func deleteExpense(expense: XYZExpense) {
        fatalError("Exception: it is not supposed to be here")
    }
    
    
    // MARK: budget detail protocol
    func saveNewBudget(budget: XYZBudget) {

        if let currencyCode = budget.value(forKey: XYZBudget.currency) as? String, currencyCodes.contains(currencyCode) {
         
            for (sectionIndex, section) in sectionList.enumerated() {
                
                if section.identifier == currencyCode {
                    
                    let setionBudgetList = section.data as? [XYZBudget]
                    
                    budget.setValue((setionBudgetList?.count)! + sectionIndex * 1000, forKey: XYZBudget.sequenceNr)
                    
                    break
                }
            }
        }
        
        saveManageContext()

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        var budgetList = (appDelegate?.budgetList)!
        budgetList.append(budget)
        appDelegate?.budgetList = budgetList
        
        reloadData()
        
        saveBudgets()
    }
    
    func saveBudget(budget: XYZBudget) {
        
        saveManageContext()
        
        reloadData()
        
        saveBudgets()
    }
    
    func deleteBudget(budget: XYZBudget) {

        let oldBudget = softdeletebudget(budget)
        
        self.delegate?.budgetDeleted(deletedBudget: oldBudget)
        reloadData()
    }
    
    // MARK: - property
    var isPopover = false
    var sectionList = [TableSectionCell]()
    var currencyCodes = [String]()
    var delegate: BudgetSelectionDelegate?
    
    @IBAction func add(_ sender: UIBarButtonItem) {
    
        guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "BudgetDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating BudgetDetailNavigationController")
        }
        
        guard let budgetDetailTableView = budgetDetailNavigationController.viewControllers.first as? BudgetDetailTableViewController else {
            
            fatalError("Exception: eror on casting first view controller to IncomeDetailTableViewController" )
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        mainSplitView.popOverNavigatorController = budgetDetailNavigationController
        
        budgetDetailTableView.currencyCodes = currencyCodes
        
        budgetDetailTableView.setPopover(delegate: self)
        isPopover = true
        budgetDetailNavigationController.modalPresentationStyle = .popover
        
        self.present(budgetDetailNavigationController, animated: true, completion: nil)
    }
    
    func loadBudgetsIntoSection() {
        
        sectionList = [TableSectionCell]()
        currencyCodes = [String]()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let budgetList = (appDelegate?.budgetList)!
        
        for budget in budgetList {
            
            let currency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
            
            if !currencyCodes.contains(currency!) {
            
                currencyCodes.append(currency!)
            }
        }
        
        for currency in currencyCodes {
        
            var sectionBudgetList = [XYZBudget]()
            
            for budget in budgetList {
                
                let budgetCurrency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
                
                if budgetCurrency == currency {
                    
                    sectionBudgetList.append(budget)
                }
            }
            
            sectionBudgetList.sort(by: { (bu1, bu2) -> Bool in
                
                let seq1 = bu1.value(forKey: XYZBudget.sequenceNr) as? Int
                let seq2 = bu2.value(forKey: XYZBudget.sequenceNr) as? Int
                
                return seq1! < seq2!
            })
            
            let newSection = TableSectionCell(identifier: currency, title: currency, cellList: [], data: sectionBudgetList)
            sectionList.append(newSection)
        }
        
        sectionList = sectionList.sorted(by: { (section1, section2) -> Bool in
            
            section1.identifier < section2.identifier
        })
    }
    
    func loadData() {
        
        loadBudgetsIntoSection()
    }
    
    func reloadData() {
        
        loadData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        navigationItem.leftBarButtonItem = self.editButtonItem
        
        loadData()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sectionTotal(section: Int) -> (Double, String) {
        
        var total = 0.0;
        let sectionBudgetList = sectionList[section].data as? [XYZBudget]
        
        for budget in sectionBudgetList! {
            
            total = total + ((budget.value(forKey: XYZBudget.amount) as? Double) ?? 0.0 )
        }
        
        return (total, sectionList[section].title!)
    }
    
    func getExpenseList(of budget: XYZBudget, from expenseList: [XYZExpense]) -> [XYZExpense] {
     
        var outputExpenseList = [XYZExpense]()
        let name = budget.value(forKey: XYZBudget.name) as? String ?? ""
        
        for expense in expenseList {
            
            let category = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
            let isSoftDelete = expense.value(forKey: XYZExpense.isSoftDelete) as? Bool ?? false
            
            if isSoftDelete {
                
                continue
            }
            
            if category.lowercased() == name.lowercased() {
         
                outputExpenseList.append(expense)
            }
        }
        
        return outputExpenseList
    }
    
    func getTotalSpendAmount(of budget: XYZBudget, from expenseList: [XYZExpense]) -> Double {
        
        var total = 0.0
        let name = budget.value(forKey: XYZBudget.name) as? String ?? ""
        let currentStart = budget.currentStart
        let currentEnd = budget.currentEnd
        
        for expense in expenseList {
        
            let category = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
            let isSoftDelete = expense.value(forKey: XYZExpense.isSoftDelete) as? Bool ?? false
            
            if isSoftDelete {
                
                continue
            }
            
            if category.lowercased() == name.lowercased() {
                
                let date = expense.value(forKey: XYZExpense.date) as? Date
                if currentStart == nil
                   || currentEnd == nil
                    || (date! >= currentStart! && date! < currentEnd! ) {
                
                    let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
                    
                    total = total + amount
                }
            }
        }
        
        return total
    }

    private func saveBudgets() {
        
        /* we do 3 things:
         * - if there is a any record that its LastRecordChange is greater than LastRecordUpload, then we upload it to icloud
         * - if the upload is success:
         *      - then we tagged lastRecordUpload and lastRecordFetch
         * - if the uploda is failed:
         *      - if conflict:
         *          - we will overwrite existing record with new record from icloud (which should overwrite all 3 timestamp:
         *            lastRecordChange, lastRecordUpload and lastRecordFetch
         *          - we then display alertpanel to user to notify that change failed
         *      - if other error:
         *          - then we will keep existing changed record and try to upload it again at different time.
         *
         */
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let ckrecordzone = CKRecordZone(zoneName: XYZBudget.type)
        let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.privateiCloudZones)!)
        zone?.data = appDelegate?.budgetList
        
        fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone], (appDelegate?.privateiCloudZones)!, {
                                
        })
    }
    
    func delete(of indexPath:IndexPath) {

        var sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
        
        let oldBudget = sectionBudgetList?.remove(at: indexPath.row)
        self.sectionList[indexPath.section].data = sectionBudgetList
        
        softdeletebudget(oldBudget!)
        
        saveManageContext()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let new = UIContextualAction(style: .normal, title: "Add Expense" ) { _, _, handler in
            
            guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                
                fatalError("Exception: ExpenseDetailTableViewController is expected" )
            }
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = expenseDetailNavigationController
            
            let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            let currrency = budget.value(forKey: XYZBudget.currency) as? String
            let budgetGroup = budget.value(forKey: XYZBudget.name) as? String
            
            expenseDetailTableView.presetBudgetCategory = budgetGroup
            expenseDetailTableView.presetCurrencyCode = currrency
            expenseDetailTableView.setPopover(delegate: self)
            //expenseDetailTableView.currencyCodes = currencyCodes
            self.isPopover = true
            
            expenseDetailNavigationController.modalPresentationStyle = .popover
            handler(true)
            self.present(expenseDetailNavigationController, animated: true, completion: nil)
        }
        
        new.backgroundColor = UIColor.blue
        commands.append(new)
        
        let more = UIContextualAction(style: .normal, title: "More" ) { _, _, handler in
            
            guard let calendarViewNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "CalendarViewNavigationController") as? UINavigationController else {
                
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let calendarCollectionViewController = calendarViewNavigationController.viewControllers.first as? CalendarCollectionViewController else {
                
                fatalError("Exception: CalendarCollectionViewController is expected" )
            }
            
            let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            //let startDate = budget.currentStart ?? Date()
        
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.orientation = UIInterfaceOrientationMask.portrait
            
            let expeneseList = self.getExpenseList(of: budget, from: (appDelegate?.expenseList)!)
            calendarCollectionViewController.expenseList = expeneseList
            calendarCollectionViewController.budgetGroup = budget.value(forKey: XYZBudget.name) as? String ?? ""
            calendarCollectionViewController.setDate(Date())
            calendarCollectionViewController.budget = budget
            
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = calendarViewNavigationController
            
            handler(true)
            self.present(calendarViewNavigationController, animated: true, completion: {})
        }
        
        commands.append(more)
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
            
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, handler in
            
            // Delete the row from the data source
            let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            
            self.softdeletebudget(budget)
            
            self.reloadData()
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if (appDelegate?.budgetList.isEmpty)! {
                
                self.setEditing(false, animated: true)
                self.tableView.setEditing(false, animated: false)
            }
            
            handler(true)
        }
        
        commands.append(delete)
    
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        super.setEditing(editing, animated: animated)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        if mainSplitView.isCollapsed  {
            
            guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "BudgetDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating BudgetDetailNavigationController")
            }
            
            guard let budgetDetailTableViewController = budgetDetailNavigationController.viewControllers.first as? BudgetDetailTableViewController else {
                
                fatalError("Exception: BudgetDetailTableViewController is expected")
            }

            budgetDetailTableViewController.setPopover(delegate: self)
            
            let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
            
            budgetDetailTableViewController.budget = sectionBudgetList?[indexPath.row]
            budgetDetailTableViewController.currencyCodes = currencyCodes
            isPopover = true
            budgetDetailNavigationController.modalPresentationStyle = .popover
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = budgetDetailNavigationController
            
            self.present(budgetDetailNavigationController, animated: true, completion: nil)
        } else {
            
            guard let detailTableViewController = delegate as? BudgetDetailTableViewController else {
                
                fatalError("Exception: BudgetDetailTableViewController is expedted" )
            }
            
            let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
            detailTableViewController.budgetDelegate = self
            detailTableViewController.currencyCodes = currencyCodes
            delegate?.budgetSelected(newBudget: sectionBudgetList?[indexPath.row])
        }
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionBudgetList = sectionList[section].data as? [XYZBudget]
        
        return (sectionBudgetList?.count)!
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let stackView = UIStackView()
        let title = UILabel()
        let subtotal = UILabel()
        let (amount, currency) = sectionTotal(section: section)
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 45)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = sectionList[section].title
        title.textColor = UIColor.gray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
        subtotal.text = formattingCurrencyValue(input: amount, code: currency)
        subtotal.textColor = UIColor.gray
        stackView.addArrangedSubview(subtotal)
        
        return stackView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 35
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "budgetTableCell", for: indexPath) as? BudgetTableViewCell else {
            
            fatalError("Exception: BudgetTableViewCell is expected")
        }

        let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
        let budget = sectionBudgetList![indexPath.row]
        let name = budget.value(forKey: XYZBudget.name) as? String
        let amount = budget.value(forKey: XYZBudget.amount) as? Double
        let currency = budget.value(forKey: XYZBudget.currency) as? String
        let length = budget.value(forKey: XYZBudget.length) as? String
        var period = ""
        
        if length == XYZBudget.Length.none.rawValue {
            
            period = "-"
        } else {
            
            let start = formattingDate(date: budget.currentStart!, style: .short) //budget.currentStart
            period = "\(length!), from: \(start)"
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let spendAmount = getTotalSpendAmount(of: budget, from: (appDelegate?.expenseList)!)
        cell.spendAmount.text = formattingCurrencyValue(input: spendAmount, code: currency!)
        cell.amount.text = formattingCurrencyValue(input: amount!, code: currency!)
        cell.name.text = name
        cell.length.text = period
        var color = UIColor.black
        if spendAmount > amount! {
            
            color = UIColor.red
        } else if spendAmount == amount {
            
            color = UIColor.black
        } else {
            
            color = UIColor.black
        }
        
        cell.spendAmount.textColor = color
        
        return cell
    }

    func indexPath(_ budget2Find: XYZBudget) -> IndexPath? {
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
            let sectionBudgetList = section.data as? [XYZBudget]
            
            for (rowIndex, budget) in (sectionBudgetList?.enumerated())! {
                
                if budget == budget2Find {
                    
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }
    
    func loadBudgetsFromSection() -> [XYZBudget] {
        
        var budgetList = [XYZBudget]()
        
        for section in sectionList {
            
            let sectionBudgetList = section.data as? [XYZBudget]
            
            for budget in sectionBudgetList! {
                
                budgetList.append(budget)
            }
        }
        
        return budgetList
    }
    
    @discardableResult
    func softdeletebudget(_ budget: XYZBudget) -> XYZBudget {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZBudget.type)
        
        if !(appDelegate?.iCloudZones.isEmpty)! {
            
            guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
                
                fatalError("Exception: iCloudZoen is expected")
            }
            
            guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
                
                fatalError("Exception: data is expected for deleteRecordIdList")
            }
            
            guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
                
                fatalError("Exception: deleteRecordList is expected as [String]")
            }
            
            let recordName = budget.value(forKey: XYZBudget.recordId) as? String
            deleteRecordLiset.append(recordName!)
            
            let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
            zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
        }
        
        let indexPath = self.indexPath(budget)
        var sectionBudgetList = sectionList[(indexPath?.section)!].data as? [XYZBudget]
        
        let oldBudget = sectionBudgetList?.remove(at: (indexPath?.row)!)
        sectionList[(indexPath?.section)!].data = sectionBudgetList
        
        appDelegate?.budgetList = loadBudgetsFromSection()
        
        let aContext = managedContext()
        aContext?.delete(budget)
        
        saveManageContext()
        
        saveBudgets()
        
        return oldBudget!
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            
            softdeletebudget(budget)
        
            reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
      
        if fromIndexPath.row != to.row {
            
            var sectionBudgetList = sectionList[fromIndexPath.section].data as! [XYZBudget]

            sectionBudgetList.insert(sectionBudgetList.remove(at: fromIndexPath.row), at: to.row)

            for (index, budget) in sectionBudgetList.enumerated() {
                
                budget.setValue(index + to.section * 1000, forKey: XYZBudget.sequenceNr)
                budget.setValue(Date(), forKey: XYZBudget.lastRecordChange)
            }
            
            sectionList[fromIndexPath.section].data = sectionBudgetList
            
            saveManageContext()
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let ckrecordzone = CKRecordZone(zoneName: XYZBudget.type)
            let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.privateiCloudZones)!)
            zone?.data = appDelegate?.budgetList
            
            fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                                 [ckrecordzone], (appDelegate?.privateiCloudZones)!, {
                                    
            })
        }
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {

        return true
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var indexPath = proposedDestinationIndexPath
        
        if ( sourceIndexPath.section != proposedDestinationIndexPath.section ) {
            
            indexPath = sourceIndexPath
        }
        
        return indexPath
    }
    
    // MARK: - split view delegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for row in 0..<(appDelegate?.budgetList)!.count {
            
            let indexPath = IndexPath(row: row, section: 0)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        self.delegate = nil
        secondaryViewController.navigationItem.title = "New" //TODO: check if we need this
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let budgetDetailTableViewController = navigationController.viewControllers.first as? BudgetDetailTableViewController {
                
                budgetDetailTableViewController.budgetDelegate = self
                budgetDetailTableViewController.isPushinto = true
                
                if !isPopover && budgetDetailTableViewController.modalEditing {
                    
                    budgetDetailTableViewController.isPushinto = false
                    budgetDetailTableViewController.isPopover = true
                    navigationController.modalPresentationStyle = .popover
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                        
                        fatalError("Exception: UISplitViewController is expected" )
                    }
                    
                    mainSplitView.popOverNavigatorController = navigationController
                    
                    //OperationQueue.main.addOperation
                    DispatchQueue.main.async {
                        
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
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "BudgetDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating BudgetDetailNavigationController")
        }
        
        guard let budgetDetailTableViewController = budgetDetailNavigationController.viewControllers.first as? BudgetDetailTableViewController else {
            
            fatalError("Exception: BudgetDetailTableViewController is expected")
        }
        
        budgetDetailNavigationController.navigationItem.title = ""
        self.delegate = budgetDetailTableViewController
        
        return budgetDetailNavigationController
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        
        return nil
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
