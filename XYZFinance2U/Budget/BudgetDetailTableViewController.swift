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
    BudgetDetailTextTableViewCellDelegate {
    
    func textDidEndEditing(_ sender: BudgetDetailTextTableViewCell) {
        
    }
    
    func textDidBeginEditing(_ sender: BudgetDetailTextTableViewCell) {
    
    }
    
    
    func budgetSelected(newBudget: XYZBudget?) {

    }
    
    func budgetDeleted(deletedBudget: XYZBudget) {
    
    }

    var budgetDelegate: BudgetDetailDelegate?
    var isPopover: Bool = false
    var isPushinto: Bool = false
    var modalEditing = false
    var budget: XYZBudget?
    var sectinList = [TableSectionCell]()
    var budgetType = ""
    var amount = 0.0
    var currencyCode = Locale.current.currencyCode
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        
        if isPushinto {
            
            fatalError("Exception: todo")
        } else if isPopover {
            
            dismiss(animated: true, completion: nil)
        } else {
            
            /*
            let masterViewController  = getMasterTableViewController()
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            incomeSelected(newIncome: income)
            */
        }
    }
    
    @IBAction func save(_ sender: Any) {
        
        /*
        if isPushinto {
            
            fatalError("Exception: todo")
            
            //saveData()
            //expenseDelegate?.saveExpense(expense: expense!)
            //navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            if nil == income {
                
                income = XYZAccount(id: nil, sequenceNr: 0, bank: bank, accountNr: accountNr, amount: amount!, date: date!, context: managedContext())
                
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
        }*/
    }
    
    func loadDataIntoSectionList() {
    
        sectinList = [TableSectionCell]()
        
        let mainSection = TableSectionCell(identifier: "main", title: nil, cellList: ["budget", "amount"], data: nil)
        sectinList.append(mainSection)
    }
    
    func loadData() {
        
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
        
        if let _ = budget {
            
            navigationItem.title = "Budget"
        }

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
        
        return sectinList[section].title
    }

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectinList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return sectinList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sectinList[indexPath.section].cellList[indexPath.row] {
        
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
            
            default:
                fatalError("Exception: \(sectinList[indexPath.section].cellList[indexPath.row]) not handle")
        }
        
        return cell
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
