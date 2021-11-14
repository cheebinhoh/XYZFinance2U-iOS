//
//  XYZBudgetExpenseTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/25/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

protocol BudgetExpenseDelegate: AnyObject {
    
    func reloadData()
    func deleteExpense(expense: XYZExpense)
}

class XYZBudgetExpenseTableViewController: UITableViewController,
    XYZExpenseDetailDelegate {

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
        
        guard let calendarViewController = delegate as? XYZCalendarCollectionViewController else {
            
            fatalError("Exception: XYZCalendarCollectionViewController is expected")
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
        
        let oldRecordId = expense.recordId
        let oldDetail = expense.detail
        let oldAmount = expense.amount
        let oldDate = expense.date
        let oldIsShared = expense.isShared // if we can save it, it means it is not readonly
        let oldShareRecordId = expense.shareRecordId
        let oldShareUrl = expense.shareUrl
        let oldCurrencyCode = expense.currencyCode
        let oldBudgetCategory = expense.budgetCategory
        let oldRecurring = expense.recurring
        let oldRecurringStopDate = expense.recurringStopDate
        let oldReceiptList = expense.receipts
        let oldPersonList = expense.getPersons()
        
        undoManager?.registerUndo(withTarget: self, handler: { (viewController) in
            
            let newExpense = XYZExpense(id: oldRecordId, detail: oldDetail, amount: oldAmount, date: oldDate, context: managedContext())
            
            newExpense.isShared = oldIsShared
            newExpense.currencyCode = oldCurrencyCode
            newExpense.budgetCategory = oldBudgetCategory
            newExpense.recurring = oldRecurring
            newExpense.recurringStopDate = oldRecurringStopDate
            newExpense.receipts = oldReceiptList
            newExpense.persons = oldPersonList
            newExpense.shareUrl = oldShareUrl
            newExpense.shareRecordId = oldShareRecordId
            newExpense.lastRecordChange = Date()
            
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

            let index = sectionExpenseList?.firstIndex(where: {
                
                return $0 == expense
            })

            if let index = index {
                
                indexPath = IndexPath(row: index, section: sectionIndex)
                break
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
        
        if let expenseList = expenseList, !expenseList.isEmpty {
            
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

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewCell", for: indexPath) as? XYZExpenseTableViewCell else {
            
            fatalError("Exception: expenseTableViewCell is expected" )
        }
        
        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
        let expense = sectionExpenseList![indexPath.row]
        cell.monthYearDate = monthYearDate
        cell.setExpense(expense: expense)
        
        /*
        if hasDisclosureIndicator {
            
            cell.accessoryType = .disclosureIndicator

            for constraint in cell.cellContentView.constraints {
                
                if constraint.identifier == "amount" {
                    
                    constraint.constant = 5
                }
            }
        }
        */
        
        return cell
    }

    func softDeleteExpense(expense: XYZExpense) -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        
        if expense.isShared {
            
            expense.isSoftDelete = true
            expense.lastRecordChange = Date()
        }
        
        if !((appDelegate?.iCloudZones.isEmpty)!) {
            
            if expense.isShared  {
                
            } else {
                
                guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
                    
                    fatalError("Exception: iCloudZoen is expected")
                }
                
                let data = zone.deleteRecordIdList
                
                guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }
                
                deleteRecordList.append(expense.recordId)
                
                let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
                zone.deleteRecordIdList = savedDeleteRecordList!
                
                let shareRecordNameData = zone.deleteShareRecordIdList
                
                guard var deleteShareRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(shareRecordNameData) as? [String] else {
                    
                    fatalError("Exception: deleteShareRecordList is expected as [String]")
                }
    
                if expense.shareRecordId != "" {
                    
                    deleteShareRecordList.append(expense.shareRecordId)
                    
                    let savedDeleteShareRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordList, requiringSecureCoding: false)
                    zone.deleteShareRecordIdList = savedDeleteShareRecordList!
                }
            }
        }
        
        return expense.isShared  // if it is shared, then we softdelete it by keeping
    }
    
    func updateToiCloud(_ expense: XYZExpense?) {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let iCloudZone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!)
        iCloudZone?.data = appDelegate?.expenseList
        
        if let iCloudZone = iCloudZone {
            
            fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                                 zones: [ckrecordzone],
                                 iCloudZones: [iCloudZone], completionblock: {
                                    
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
        let sectionExpenseList = sectionList[section].data as? [XYZExpense]
        
        let currencyCode = sectionExpenseList!.first?.currencyCode
        
        let total = sectionExpenseList!.reduce(0.0) { (result, expense) in
        
            return result + expense.amount
        }
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 15)
        
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
                
                guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: ExpenseDetailNavigationController is expected")
                }
                
                guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
                    
                    fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
                }
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                    
                    fatalError("Exception: XYZMainUITabBarController is expected")
                }
                
                tabBarController.popOverNavigatorController = expenseDetailNavigationController
                
                let detail = expense.detail
                let amount = expense.amount
                let budgetGroup = expense.budgetCategory
                let date = Date()
                let currency = expense.currencyCode
                
                expenseDetailTableView.presetAmount = amount
                expenseDetailTableView.presetDate = date
                expenseDetailTableView.presetDetail = detail
                expenseDetailTableView.presetBudgetCategory = budgetGroup
                expenseDetailTableView.presetCurrencyCode = currency
                expenseDetailTableView.setDelegate(delegate: self)
                
                //xpenseDetailNavigationController.modalPresentationStyle = .popover
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

            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                let oldExpense = sectionExpenseList?.remove(at: indexPath.row)
                self.deleteExpense(expense: oldExpense!)
                
                handler(true)
            }
            
            commands.append(delete)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
            
            fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
        }
        
        expenseTableView.setDelegate(delegate: self)
        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]

        expenseTableView.expense = sectionExpenseList?[indexPath.row]
        //expenseDetailNavigationController.modalPresentationStyle = .popover
        self.present(expenseDetailNavigationController, animated: true, completion: nil)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        tabBarController.popOverNavigatorController = expenseDetailNavigationController
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
