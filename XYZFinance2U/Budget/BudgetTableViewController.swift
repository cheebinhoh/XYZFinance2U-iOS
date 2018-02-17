//
//  BudgetTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/12/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol BudgetSelectionDelegate: class {
    
    func budgetSelected(newBudget: XYZBudget?)
    func budgetDeleted(deletedBudget: XYZBudget)
}

class BudgetTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    BudgetDetailDelegate {
    
    // MARK: budget detail protocol
    func saveNewBudget(budget: XYZBudget) {

        if let currencyCode = budget.value(forKey: XYZBudget.currency) as? String, currencyCodes.contains(currencyCode) {
         
            for section in sectionList {
                
                if section.identifier == currencyCode {
                    
                    let setionBudgetList = section.data as? [XYZBudget]
                    
                    budget.setValue(setionBudgetList?.count, forKey: XYZBudget.sequenceNr)
                    
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
    }
    
    func saveBudget(budget: XYZBudget) {

    }
    
    func deleteBudget(budget: XYZBudget) {

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
        
        //incomeDetailTableView.currencyCodes = currencyCodes
        
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
        
        /*
        for budget in budgetList {
            
            let currency = budget.value(forKey: XYZBudget.currency) as? String ?? Locale.current.currencyCode
        
            if !currencyCodes.contains(currency!) {
                
                if !sectionList.isEmpty {
                    
                    var sectionBudgetList = sectionList[sectionList.count - 1].data as? [XYZBudget]
                    
                    sectionBudgetList?.sort(by: { (bu1, bu2) -> Bool in
                        
                        let seq1 = bu1.value(forKey: XYZBudget.sequenceNr) as? Int
                        let seq2 = bu2.value(forKey: XYZBudget.sequenceNr) as? Int
                        
                        return seq1! > seq2!
                    })
                    
                    sectionList[sectionList.count - 1].data = sectionBudgetList
                }
                
                let newSection = TableSectionCell(identifier: currency!, title: currency, cellList: [], data: [XYZBudget]())
                sectionList.append(newSection)
                
                currencyCodes.append(currency!)
            }
            
            var sectionBudgetList = sectionList[sectionList.count - 1].data as? [XYZBudget]
            sectionBudgetList?.append(budget)
            sectionList[sectionList.count - 1].data = sectionBudgetList
        }
        
        if !sectionList.isEmpty {
            
            var sectionBudgetList = sectionList[sectionList.count - 1].data as? [XYZBudget]
            
            sectionBudgetList?.sort(by: { (bu1, bu2) -> Bool in
                
                let seq1 = bu1.value(forKey: XYZBudget.sequenceNr) as? Int
                let seq2 = bu2.value(forKey: XYZBudget.sequenceNr) as? Int
                
                return seq1! >  seq2!
            })
            
            sectionList[sectionList.count - 1].data = sectionBudgetList
        }
        */
        /*
        print("-------- # of sections = \(sectionList.count)")
        for section in sectionList {
            
            let currency = section.title
            let sectionBudgetList = section.data as? [XYZBudget]
            
            print("-------- section = \(String(describing: currency))")
            for budget in sectionBudgetList! {
            
                let name = budget.value(forKey: XYZBudget.name)
                let amount = budget.value(forKey: XYZBudget.amount)
                let start = budget.value(forKey: XYZBudget.start)
                let length = XYZBudget.Length(rawValue: budget.value(forKey: XYZBudget.length) as? String ?? "")
                
                
                print("-------- name = \(String(describing: name)), amount = \(String(describing: amount)), length = \(String(describing: length)), start = \(String(describing: start))")
            }
        }
        

            _ = XYZBudget(id: nil, name: "grocery", amount: 600.0, currency: Locale.current.currencyCode!, length: .monthly, start: Date(),  context: managedContext())
            
            _ = XYZBudget(id: nil, name: "xfinity", amount: 120.0, currency: Locale.current.currencyCode!, length: .monthly, start: Date(), context: managedContext())
            
            _ = XYZBudget(id: nil, name: "insurance", amount: 1500.0, currency: "MYR", length: .monthly, start: Date(), context: managedContext())
        
            saveManageContext() */
 
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
    

    // MARK: - Table view data source

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
        
        cell.amount.text = formattingCurrencyValue(input: amount!, code: currency!)
        cell.name.text = name

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
    
    func softdeletebudget(_ budget: XYZBudget) {
        
        let indexPath = self.indexPath(budget)
        var sectionBudgetList = sectionList[(indexPath?.section)!].data as? [XYZBudget]
        
        sectionBudgetList?.remove(at: (indexPath?.row)!)
        sectionList[(indexPath?.section)!].data = sectionBudgetList
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.budgetList = loadBudgetsFromSection()
        
        let aContext = managedContext()
        aContext?.delete(budget)
        
        saveManageContext()
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
            
            //tableView.deleteRows(at: [indexPath], with: .fade)
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
                
                budget.setValue(index, forKey: XYZBudget.sequenceNr)
            }
            
            sectionList[fromIndexPath.section].data = sectionBudgetList
            
            saveManageContext()
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
        
        /*
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for row in 0..<(appDelegate?.incomeList)!.count {
            
            let indexPath = IndexPath(row: row, section: 0)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }*/
        
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
