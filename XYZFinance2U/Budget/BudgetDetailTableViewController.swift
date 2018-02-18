//
//  BudgetDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/15/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol BudgetDetailDelegate: class {
    
    func saveNewBudget(budget: XYZBudget)
    func saveBudget(budget: XYZBudget)
    func deleteBudget(budget: XYZBudget)
}

class BudgetDetailTableViewController: UITableViewController,
    BudgetSelectionDelegate,
    BudgetDetailTextTableViewCellDelegate,
    BudgetDetailDateTableViewCellDelegate,
    BudgetDetailDatePickerTableViewCellDelegate,
    BudgetDetailCommandDelegate,
    SelectionDelegate {
    
    func executeCommand(_ sender: BudgetDetailCommandTableViewCell) {

        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: sender.command.text, style: .default, handler: { (action) in
            
            self.budgetDelegate?.deleteBudget(budget: self.budget!)
            
            if self.isPushinto {
                
                self.navigationController?.popViewController(animated: true)
            } else if self.isCollapsed {
                
                self.dismiss(animated: true, completion: nil)
            } else {
                
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.leftBarButtonItem = nil
                self.budget = nil
                self.reloadData()
                
                let masterViewController  = self.getMasterTableViewController()
                
                masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
                masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            }

            self.modalEditing = false
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func dateDidPick(_ sender: BudgetDetailDatePickerTableViewCell) {
    
        date = sender.date!
        let indexPath = tableView.indexPath(for: sender)
        let dateIndexPath = IndexPath(row: (indexPath?.row)! - 1, section: (indexPath?.section)!)
        
        tableView.reloadRows(at: [dateIndexPath], with: .none)
        //tableView.reloadSections(indexPath, with: UITableViewRowAnimation.none)
    }
    
    func dateInputTouchUp(_ sender: BudgetDetailDateTableViewCell) {

        let indexPath = tableView.indexPath(for: sender)
        let showDatePicker = sectionList[(indexPath?.section)!].cellList.count - 1 > (indexPath?.row)!

        if !showDatePicker {
            
            sectionList[(indexPath?.section)!].cellList.insert("datepicker", at: (indexPath?.row)! + 1)
        } else {
            
            sectionList[(indexPath?.section)!].cellList.remove(at: (indexPath?.row)! + 1)
        }
        
        tableView.reloadData()
    }
    
    func selection(_ sender: SelectionTableViewController, item: String?) {

        switch sender.selectionIdentifier {
            case "length":
                length = XYZBudget.Length(rawValue: item!)!
            
            case "currency":
                currencyCode = item!
            
            default:
                break
        }
        
        tableView.reloadData() // TODO: how do we improve by just the row, does it worth it?
    }
        
    func textDidEndEditing(_ sender: BudgetDetailTextTableViewCell) {
        
        if let index = tableView.indexPath(for: sender) {
            
            switch sectionList[index.section].cellList[index.row] {
                
                case "budget":
                    budgetType = sender.input.text!
                    navigationItem.rightBarButtonItem?.isEnabled = !budgetType.isEmpty
                
                case "amount":
                    amount = formattingDoubleValueAsDouble(input: sender.input.text!)
                    break
                
                default:
                    fatalError("Exception: \(sectionList[index.section].cellList[index.row] ) is not supported")
            }
        }
    }
    
    func textDidBeginEditing(_ sender: BudgetDetailTextTableViewCell) {
    
    }
    
    
    func budgetSelected(newBudget: XYZBudget?) {

        modalEditing = false
        budget = newBudget
        reloadData()
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        navigationItem.leftBarButtonItem = nil
    }
    
    func budgetDeleted(deletedBudget: XYZBudget) {
    
    }

    var budgetDelegate: BudgetDetailDelegate?
    var isPopover: Bool = false
    var isPushinto: Bool = false
    var modalEditing = true
    var budget: XYZBudget?
    var sectionList = [TableSectionCell]()
    var budgetType = ""
    var amount = 0.0
    var currencyCode = Locale.current.currencyCode
    var length: XYZBudget.Length = XYZBudget.Length.none
    var date = Date()
    var datecell: BudgetDetailDateTableViewCell?
    var currencyCodes = [String]()
    
    var isCollapsed: Bool {
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            return split.isCollapsed
        } else {
            
            return true
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        
        if isPushinto {
            
            fatalError("Exception: todo")
        } else if isPopover {
            
            dismiss(animated: true, completion: nil)
        } else {
            
            let masterViewController  = getMasterTableViewController()
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            budgetSelected(newBudget: budget)
        }
    }
    
    @IBAction func edit(_ sender: Any) {
        
        let  masterViewController = getMasterTableViewController();
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        navigationItem.setRightBarButton(doneButton, animated: true)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        
        masterViewController.navigationItem.leftBarButtonItem?.isEnabled = false
        masterViewController.navigationItem.rightBarButtonItem?.isEnabled = false
        
        modalEditing = true
        
        reloadData()
    }
    
    @IBAction func save(_ sender: Any) {
        
        if isPushinto {
            
            fatalError("Exception: todo")
            
            //saveData()
            //expenseDelegate?.saveExpense(expense: expense!)
            //navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            if nil == budget {
             
                budget = XYZBudget(id: nil, name: budgetType, amount: amount, currency: currencyCode!, length: length, start: date, sequenceNr: 0, context: managedContext())
                
                saveData()
                budgetDelegate?.saveNewBudget(budget: budget!)
            } else {
                
                saveData()
                budgetDelegate?.saveBudget(budget: budget!)
            }

            dismiss(animated: true, completion: nil)
        } else {
            
            fatalError("TODO")
            /*
            saveData()
            navigationItem.leftBarButtonItem?.isEnabled = false
            modalEditing = false
            loadDataInTableSectionCell()
            tableView.reloadData()
            
            let masterViewController = getMasterTableViewController()
            
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
            navigationItem.setRightBarButton(editButton, animated: true)
            navigationItem.leftBarButtonItem = nil
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            
            incomeDelegate?.saveIncome(income: income!)
            */
        }
    }
    
    private func getMasterTableViewController() -> BudgetTableViewController {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        guard let tabBarController = mainSplitView.viewControllers.first as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected")
        }
        
        guard let navController = tabBarController.selectedViewController as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        return (navController.topViewController as? BudgetTableViewController)!
    }
    
    func saveData() {
        
        var hasChanged = false
   
        if let existingBudgetType = budget?.value(forKey: XYZBudget.name) as? String, existingBudgetType != budgetType {
            
            hasChanged = true
        } else if let existingAmount = budget?.value(forKey: XYZBudget.amount) as? Double, existingAmount != amount {
            
            hasChanged = true
        } else if let existingCurrencyCode = budget?.value(forKey: XYZBudget.currency) as? String, existingCurrencyCode != currencyCode {
            
            hasChanged = true
        } else if let existingLength = budget?.value(forKey: XYZBudget.currency) as? XYZBudget.Length, existingLength != length {
            
            hasChanged = true
        } else if let existingDate = budget?.value(forKey: XYZBudget.start) as? Date, existingDate != date {
            
            hasChanged = true
        }

        budget?.setValue(budgetType, forKey: XYZBudget.name)
        budget?.setValue(amount, forKey: XYZBudget.amount)
        budget?.setValue(currencyCode, forKey: XYZBudget.currency)
        budget?.setValue(date, forKey: XYZBudget.start)
        budget?.setValue(length.rawValue, forKey: XYZBudget.length)

        if nil == budget?.value(forKey: XYZBudget.lastRecordChange) as? Date
            || hasChanged {
            
            budget?.setValue(Date(), forKey: XYZBudget.lastRecordChange)
        }
    }
    
    func loadDataIntoSectionList() {
    
        sectionList = [TableSectionCell]()
        
        let mainSection = TableSectionCell(identifier: "main", title: nil, cellList: ["budget", "amount", "currency"], data: nil)
        sectionList.append(mainSection)
        
        let lengthSection = TableSectionCell(identifier: "length", title: nil, cellList: ["length", "date"], data: nil)
        sectionList.append(lengthSection)
        
        if modalEditing && nil != budget {
            
            let deleteSection = TableSectionCell(identifier: "delete",
                                                 title: "",
                                                 cellList: ["delete"],
                                                 data: nil)
            sectionList.append(deleteSection)
        }
    }
    
    func reloadData() {
        
        loadData()
        tableView.reloadData()
    }
    
    func loadData() {
        
        if let _ = budget {
            
            navigationItem.title = "Budget"
            
            budgetType = (budget?.value(forKey: XYZBudget.name) as? String)!
            amount = (budget?.value(forKey: XYZBudget.amount) as? Double)!
            currencyCode = budget?.value(forKey: XYZBudget.currency) as? String
            length = XYZBudget.Length(rawValue: (budget?.value(forKey: XYZBudget.length) as? String)!)!
            date = (budget?.value(forKey: XYZBudget.start) as? Date)!
        } else {
            
            budgetType = ""
            amount = 0.0
            currencyCode = Locale.current.currencyCode
            length = XYZBudget.Length.none
            date = Date()
            
            navigationItem.title = "New budget"
            navigationItem.rightBarButtonItem?.isEnabled = !budgetType.isEmpty
        }

        loadDataIntoSectionList()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)

        navigationItem.largeTitleDisplayMode = .never
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            if !split.isCollapsed {
                
                navigationItem.rightBarButtonItem = nil
                navigationItem.leftBarButtonItem = nil
                
                modalEditing = false
            }
        }
        
        if isPopover {
            
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
            navigationItem.setRightBarButton(saveButton, animated: true)
        }
        
        loadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func setPopover(delegate: BudgetDetailDelegate) {
        
        isPopover = true
        budgetDelegate = delegate
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 35
        } else {
            
            return 17.5
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionList[section].title
    }

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return sectionList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
        
            case "budget":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailTextCell", for: indexPath) as? BudgetDetailTextTableViewCell else {
                    
                    fatalError("Exception: budgetDetailTextCell is failed to be created")
                }
            
                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "budget type"
                textcell.input.text = budgetType
                textcell.label.text = "Budget"
                
                cell = textcell
            
            
            case "amount":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailTextCell", for: indexPath) as? BudgetDetailTextTableViewCell else {
                    
                    fatalError("Exception: budgetDetailTextCell is failed to be created")
                }

                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.enableMonetaryEditing(true, currencyCode!)
                
                textcell.input.placeholder = formattingCurrencyValue(input: 0.0, code: currencyCode)
                textcell.input.text = formattingCurrencyValue(input: amount, code: currencyCode)
                textcell.label.text = "Amount"
                
                cell = textcell

            case "currency":
                guard let currencycell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? BudgetDetailSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }
                
                currencycell.setLabel("Currency")
                currencycell.setSelection(currencyCode ?? "USD")
                currencycell.selectionStyle = .none
                
                cell = currencycell
            
            case "length":
                guard let currencycell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? BudgetDetailSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }
                
                currencycell.setLabel("Period")
                currencycell.setSelection(length.rawValue)
                currencycell.selectionStyle = .none
                
                cell = currencycell
            
            case "date":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailDateTextCell", for: indexPath) as? BudgetDetailDateTableViewCell else {
                    
                    fatalError("Exception: budgetDetailDateTextCell is failed to be created")
                }
                
                datecell.dateInput.text = formattingDate(date: date, style: .medium)
                datecell.delegate = self
                datecell.label.text = "Start date"
                datecell.enableEditing = modalEditing
                self.datecell = datecell
                
                cell = datecell
            
        case "datepicker":
            guard let datepickercell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailDatePickerCell", for: indexPath) as? BudgetDetailDatePickerTableViewCell else {
                
                fatalError("Exception: incomeDetailDatePickerCell is failed to be created")
            }
            
            datepickercell.setDate(date)
            datepickercell.delegate = self
            
            cell = datepickercell
            
        case "delete":
            guard let deletecell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailCommandTextCell", for: indexPath) as? BudgetDetailCommandTableViewCell else {
                
                fatalError("Exception: budjectDetailCommandTextCell is failed to be created")
            }
            
            deletecell.delegate = self
            deletecell.setCommand(command: "Delete Budget")
            
            cell = deletecell
            
            default:
                fatalError("Exception: \(sectionList[indexPath.section].cellList[indexPath.row]) not handle")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        if let _ = tableView.cellForRow(at: indexPath) as? BudgetDetailSelectionTableViewCell {
            
            return indexPath
        } else {
            
            return nil
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
            
        case "currency":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "SelectionTableViewController") as? SelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "currency"
            
            if !currencyCodes.isEmpty {
                
                selectionTableViewController.setSelections("", false, currencyCodes)
            }
            
            var codeIndex: Character?
            var codes = [String]()
            for code in Locale.isoCurrencyCodes {
                
                if nil == codeIndex {
                    
                    codes.append(code)
                    codeIndex = code.first
                } else if code.first == codeIndex {
                    
                    codes.append(code)
                } else {
                    
                    var identifier = ""
                    identifier.append(codeIndex!)
                    
                    selectionTableViewController.setSelections(identifier, true, codes )
                    codes.removeAll()
                    codes.append(code)
                    codeIndex = code.first
                }
            }
            
            var identifier = ""
            identifier.append(codeIndex!)
            
            selectionTableViewController.setSelections(identifier, true, codes )
            selectionTableViewController.setSelectedItem(currencyCode ?? "USD")
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)

        case "length":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "SelectionTableViewController") as? SelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "length"
            selectionTableViewController.setSelections("", false,
                                                       [XYZBudget.Length.none.rawValue,
                                                        XYZBudget.Length.hourly.rawValue,
                                                        XYZBudget.Length.daily.rawValue,
                                                        XYZBudget.Length.weekly.rawValue,
                                                        XYZBudget.Length.biweekly.rawValue,
                                                        XYZBudget.Length.monthly.rawValue,
                                                        XYZBudget.Length.yearly.rawValue])
            selectionTableViewController.setSelectedItem(length.rawValue)
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)
            
        default:
            fatalError("Exception \(sectionList[indexPath.section].cellList[indexPath.row]) is not handled")
            
        }
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
