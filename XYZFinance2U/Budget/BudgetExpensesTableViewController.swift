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
    
    func reloadData()
    func deleteExpense(expense: XYZExpense)
}

class BudgetExpensesTableViewController: UITableViewController,
    ExpenseDetailDelegate {

    // MARK: - Properties
    
    var monthYearDate: Date?
    var expenseList: [XYZExpense]?
    var sectionList = [TableSectionCell]()
    var delegate: BudgetExpenseDelegate?
    var headerPretext: String?
    var readonly = false
    var hasDisclosureIndicator = false
    
    // MARK: - functions
    
    func addBackButton() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal) // Image can be downloaded from here below link
        backButton.setTitle(" \("Back".localized())", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientation = UIInterfaceOrientationMask.all
        
        dismiss(animated: true, completion: nil)
    }
    
    func cancelExpense() {
        
        delegate?.reloadData()
    }
    
    func saveNewExpenseWithoutUndo(expense: XYZExpense) {
        
        guard let calendarViewController = delegate as? CalendarCollectionViewController else {
            
            fatalError("Exception: CalendarCollectionViewController is expected")
        }
        
        calendarViewController.saveNewExpense(expense: expense)
    }
    
    func saveNewExpense(expense: XYZExpense) {
        
        saveNewExpenseWithoutUndo(expense: expense)
    }
    
    func saveExpense(expense: XYZExpense) {
        
        saveManageContext()
        
        updateToiCloud(expense)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.expenseList = loadExpenses()!
        
        delegate?.reloadData()
    }
    
    func registerUndoDeleteExpense(expense: XYZExpense) {
        
        let oldRecordId = expense.value(forKey: XYZExpense.recordId) as? String
        let oldDetail = expense.value(forKey: XYZExpense.detail) as? String ?? ""
        let oldAmount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
        let oldDate = expense.value(forKey: XYZExpense.date) as? Date ?? Date()
        let oldIsShared = expense.value(forKey: XYZExpense.isShared) // if we can save it, it means it is not readonly
        let oldShareRecordId = expense.value(forKey: XYZExpense.shareRecordId)
        let oldShareUrl = expense.value(forKey: XYZExpense.shareUrl)
        let oldHasLocation = expense.value(forKey: XYZExpense.hasLocation)
        let oldCurrencyCode = expense.value(forKey: XYZExpense.currencyCode)
        let oldBudgetCategory = expense.value(forKey: XYZExpense.budgetCategory)
        let oldRecurring = expense.value(forKey: XYZExpense.recurring)
        let oldRecurringStopDate = expense.value(forKey: XYZExpense.recurringStopDate)
        let oldLocation = expense.value(forKey: XYZExpense.loction)
        let oldReceiptList = expense.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>
        let oldPersonList = expense.getPersons()
        
        undoManager?.registerUndo(withTarget: self, handler: { (viewController) in
            
            let newExpense = XYZExpense(id: oldRecordId ?? nil, detail: oldDetail, amount: oldAmount, date: oldDate, context: managedContext())
            
            newExpense.setValue(oldIsShared, forKey: XYZExpense.isShared)
            newExpense.setValue(oldHasLocation, forKey: XYZExpense.hasLocation)
            newExpense.setValue(oldCurrencyCode, forKey: XYZExpense.currencyCode)
            newExpense.setValue(oldBudgetCategory, forKey: XYZExpense.budgetCategory)
            newExpense.setValue(oldRecurring, forKey: XYZExpense.recurring)
            newExpense.setValue(oldRecurringStopDate, forKey: XYZExpense.recurringStopDate)
            newExpense.setValue(oldLocation, forKey: XYZExpense.loction)
            newExpense.setValue(oldReceiptList, forKey: XYZExpense.receipts)
            newExpense.setValue(oldPersonList, forKey: XYZExpense.persons)
            newExpense.setValue(oldShareUrl, forKey: XYZExpense.shareUrl)
            newExpense.setValue(oldShareRecordId, forKey: XYZExpense.shareRecordId)
            newExpense.setValue(Date(), forKey: XYZExpense.lastRecordChange)
            
            self.saveNewExpenseWithoutUndo(expense: newExpense)
        })
    }

    func deleteExpense(expense: XYZExpense) {
        
        registerUndoDeleteExpense(expense: expense)
        deleteExpenseWithoutUndo(expense: expense)
    }
    
    func deleteExpenseWithoutUndo(expense: XYZExpense) {
        
        let aContext = managedContext()
        var indexPath = IndexPath(row: 0, section: 0)
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
            let sectionExpenseList = section.data as? [XYZExpense]
            
            for (index, expenseItem) in (sectionExpenseList?.enumerated())! {
                
                if expense == expenseItem {
                    
                    indexPath = IndexPath(row: index, section: sectionIndex)
                    break
                }
            }
        }
        
        let sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
        
        self.sectionList[indexPath.section].data = sectionExpenseList
        self.expenseList = sectionExpenseList
        
        let isSoftDelete = self.softDeleteExpense(expense: expense)
        
        saveManageContext()
        
        if isSoftDelete {
            
            self.updateToiCloud(expense)
        } else {
            
            aContext?.delete(expense)
            
            
            self.updateToiCloud(nil)
        }
        
        self.delegate?.deleteExpense(expense: expense)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.expenseList = loadExpenses()!
        
        self.delegate?.reloadData()
        self.loadData()
    }
    
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
        
        self.expenseList = sortExpenses( expenseList! )
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
        cell.monthYearDate = monthYearDate
        cell.setExpense(expense: expense)
        
        if hasDisclosureIndicator {
            
            cell.accessoryType = .disclosureIndicator

            for constraint in cell.cellContentView.constraints {
                
                if constraint.identifier == "amount" {
                    
                    constraint.constant = 5
                }
            }
        }
        
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
                                    
                DispatchQueue.main.async {
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    
                    appDelegate?.expenseList = loadExpenses()!
                    
                    self.delegate?.reloadData()
                    self.loadData()
                }
            })
        }
    }
    
    // MARK: - table functions
    
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
        
        if hasDisclosureIndicator {
            
            stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 43)
        } else {
            
            stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
        
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = headerPretext ?? "Total".localized()
        title.textColor = UIColor.gray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
        if let currencyCode = currencyCode {
            
            subtotal.text = formattingCurrencyValue(of: total, as: currencyCode)
            subtotal.textColor = UIColor.gray
            stackView.addArrangedSubview(subtotal)
        }
        
        return stackView
    }
    
    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        if !readonly {
            
            let sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
            let expense = sectionExpenseList![indexPath.row]
            
            let copy = UIContextualAction(style: .normal, title: "Copy".localized() ) { _, _, handler in
                
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
                
                let detail = expense.value(forKey: XYZExpense.detail) as? String
                let amount = expense.value(forKey: XYZExpense.amount) as? Double
                let budgetGroup = expense.value(forKey: XYZExpense.budgetCategory) as? String
                let date = Date()
                let currency = expense.value(forKey: XYZExpense.currencyCode) as? String
                
                expenseDetailTableView.presetAmount = amount
                expenseDetailTableView.presetDate = date
                expenseDetailTableView.presetDetail = detail
                expenseDetailTableView.presetBudgetCategory = budgetGroup
                expenseDetailTableView.presetCurrencyCode = currency
                expenseDetailTableView.setPopover(delegate: self)
                
                expenseDetailNavigationController.modalPresentationStyle = .popover
                handler(true)
                self.present(expenseDetailNavigationController, animated: true, completion: nil)
            }
            
            copy.backgroundColor = UIColor.systemBlue
            commands.append(copy)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    
        var commands = [UIContextualAction]()
        
        if !readonly {
            
            var sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
            // let expense = sectionExpenseList![indexPath.row]

            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                //let aContext = managedContext()
                
                let oldExpense = sectionExpenseList?.remove(at: indexPath.row)
                self.deleteExpense(expense: oldExpense!)
                
                handler(true)
            }
            
            commands.append(delete)
            
            /*
            let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool
            
            if !(isShared!) {
                
                if let url = expense.value(forKey: XYZExpense.shareUrl) as? String {
                    
                    let more = UIContextualAction(style: .normal, title: "More".localized()) { _, _, handler in
                        
                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                            
                            fatalError("Exception: UISplitViewController is expected" )
                        }
                        
                        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        let copyUrlOption = UIAlertAction(title: "Share expense url".localized(), style: .default, handler: { (action) in
                            
                            let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
                            self.present(vc, animated: true, completion: {

                                self.delegate?.reloadData()
                                self.loadData()
                            })
                            
                            mainSplitView.popOverAlertController = nil
                            handler(true)
                        })
                        
                        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { (action) in
                            
                            mainSplitView.popOverAlertController = nil
                            handler(true)
                        })
                        
                        optionMenu.addAction(copyUrlOption)
                        optionMenu.addAction(cancelAction)
                        
                        mainSplitView.popOverAlertController = optionMenu
                        self.present(optionMenu, animated: true, completion: nil)
                    }
                    
                    more.image = UIImage(named: "more")
                    commands.append(more)
                }
            }
            */
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        mainSplitView.popOverNavigatorController = expenseDetailNavigationController
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
