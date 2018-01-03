//
//  IncomeDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/24/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import UserNotifications
import NotificationCenter

protocol IncomeDetailDelegate: class {
    
    func saveNewIncome(income: XYZAccount)
    func saveIncome(income: XYZAccount)
    func deleteIncome(income: XYZAccount)
}

class IncomeDetailTableViewController: UITableViewController,
    IncomeDetailTextTableViewCellDelegate,
    IncomeDetailDateTableViewCellDelegate,
    IncomeDetailDatePickerTableViewCellDelegate,
    IncomeDetailCommandDelegate,
    IncomeSelectionDelegate,
    IncomeDetailSwitchDelegate {
    
    func optionUpdate(_ sender: IncomeDetailSwitchTableViewCell, option: Bool) {
        
        let indexPath = tableView.indexPath(for: sender)
        
        switch tableSectionCellList[indexPath!.section].cellList[indexPath!.row] {
            
            case "remind":
                if option {
                    
                    hasUpdateReminder = true
                } else {
                    hasUpdateReminder = false
                    reminddate = nil // FIXME: we need to reload the original value from the core data
                }

                loadDataInTableSectionCell()
                tableView.reloadData()
            
            default:
                fatalError("Exception: index of IncomeDetailSwitchTableViewCell is not found in tableview")
        }
    }
    
    
    func incomeSelected(newIncome: XYZAccount?) {
        
        modalEditing = false
        income = newIncome
        reloadData()
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        navigationItem.leftBarButtonItem = nil
    }
    
    func incomeDeleted(deletedIncome: XYZAccount) {

    }
    
    func reloadData() {
        
        loadData()
        
        tableView.reloadData()
    }

    private func getMasterTableViewController() -> IncomeTableViewController {
        
        var masterViewController: IncomeTableViewController?
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            guard let tabBarController = split.viewControllers.first as? UITabBarController else {
                fatalError("Exception: UITabBarController is expected")
            }
            
            guard let navController = tabBarController.selectedViewController as? UINavigationController else {
                fatalError("Exception: UINavigationController is expected")
            }
            
            masterViewController = (navController.topViewController as? IncomeTableViewController)!
        } else if let split = self.parent?.parent?.parent as? UISplitViewController {
            
            guard let tabBarController = split.viewControllers.first as? UITabBarController else {
                fatalError("Exception: UITabBarController is expected")
            }
            
            guard let navController = tabBarController.selectedViewController as? UINavigationController else {
                fatalError("Exception: UINavigationController is expected")
            }
            
            masterViewController = (navController.viewControllers.first as? IncomeTableViewController)!
        }
        
        return masterViewController!
    }
    
    func executeCommand(_ sender: IncomeDetailCommandTableViewCell) {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: sender.command.text, style: .default, handler: { (action) in
            
            self.incomeDelegate?.deleteIncome(income: self.income!)
            
            if self.isPushinto {
                
                self.navigationController?.popViewController(animated: true)
            } else if self.isCollapsed {
                
                self.dismiss(animated: true, completion: nil)
            } else {
                
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.leftBarButtonItem = nil
                self.income = nil
                self.reloadData()
                
                let masterViewController  = self.getMasterTableViewController()
                
                masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
                masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func dateDidPick(_ sender: IncomeDetailDatePickerTableViewCell) {
        
        let indexPath = tableView.indexPath(for: sender)
        
        switch tableSectionCellList[indexPath!.section].identifier {
            
            case "balance":
                datecell?.dateInput.text = formattingDate(date: sender.date ?? Date(), .medium)
                date = sender.date ?? Date()

            case "remind":
                dateremindcell?.dateInput.text = formattingDateTime(date: sender.date ?? Date())
                reminddate = sender.date ?? Date()
            
            default:
                fatalError("Exception: dateDidPick is not handled at \(String(describing: indexPath))")
        }
    }
    
    func dateInputTouchUp(_ sender: IncomeDetailDateTableViewCell) {
        
        let indexPath = tableView.indexPath(for: sender)
        let showDatePicker = tableSectionCellList[indexPath!.section].cellList.count > ( (indexPath?.row)! + 1 )
        let datepickeridentifier = tableSectionCellList[indexPath!.section].identifier == "remind" ? "reminddatepicker" : "datepicker"
        
        if !showDatePicker {
            
            tableSectionCellList[(indexPath?.section)!].cellList.insert(datepickeridentifier, at: (indexPath?.row)! + 1)
        } else {
            
            tableSectionCellList[(indexPath?.section)!].cellList.remove(at: (indexPath?.row)! + 1)
        }
        
        tableView.reloadData()
    }
    
    func textDidEndEditing(_ sender: IncomeDetailTextTableViewCell) {
        
        if modalEditing {
            
            guard let index = tableView.indexPath(for: sender) else {
                fatalError("Exception: index path is expected")
            }
            
            switch tableSectionCellList[index.section].cellList[index.row] {
                
                case "bank":
                    bank = sender.input.text!
                
                case "amount":
                    amount = formattingDoubleValueAsDouble(input: sender.input.text!)
                
                case "accountNr":
                    accountNr = sender.input.text!
                
                default:
                    fatalError("Exception: \(tableSectionCellList[index.section].cellList[index.row]) is not expected")
            }
        }
    }
    
    func textDidBeginEditing(_ sender: IncomeDetailTextTableViewCell) {
        
    }
    
    // MARK: - IBOutlet
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    // MARK: - property
    var income: XYZAccount?
    var modalEditing = true
    var isPopover = false
    var isPushinto = false
    var incomeDelegate: IncomeDetailDelegate?
    var hasUpdateReminder = false
    
    var bank = ""
    var accountNr = ""
    var amount: Double?
    var date: Date?
    var reminddate: Date?
    var repeatselection: String?
    
    var isCollapsed: Bool {
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            return split.isCollapsed
        } else {
            
            return true
        }
    }
    
    var tableSectionCellList = [TableSectionCell]()
    weak var datecell: IncomeDetailDateTableViewCell?
    weak var dateremindcell: IncomeDetailDateTableViewCell?
    
    // MARK: - IBAction
    
    @IBAction func edit(_ sender: Any) {
        
        let  masterViewController = getMasterTableViewController();
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        navigationItem.setRightBarButton(doneButton, animated: true)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        
        masterViewController.navigationItem.leftBarButtonItem?.isEnabled = false
        masterViewController.navigationItem.rightBarButtonItem?.isEnabled = false
        
        modalEditing = true
        
        let deleteSection = TableSectionCell(identifier: "delete",
                                             title: "",
                                             cellList: ["delete"],
                                             data: nil)
        tableSectionCellList.insert(deleteSection, at: tableSectionCellList.count - 1)
        
        loadDataInTableSectionCell()
        tableView.reloadData()
    }

    @IBAction func save(_ sender: Any) {
        
        if isPushinto {
            
            fatalError("Exception: todo")
            
            //saveData()
            //expenseDelegate?.saveExpense(expense: expense!)
            //navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            if nil == income {
                
                income = XYZAccount(sequenceNr: 0, bank: bank, accountNr: accountNr, amount: amount!, date: date!, context: managedContext())
                
                saveData()
                incomeDelegate?.saveNewIncome(income: income!)
            } else {
                
                saveData()
                incomeDelegate?.saveIncome(income: income!)
            }
            
            dismiss(animated: true, completion: nil)
        } else {
            
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
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        
        if isPushinto {
            
            fatalError("Exception: todo")
            // navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            dismiss(animated: true, completion: nil)
        } else {
            
            let masterViewController  = getMasterTableViewController()
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            incomeSelected(newIncome: income)
        }
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
        
        if let _ = income {
            
            navigationItem.title = ""
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func saveData() {
        
        income?.setValue(bank, forKey: XYZAccount.bank)
        income?.setValue(accountNr, forKey: XYZAccount.accountNr)
        income?.setValue(amount, forKey: XYZAccount.amount)
        income?.setValue(date, forKey: XYZAccount.lastUpdate)
        
        // setup local notification
        if hasUpdateReminder {
            let notificationCenter = UNUserNotificationCenter.current()
        
            let identifier = "income:\(bank):\(accountNr)"
            
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    
            notificationCenter.removeAllDeliveredNotifications()
            notificationCenter.removeAllPendingNotificationRequests()

            let content = UNMutableNotificationContent()
            content.title = "Income update reminder"
            content.body = "Check income \(bank), \(accountNr) ..."
            content.sound = UNNotificationSound.default()
            //content.categoryIdentifier = "Income"
            
            let units: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
            
            let dateInfo = Calendar.current.dateComponents(units, from: reminddate!)

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)
            
         
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { (error : Error?) in
                if let theError = error {
                    print("-------- notification scheduling error = \(theError.localizedDescription)")
                }
            }
        }
    }

    func loadData() {
        
        bank = ""
        accountNr = ""
        amount = 0.0
        date = Date()
        
        if nil != income {
            
            bank = (income?.value(forKey: XYZAccount.bank) as! String)
            accountNr = (income?.value(forKey: XYZAccount.accountNr) as! String)
            date = (income?.value(forKey: XYZAccount.lastUpdate) as? Date) ?? Date()
            amount = (income?.value(forKey: XYZAccount.amount) as? Double) ?? 0.0
        }
        
        loadDataInTableSectionCell()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPopover(delegate: IncomeDetailDelegate) {
        
        isPopover = true
        incomeDelegate = delegate
    }
    
    // MARK: - data mamipulation
    
    private func loadDataInTableSectionCell() {
        
        tableSectionCellList.removeAll()

        let mainSection = TableSectionCell(identifier: "main",
                                           title: "",
                                           cellList: ["bank", "accountNr"],
                                           data: nil)
        tableSectionCellList.append(mainSection)
        
        let balanceSection = TableSectionCell(identifier: "balance",
                                              title: "",
                                              cellList: ["amount", "date"],
                                              data: nil)
        tableSectionCellList.append(balanceSection)
        
        var updateRemindSection = TableSectionCell(identifier: "remind",
                                                   title: "",
                                                   cellList: ["remind"],
                                                   data: nil)
        
        if hasUpdateReminder {
            updateRemindSection.cellList.append("reminddate")
            updateRemindSection.cellList.append("repeat")
        }
        
        tableSectionCellList.append(updateRemindSection)
        
        if modalEditing && nil != income {
            
            let deleteSection = TableSectionCell(identifier: "delete",
                                                 title: "",
                                                 cellList: ["delete"],
                                                 data: nil)
            tableSectionCellList.append(deleteSection)
        }
        
        let footerSection = TableSectionCell(identifier: "footer",
                                             title: "",
                                             cellList: [String](),
                                             data: nil)
        tableSectionCellList.append(footerSection)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if let _ = tableSectionCellList[section].title {
            
            return ( tableSectionCellList.count - 1 ) == section ? 700 : 35
        } else {
            
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return tableSectionCellList.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableSectionCellList[section].cellList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        
        switch  tableSectionCellList[indexPath.section].cellList[indexPath.row] {
            
            case "bank":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailTextCell", for: indexPath) as? IncomeDetailTextTableViewCell else {
                    fatalError("Exception: incomeDetailTextCell is failed to be created")
                }
                
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "bank"
                textcell.input.text = bank
                textcell.label.text = "Bank"
                
                cell = textcell
            
            case "accountNr":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailTextCell", for: indexPath) as? IncomeDetailTextTableViewCell else {
                    fatalError("Exception: incomeDetailTextCell is failed to be created")
                }
                
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "accountNr"
                textcell.input.text = accountNr
                textcell.label.text = "AccountNr"
                
                cell = textcell
            
            case "amount":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailTextCell", for: indexPath) as? IncomeDetailTextTableViewCell else {
                    fatalError("Exception: incomeDetailTextCell is failed to be created")
                }
                
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.enableMonetaryEditing(true)
                textcell.input.placeholder = formattingCurrencyValue(input: 0.0)
                textcell.input.text = formattingCurrencyValue(input: amount ?? 0.0)
                textcell.label.text = "Balance"
                
                cell = textcell
            
            case "date":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailDateTextCell", for: indexPath) as? IncomeDetailDateTableViewCell else {
                    fatalError("Exception: incomeDetailDateTextCell is failed to be created")
                }
                
                if nil == date {
                    
                    date = Date()
                }
                
                datecell.dateInput.text = formattingDate(date: date ?? Date(), .medium)
                datecell.delegate = self
                datecell.label.text = "Last update"
                datecell.enableEditing = modalEditing
                
                self.datecell = datecell
                cell = datecell
            
            case "datepicker":
                guard let datepickercell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailDatePickerCell", for: indexPath) as? IncomeDetailDatePickerTableViewCell else {
                    fatalError("Exception: incomeDetailDatePickerCell is failed to be created")
                }
                
                datepickercell.setDate(date ?? Date())
                datepickercell.delegate = self
                cell = datepickercell
            
            case "reminddatepicker":
                guard let datepickercell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailDatePickerCell", for: indexPath) as? IncomeDetailDatePickerTableViewCell else {
                    fatalError("Exception: incomeDetailDatePickerCell is failed to be created")
                }
                
                datepickercell.setDate(reminddate ?? Date())
                datepickercell.delegate = self
                cell = datepickercell
            
            case "remind":
                guard let remindOptionCell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailSwitchCell", for: indexPath) as? IncomeDetailSwitchTableViewCell else {
                    fatalError("Exception: incomeDetailSwitchCell is failed to be created")
                }
                
                remindOptionCell.setOption("Remind update on a day", default: hasUpdateReminder)
                remindOptionCell.delegate = self
                cell = remindOptionCell
            
            case "reminddate":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailDateTextCell", for: indexPath) as? IncomeDetailDateTableViewCell else {
                    fatalError("Exception: incomeDetailDateTextCell is failed to be created")
                }
                
                if nil == reminddate {
                    
                    reminddate = Date()
                }
                
                datecell.dateInput.text = formattingDateTime(date: reminddate ?? Date())
                datecell.delegate = self
                datecell.label.text = "Remind date"
                datecell.enableEditing = modalEditing
                dateremindcell = datecell
                
                cell = datecell
            
            case "repeat":
                guard let repeatcell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailSelectionCell", for: indexPath) as? IncomeDetailSelectionTableViewCell else {
                    fatalError("Exception: incomeDetailSelectionCell is failed to be created")
                }
                
                repeatcell.setLabel("Repeat")
                repeatcell.setSelection(repeatselection ?? "Never")
                
                cell = repeatcell
            
            case "delete":
                guard let deletecell = tableView.dequeueReusableCell(withIdentifier: "incomeDetailCommandTextCell", for: indexPath) as? IncomeDetailCommandTableViewCell else {
                    fatalError("Exception: incomeDetailCommandTextCell is failed to be created")
                }
       
                deletecell.delegate = self
                deletecell.setCommand(command: "Delete income")
                cell = deletecell
     
            default:
                fatalError("Exception: \(indexPath.row) is not handled")
        }
        // Configure the cell...
        
        return cell
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
