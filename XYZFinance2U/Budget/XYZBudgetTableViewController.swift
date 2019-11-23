//
//  XYZBudgetTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit
import CloudKit

protocol XYZBudgetSelectionDelegate: class {
    
    func budgetSelected(budget: XYZBudget?)
    func budgetDeleted(budget: XYZBudget)
}

class XYZBudgetTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    XYZTableViewReloadData,
    XYZExpenseDetailDelegate,
    XYZBudgetDetailDelegate {
    
    func cancelExpense() {

    }
    
    func saveNewExpense(expense: XYZExpense) {

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList.append(expense)

        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected")
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
            
            fatalError("Exception: XYZExpenseTableViewController is expected")
        }
        
        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
         
            expenseView.deleteExpenseWithoutUndo(expense: expense)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            appDelegate?.expenseList = loadExpenses()!
            expenseView.reloadData()
            self.reloadData()
        })
        
        saveManageContext()

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
    func saveNewBudgetWithoutUndo(budget: XYZBudget) {
        
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
        
        let ip = indexPath(budget)
        tableView.scrollToRow(at: ip!, at: UITableView.ScrollPosition.top, animated: true)
    }
    
    func saveNewBudget(budget: XYZBudget) {

        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
            
            self.deleteBudgetWithoutUndo(budget: budget)
        })
        
        saveNewBudgetWithoutUndo(budget: budget)
    }
    
    func saveBudget(budget: XYZBudget) {
        
        saveManageContext()
        
        reloadData()
        
        saveBudgets()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected")
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
            
            fatalError("Exception: XYZExpenseTableViewController is expected")
        }
        
        expenseView.reloadData()
    }
    
    func deleteBudgetWithoutUndo(budget: XYZBudget) {
    
        let oldBudget = softdeletebudget(budget)
        
        self.delegate?.budgetDeleted(budget: oldBudget)
        reloadData()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected")
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
            
            fatalError("Exception: XYZExpenseTableViewController is expected")
        }
        
        expenseView.reloadData()
    }
    
    func registerDeleteUndo(budget: XYZBudget) {
        
        let oldName = budget.value(forKey: XYZBudget.name) as? String ?? ""
        let oldAmount = budget.value(forKey: XYZBudget.amount) as? Double ?? 0.0
        let oldCurrency = budget.value(forKey: XYZBudget.currency) as? String ?? ""
        let oldStart = budget.value(forKey: XYZBudget.start) as? Date ?? Date()
        let oldLength = XYZBudget.Length(rawValue: budget.value(forKey: XYZBudget.length) as?
                                                    String ?? XYZBudget.Length.none.rawValue)
        let oldColor = budget.value(forKey: XYZBudget.color)
        let oldHistoricalAmount = budget.value(forKey: XYZBudget.historicalAmount)
        let oldHistoricalStart = budget.value(forKey: XYZBudget.historicalStart)
        let oldHistoricalLength = budget.value(forKey: XYZBudget.historicalLength)
        let oldIconName = budget.value(forKey: XYZBudget.iconName)
        let oldSequenceNr = budget.value(forKey: XYZBudget.sequenceNr) as? Int ?? 0
        
        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
            
            let budget = XYZBudget(id: nil,
                                   name: oldName,
                                   amount: oldAmount,
                                   currency: oldCurrency,
                                   length: oldLength!,
                                   start: oldStart,
                                   sequenceNr: oldSequenceNr,
                                   context: managedContext())
            
            budget.setValue(oldColor, forKey: XYZBudget.color)
            budget.setValue(oldHistoricalAmount, forKey: XYZBudget.historicalAmount)
            budget.setValue(oldHistoricalStart, forKey: XYZBudget.historicalStart)
            budget.setValue(oldHistoricalLength, forKey: XYZBudget.historicalLength)
            budget.setValue(oldIconName, forKey: XYZBudget.iconName)
            budget.setValue(Date(), forKey: XYZBudget.lastRecordChange)
            
            self.saveNewBudgetWithoutUndo(budget: budget)
        })
    }
    
    func deleteBudget(budget: XYZBudget) {

        registerDeleteUndo(budget: budget)
        deleteBudgetWithoutUndo(budget: budget)
    }
    
    // MARK: - property
    var isPopover = false
    var sectionList = [TableSectionCell]()
    var currencyCodes = [String]()
    var delegate: XYZBudgetSelectionDelegate?
    
    @IBAction func add(_ sender: UIBarButtonItem) {
    
        guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "budgetDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating budgetDetailNavigationController")
        }
        
        guard let budgetDetailTableView = budgetDetailNavigationController.viewControllers.first as? XYZBudgetDetailTableViewController else {
            
            fatalError("Exception: eror on casting first view controller to XYZBudgetDetailTableViewController" )
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
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
        var budgetLengths = [XYZBudget.Length]()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let budgetList = (appDelegate?.budgetList)!
        
        for budget in budgetList {
            
            let currency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
            
            if !currencyCodes.contains(currency!) {
            
                currencyCodes.append(currency!)
            }
        }
        
        for budget in budgetList {
            
            let length = XYZBudget.Length(rawValue: budget.value(forKey: XYZBudget.length) as? String ?? XYZBudget.Length.none.rawValue)
            
            if !budgetLengths.contains(length!) {
                
                budgetLengths.append(length!)
            }
        }
        
        currencyCodes = currencyCodes.sorted(by: { (cur1, cur2) -> Bool in
        
            return cur1 < cur2
        })
        
        budgetLengths = budgetLengths.sorted(by: { (len1, len2) -> Bool in
            
            return len1.index() < len2.index()
        })
        
        for currency in currencyCodes {
        
            for length in budgetLengths {
                
                var sectionBudgetList = [XYZBudget]()
                
                for budget in budgetList {
                    
                    let budgetCurrency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
                    
                    if budgetCurrency == currency {
                        
                        let budgetLength = XYZBudget.Length(rawValue: budget.value(forKey: XYZBudget.length) as? String ?? XYZBudget.Length.none.rawValue)
                        
                        if budgetLength == length {
                            
                            sectionBudgetList.append(budget)
                        }
                    }
                }
                
                sectionBudgetList.sort(by: { (bu1, bu2) -> Bool in
                    
                    let seq1 = bu1.value(forKey: XYZBudget.sequenceNr) as? Int
                    let seq2 = bu2.value(forKey: XYZBudget.sequenceNr) as? Int
                    
                    return seq1! < seq2!
                })
                
                if !sectionBudgetList.isEmpty {
                    
                    let title = ( length == XYZBudget.Length.none ) ? "\(currency)" : "\(currency) \(length.rawValue.localized())"
                    let sortedSectionBudgetList = sectionBudgetList.sorted { (bud1, bud2) -> Bool in
                    
                        let seqNr1 = bud1.value(forKey: XYZBudget.sequenceNr) as? Int ?? 0
                        let seqNr2 = bud2.value(forKey: XYZBudget.sequenceNr) as? Int ?? 0
                        
                        return seqNr1 <= seqNr2
                    }
                    
                    let newSection = TableSectionCell(identifier: currency,
                                                      title: title, cellList: [], data: sortedSectionBudgetList)
                    sectionList.append(newSection)
                }
            }
        }
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
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Retrieve latest update from iCloud".localized())
        refreshControl.addTarget(self, action: #selector(refreshUpdateFromiCloud), for: .valueChanged)
        
        // this is the replacement of implementing: "collectionView.addSubview(refreshControl)"
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshUpdateFromiCloud(refreshControl: UIRefreshControl) {
        
        var zonesToBeFetched = [CKRecordZone]()
        let incomeCustomZone = CKRecordZone(zoneName: XYZBudget.type)
        
        zonesToBeFetched.append(incomeCustomZone)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let icloudZones = appDelegate?.privateiCloudZones.filter({ (icloudZone) -> Bool in
            
            let name = icloudZone.value(forKey: XYZiCloudZone.name) as? String ?? ""
            
            return name == XYZBudget.type
        })
        
        fetchiCloudZoneChange(CKContainer.default().privateCloudDatabase, zonesToBeFetched, icloudZones!, {
            
            for (_, icloudzone) in (icloudZones?.enumerated())! {
                
                let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String
                
                switch zName! {
                    case XYZBudget.type:
                        appDelegate?.budgetList = (icloudzone.data as? [XYZBudget])!
                        appDelegate?.budgetList = sortBudgets((appDelegate?.budgetList)!)

                        DispatchQueue.main.async {

                            self.reloadData()
                            
                            pushChangeToiCloudZone(CKContainer.default().privateCloudDatabase, zonesToBeFetched, icloudZones!, {
                                
                            })
                        }
                    
                    default:
                        fatalError("Exception: \(String(describing: zName)) is not supported")
                }
            }
        })
        
        // somewhere in your code you might need to call:
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sectionTotalBudget(section: Int) -> (Double, String) {
        
        var total = 0.0;
        let sectionBudgetList = sectionList[section].data as? [XYZBudget]
        
        for budget in sectionBudgetList! {
            
            total = total + ((budget.value(forKey: XYZBudget.amount) as? Double) ?? 0.0 )
        }
        
        return (total, sectionList[section].title!)
    }
    
    func sectionSpentAmount(section: Int) -> (Double, String) {
        
        var total = 0.0;
        let sectionBudgetList = sectionList[section].data as? [XYZBudget]
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for budget in sectionBudgetList! {
            
            let expeneseList = self.getExpenseList(of: budget, from: (appDelegate?.expenseList)!)
            
            for expense in expeneseList {
                
                var needed = budget.currentEnd == nil
                    || budget.currentStart == nil
                
                if !needed {
                    
                    let occurrenceDates = expense.getOccurenceDates(until: Date()).filter { (date) -> Bool in
                        
                        return date >= budget.currentStart! && date < budget.currentEnd!
                    }
                    
                    needed = !occurrenceDates.isEmpty
                }
                
                if needed {
                    
                    let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
                    
                    total = total + amount
                }
            }
        }
        
        return (total, sectionList[section].title!)
    }
    
    func sectionRemainingBudget(section: Int) -> (Double, String) {
        
        var total = 0.0;
        let sectionBudgetList = sectionList[section].data as? [XYZBudget]
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for budget in sectionBudgetList! {
            
            let expeneseList = self.getExpenseList(of: budget, from: (appDelegate?.expenseList)!)
            
            for expense in expeneseList {
                
                var needed = budget.currentEnd == nil
                                || budget.currentStart == nil
                
                if !needed {
                    
                    let occurrenceDates = expense.getOccurenceDates(until: Date()).filter { (date) -> Bool in
                        
                        return date >= budget.currentStart! && date < budget.currentEnd!
                    }
                    
                    needed = !occurrenceDates.isEmpty
                }
                
                if needed {
                
                    let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
                    
                    total = total + amount
                }
            }
        }
        
        let (budget, _) = sectionTotalBudget(section: section)
        
        return (budget - total, sectionList[section].title!)
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
                
                var occurenceDates: [Date]?
                
                if currentStart == nil
                    || currentEnd == nil {
                    
                    occurenceDates = expense.getOccurenceDates(until: Date())
                } else {
                    
                    occurenceDates = expense.getOccurenceDates(until: currentEnd!)

                    occurenceDates = occurenceDates?.filter({ (date) -> Bool in
                        
                        date >= currentStart! && date < currentEnd!
                    })
                }
                
                if !(occurenceDates?.isEmpty)! {
                
                    let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
                    
                    total = total + ( amount * Double( (occurenceDates?.count)! ) )
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
        
        registerDeleteUndo(budget: oldBudget!)
        
        softdeletebudget(oldBudget!)
        
        saveManageContext()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code here
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: "Undo last change".localized(), style: .default, handler: { (action) in
            
            self.undoManager?.undo()
            self.undoManager?.removeAllActions()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let new = UIContextualAction(style: .normal, title: "New expense".localized() ) { _, _, handler in
            
            guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
                
                fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
            }
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                
                fatalError("Exception: XYZMainSplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = expenseDetailNavigationController
            
            let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            let currrency = budget.value(forKey: XYZBudget.currency) as? String
            let budgetGroup = budget.value(forKey: XYZBudget.name) as? String
            
            expenseDetailTableView.presetBudgetCategory = budgetGroup
            expenseDetailTableView.presetCurrencyCode = currrency
            expenseDetailTableView.setPopover(delegate: self)

            self.isPopover = true
            
            expenseDetailNavigationController.modalPresentationStyle = .popover
            handler(true)
            self.present(expenseDetailNavigationController, animated: true, completion: nil)
        }
        
        new.backgroundColor = UIColor.systemBlue
        commands.append(new)
        
        let more = UIContextualAction(style: .normal, title: "More".localized() ) { _, _, handler in
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (action) in
                
                handler(true)
            })
            
            let calendarViewAction = UIAlertAction(title: "Calendar view".localized(), style: .default, handler: { (action) in

                guard let calendarViewNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "CalendarViewNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: CalendarViewNavigationController is expected")
                }
                
                guard let calendarCollectionViewController = calendarViewNavigationController.viewControllers.first as? XYZCalendarCollectionViewController else {
                    
                    fatalError("Exception: XYZCalendarCollectionViewController is expected" )
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
                
                guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                    
                    fatalError("Exception: XYZMainSplitViewController is expected" )
                }
                
                mainSplitView.popOverNavigatorController = calendarViewNavigationController
                
                handler(true)
                self.present(calendarViewNavigationController, animated: true, completion: {})
            })
            
            let historicalViewAction = UIAlertAction(title: "Historical view".localized(), style: .default, handler: { (action) in
            
                guard let budgetListViewNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "BudgetListNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: BudgetListNavigationController is expected")
                }
            
                guard let budgetListViewController = budgetListViewNavigationController.viewControllers.first as? XYZBudgetListTableViewController else {
                    
                    fatalError("Exception: XYZBudgetListTableViewController is expected" )
                }
                
                let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
                let budget = sectionBudgetList![indexPath.row]
                budgetListViewController.budget = budget
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.orientation = UIInterfaceOrientationMask.portrait
                
                guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                    
                    fatalError("Exception: XYZMainSplitViewController is expected" )
                }
                
                mainSplitView.popOverNavigatorController = budgetListViewNavigationController
                
                handler(true)
                self.present(budgetListViewNavigationController, animated: true, completion: {})
            })
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                
                fatalError("Exception: XYZMainSplitViewController is expected" )
            }
            
            optionMenu.addAction(calendarViewAction)
            optionMenu.addAction(historicalViewAction)
            optionMenu.addAction(cancelAction)
            
            mainSplitView.popOverAlertController = optionMenu
            self.present(optionMenu, animated: true, completion: nil)
        }
        
        more.image = UIImage(named: "more")
        
        commands.append(more)
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
            
        let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
            
            // Delete the row from the data source
            let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let budget = sectionBudgetList![indexPath.row]
            
            self.deleteBudget(budget: budget)
            
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
        guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
        }
        
        if mainSplitView.isCollapsed  {
            
            guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "budgetDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating budgetDetailNavigationController")
            }
            
            guard let budgetDetailTableViewController = budgetDetailNavigationController.viewControllers.first as? XYZBudgetDetailTableViewController else {
                
                fatalError("Exception: XYZBudgetDetailTableViewController is expected")
            }

            budgetDetailTableViewController.setPopover(delegate: self)
            
            let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
            
            budgetDetailTableViewController.budget = sectionBudgetList?[indexPath.row]
            budgetDetailTableViewController.currencyCodes = currencyCodes
            isPopover = true
            budgetDetailNavigationController.modalPresentationStyle = .popover
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                
                fatalError("Exception: XYZMainSplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = budgetDetailNavigationController
            
            self.present(budgetDetailNavigationController, animated: true, completion: nil)
        } else {
            
            guard let detailTableViewController = delegate as? XYZBudgetDetailTableViewController else {
                
                fatalError("Exception: XYZBudgetDetailTableViewController is expedted" )
            }
            
            let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
            detailTableViewController.budgetDelegate = self
            detailTableViewController.currencyCodes = currencyCodes
            delegate?.budgetSelected(budget: sectionBudgetList?[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
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

        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 45)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = sectionList[section].title
        title.textColor = UIColor.systemGray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "budgetTableCell", for: indexPath) as? XYZBudgetTableViewCell else {
            
            fatalError("Exception: XYZBudgetTableViewCell is expected")
        }
        
        let sectionBudgetList = sectionList[indexPath.section].data as? [XYZBudget]
        let budget = sectionBudgetList![indexPath.row]
        
        let effectivebudget = budget.getEffectiveBudgetDateAmount()
        
        let name = budget.value(forKey: XYZBudget.name) as? String
        let amount = effectivebudget.amount ?? 0.0
        let currency = budget.value(forKey: XYZBudget.currency) as? String
        let budgetColor = XYZColor(rawValue: budget.value(forKey: XYZBudget.color) as? String ?? "")
        
        var period = "∞"
        if let currentStart = budget.currentStart, let currentEnd = budget.currentEnd {
            
            let periodEnd = Calendar.current.date(byAdding: .day, value: -1, to: currentEnd)
            period = "\(formattingDate(currentStart, style: .short)) ... \(formattingDate(periodEnd!, style: .short))"
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
        let spendAmount = getTotalSpendAmount(of: budget, from: (appDelegate?.expenseList)!)

        let balance = amount - spendAmount
        cell.balanceAmount.text = formattingCurrencyValue(of: balance, as: currency!)
        cell.amount.text = formattingCurrencyValue(of: amount, as: currency!)
        cell.name.text = name
        cell.length.text = period
        var color = UIColor.black
        
        if balance < 0.0 {
            
            color = UIColor.red
        } else {
            
            if #available(iOS 13.0, *) {
                
                color = UIColor.label
            } else {
                
                color = UIColor.black
            } 
        }
        
        cell.balanceAmount.textColor = color
        cell.dotColorView.backgroundColor = (budgetColor?.uiColor())!
        
        if let iconName = budget.value(forKey: XYZBudget.iconName) as? String, iconName != "" {

            cell.icon.isHidden = false
            cell.icon.image = UIImage(named: iconName)
            cell.icon.image = cell.icon.image?.withRenderingMode(.alwaysTemplate)
            
            if #available(iOS 13.0, *) {
                
                cell.icon.image?.withTintColor(UIColor.systemBlue)
            } else {
                // Fallback on earlier versions
            }
        } else {

            cell.icon.image = UIImage(named: "empty")
            cell.icon.setNeedsDisplay()
        }
        
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        fatalError("Unreachable")
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
        
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            
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
        secondaryViewController.navigationItem.title = "New budget".localized()
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let budgetDetailTableViewController = navigationController.viewControllers.first as? XYZBudgetDetailTableViewController {
                
                budgetDetailTableViewController.budgetDelegate = self
                budgetDetailTableViewController.isPushinto = true
                
                if !isPopover && budgetDetailTableViewController.modalEditing {
                    
                    budgetDetailTableViewController.isPushinto = false
                    budgetDetailTableViewController.isPopover = true
                    navigationController.modalPresentationStyle = .popover
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                        
                        fatalError("Exception: XYZMainSplitViewController is expected" )
                    }
                    
                    mainSplitView.popOverNavigatorController = navigationController
                    
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
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        guard let budgetDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "budgetDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating budgetDetailNavigationController")
        }
        
        guard let budgetDetailTableViewController = budgetDetailNavigationController.viewControllers.first as? XYZBudgetDetailTableViewController else {
            
            fatalError("Exception: XYZBudgetDetailTableViewController is expected")
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
