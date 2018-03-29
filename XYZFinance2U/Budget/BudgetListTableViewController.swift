//
//  BudgetListTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 3/27/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class BudgetListTableViewController: UITableViewController {
    
    // MARK: - type
    struct TableCell {
        
        var length: String
        var start: Date
        var until: Date
        var amount: Double
        var spentAmount: Double
        var expenseList: [XYZExpense]
    }
    
    // MARK: - property
    var budget: XYZBudget?
    var cellList = [TableCell]()
    
    // MARK: - IBActions
    
    @IBAction func backAction(_ sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientation = UIInterfaceOrientationMask.all
        
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - functions
    
    func loadData() {
        
        loadDataIntoSection()
    }
    
    func loadDataIntoSection() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let expenseList = (appDelegate?.expenseList)!
            
        navigationItem.title = budget?.value(forKey: XYZBudget.name) as? String ?? ""
        cellList = [TableCell]()
        
        if let _ = budget {
            
            let (count, lengths, dates, amounts) = (budget?.getAllBudgetDateAmount())!
            
            for index in 0..<count {
            
                let length = XYZBudget.Length(rawValue: lengths[index])
                let amount = amounts[index]
                var start = dates[index]
                var untilDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                if index < (count - 1) {
                
                    untilDate = min(untilDate!, dates[index + 1])
                }
                
                if length == XYZBudget.Length.none {
                    
                } else {
                    
                    while start < untilDate! {
                        
                        var end = start
                        
                        switch length! {
                            
                        case .none:
                            fatalError("Exception: .none is not expected")
                        
                        case .daily:
                            end = Calendar.current.date(byAdding: .day, value: 1, to: end)!
                            break
                            
                        case .weekly:
                            end = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: end)!
                            break
                            
                        case .biweekly:
                            end = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: end)!
                            break
                        
                        case .monthly:
                            end = Calendar.current.date(byAdding: .month, value: 1, to: end)!
                            break
                            
                        case .halfyearly:
                            end = Calendar.current.date(byAdding: .month, value: 6, to: end)!
                            break
                            
                        case .yearly:
                            end = Calendar.current.date(byAdding: .year, value: 1, to: end)!
                            break
                        }
                    
                        end = min(end, untilDate!)
                        let expenseLastDate = Calendar.current.date(byAdding: .day, value: -1, to: end)!
                        let filterExpenseList = expenseList.filter { (expense) -> Bool in
                            
                            let occurenceDates = expense.getOccurenceDates(until: expenseLastDate)
                            
                            return !(occurenceDates.filter({ (date) -> Bool in
                                
                                return date >= start && date <= expenseLastDate
                            })).isEmpty
                        }
                        
                        let tableCell = TableCell(length: "\(length!)", start: start, until: expenseLastDate, amount: amount, spentAmount: 0.0, expenseList: filterExpenseList)
                        
                        cellList.append(tableCell)
                        
                        start = end
                    }
                }
            }
        }
    }
    
    private func addBackButton() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal) // Image can be downloaded from here below link
        backButton.setTitle(" Back", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationItem.largeTitleDisplayMode = .never
        
        addBackButton()
        
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "budgetTableCell", for: indexPath) as? BudgetTableViewCell else {
            
            fatalError("Exception: BudgetTableViewCell is expected")
        }
        
        var spentAmount = 0.0;
        let periodExpenseList = cellList[indexPath.row].expenseList
        
        for expense in periodExpenseList {
            
            let amount = expense.value(forKey: XYZBudget.amount) as? Double ?? 0.0
            spentAmount = spentAmount + amount
        }
        
        let balanceAmount = cellList[indexPath.row].amount - spentAmount
        
        cell.name.text = cellList[indexPath.row].length
        cell.length.text = "from: \(formattingDate(date: cellList[indexPath.row].start, style: .short))"
        cell.amount.text = formattingCurrencyValue(input: cellList[indexPath.row].amount,
                                                   code: budget?.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode)
        cell.balanceAmount.text = formattingCurrencyValue(input: balanceAmount,
                                                          code: budget?.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode)
        if balanceAmount < 0.0 {
            
            cell.balanceAmount.textColor = UIColor.red
        } else {
            
            cell.balanceAmount.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        

        
        //self.present(budgetExpensesTableViewController, animated: true, completion: {})
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
