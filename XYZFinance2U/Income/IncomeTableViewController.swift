//
//  IncomeTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import LocalAuthentication
import os.log
import CoreData

protocol IncomeSelectionDelegate: class {
    
    func incomeSelected(newIncome: XYZAccount?)
    func incomeDeleted(deletedIncome: XYZAccount)
}

class IncomeTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIViewControllerPreviewingDelegate,
    IncomeDetailDelegate {
    
    // MARK: - 3d touch delegate (peek & pop)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        /*
        guard let incomeDetailViewController = self.storyboard?.instantiateViewController(withIdentifier:    "IncomeDetailViewController") as? IncomeDetailViewController else {
            fatalError("Exception: IncomeDetailViewController is expected")
        }
        
        return incomeDetailViewController
         */
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

    }
    
    
    // MARK: - property
    
    var tableSectionCellList = [TableSectionCell]()
    var isPopover = false
    let mainSection = 0
    var incomeList = [XYZAccount]()
    var total: Double {
        
        var sum = 0.0
        
        for account in incomeList {
            
            sum = sum + ( account.value(forKey: XYZAccount.amount) as? Double )! 
        }
        
        return sum
    }
    
    var authenticatedOk = false
    var lockScreenDisplayed = false
    weak var delegate: IncomeSelectionDelegate?
    weak var detailViewController: UIViewController?
    weak var totalCell: IncomeTotalTableViewCell?
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var add: UIBarButtonItem!
    
    // MARK: - IBAction
 
    @IBAction func add(_ sender: UIBarButtonItem) {
        
        guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier:    "IncomeDetailNavigationController") as? UINavigationController else {
            fatalError("Exception: IncomeDetailNavigationController is expected")
        }
        
        guard let incomeDetailTableView = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
            fatalError("Exception: IncomeDetailTableViewController is expected" )
        }
        
        incomeDetailTableView.setPopover(delegate: self)
        isPopover = true
        
        incomeDetailNavigationController.modalPresentationStyle = .popover
        self.present(incomeDetailNavigationController, animated: true, completion: nil)
    }

    @IBAction func unwindToIncomeTableView(sender: UIStoryboardSegue) {
        
        fatalError("Exception: execution should not be reached here")
        
        /*
         guard let incomeDetail = sender.source as? IncomeDetailViewController, let income = incomeDetail.account else
         {
         return
         }
         
         if let selectedIndexPath = tableView.indexPathForSelectedRow
         {
         tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
         // tableView.reloadData()
         }
         else
         {
         income.setValue(incomeList.count, forKey: XYZAccount.sequenceNr)
         incomeList.append(income)
         tableView.reloadData()
         }
         
         saveAccounts()
         */
    }
    
    // MARK: - function
    
    func totalOfSection(section: Int) -> Double {
    
        var total = 0.0;
        let sectionIncomeList = tableSectionCellList[section].data as? [XYZAccount]
        
        for income in sectionIncomeList! {
        
            total = total + ((income.value(forKey: XYZAccount.amount) as? Double) ?? 0.0 )
        }
        
        return total
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveNewIncome(income: XYZAccount) {
        
        income.setValue(incomeList.count, forKey: XYZAccount.sequenceNr)
        incomeList.append(income)
        reloadData()
    }
    
    func incomeIndex(of income: XYZAccount) -> IndexPath? {
        
        let incomeListStored = tableSectionCellList[mainSection].data as? [XYZAccount]
        
        return IndexPath(row: (incomeListStored?.index(of: income))!, section: mainSection)
    }
    
    func saveIncome(income: XYZAccount) {
        
        let selectedIndexPath = incomeIndex(of: income)
        tableView.reloadRows(at: [selectedIndexPath!], with: .automatic)
        saveAccounts()
    }
    
    func deleteIncome(income: XYZAccount) {
        
        let aContext = managedContext()
        let index = incomeList.index(of: income)
        let oldIncome = incomeList.remove(at: index!)
        aContext?.delete(oldIncome)
        
        self.delegate?.incomeDeleted(deletedIncome: oldIncome)
        reloadData()
    }
    
    private func loadDataInTableSectionCell() {
        
        var currencyList = [String]()
        
        for income in incomeList {
            
            let currency = income.value(forKey: XYZAccount.currencyCode) as? String ?? Locale.current.currencyCode!
            
            if let _ = currencyList.index(of: currency) {
                
            } else {
                
                currencyList.append(currency)
            }
        }
        
        if currencyList.isEmpty {
            
            currencyList.append(Locale.current.currencyCode!)
        }
        
        tableSectionCellList.removeAll()
     
        for currency in currencyList {
            
            var sectionIncomeList = [XYZAccount]()
            
            for income in incomeList {
                
                if let setCurrency = income.value(forKey: XYZAccount.currencyCode) as? String {
                    
                    if setCurrency == currency {
                        
                        sectionIncomeList.append(income)
                    }
                } else if currency == Locale.current.currencyCode {
                    
                    sectionIncomeList.append(income)
                }
            }
            
            let mainSection = TableSectionCell(identifier: "main", title: currency, cellList: [], data: sectionIncomeList)
            tableSectionCellList.append(mainSection)
            
            let summarySection = TableSectionCell(identifier: "summary", title: nil, cellList: ["sum"], data: nil)
            tableSectionCellList.append(summarySection)
        }
        
        for section in tableSectionCellList {
            
            switch section.identifier {
                
                case "main":
                    let incomeListStored = section.data as? [XYZAccount]
                    for income in incomeListStored! {
                        
                        _ = income.value(forKey: XYZAccount.bank)
                    }
                
                case "summary":
                    break;
                
                default:
                    fatalError("Exception: execution should not be reached here")
            }
        }
    }
    
    func reloadData() {
        
        saveAccounts()
        loadDataInTableSectionCell()
        tableView.reloadData()
    }
    
    private func saveAccounts() {
        
        let aContext = managedContext()
        
        do {
            
            try aContext?.save()
        } catch let nserror as NSError {
            
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    private func loadAccounts() -> [XYZAccount]? {
        
        var output: [XYZAccount]?
        
        let aContext = managedContext()
        let fetchRequest = NSFetchRequest<XYZAccount>(entityName: "XYZAccount")

        do {
            
            output = try aContext?.fetch(fetchRequest)
            
            output = output?.sorted() {
                (acc1, acc2) in
                
                return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
            }
        } catch let error as NSError {
            
            print("Could not fetch. \(error), \(error.userInfo)")
        }

        return output
    }
    
    func authenticate() {
        
        incomeList = []
        reloadData()
        
        // authentication validation before doing other things
        let laContext = LAContext()
        var authError: NSError?
        authenticatedOk = false
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            
            delegate.orientation = .portrait
        }
        
        if #available(iOS 8.0, macOS 10.12.1, *) {
            
            if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                
                if !lockScreenDisplayed {
                    
                    guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                        fatalError("Exception: MainSplitViewController is expected")
                    }
                    
                    if nil == mainSplitView.popOverNavigatorController {

                        guard let lockScreenView = self.storyboard?.instantiateViewController(withIdentifier: "lockScreenView") as? LockScreenViewController else {
                            fatalError("Exception: lockScreenView is expected")
                        }
                        
                        lockScreenView.mainTableViewController = self
                        let lockScreenViewNavigatorController = UINavigationController(rootViewController: lockScreenView)
                        
                        if let delegate = UIApplication.shared.delegate as? AppDelegate {
                            
                            lockScreenDisplayed = true
                
                            // NOTE: to avoid warning "Unbalanced calls to begin/end appearance transitions for"
                            OperationQueue.main.addOperation {
                                
                                delegate.window?.rootViewController?.present(lockScreenViewNavigatorController, animated: false, completion: nil)
                            }
                        }
                    }
                }
                
                laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                         localizedReason: "Authenticate to use the app" )
                { (success, error) in
                    self.authenticatedOk = success
                    
                    if self.authenticatedOk {
                        
                        OperationQueue.main.addOperation {
                            
                            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                                
                                delegate.orientation = .all
                            }
                            
                            if self.lockScreenDisplayed {
                                
                                self.dismiss(animated: false, completion: nil)
                                self.lockScreenDisplayed = false
                            }
                            
                            if let accounts = self.loadAccounts() {
                                
                                self.incomeList += accounts
                            }
                        
                            self.reloadData()
                            //self.navigationItem.leftBarButtonItem?.isEnabled = true
                            //self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                    } else {
                        
                        print("authentication fail = \(String(describing: error))")
                        //self.navigationItem.leftBarButtonItem?.isEnabled = false
                        //self.navigationItem.rightBarButtonItem?.isEnabled = false
                        
                        if !self.lockScreenDisplayed {
                            
                            self.dismiss(animated: false, completion: nil)

                            guard let lockScreenView = self.storyboard?.instantiateViewController(withIdentifier: "lockScreenView") as? LockScreenViewController else {
                                fatalError("Exception: lockScreenView is expected")
                            }
                            
                            lockScreenView.mainTableViewController = self
                            let lockScreenViewNavigatorController = UINavigationController(rootViewController: lockScreenView)
                            
                            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                                
                                self.lockScreenDisplayed = true
                                
                                // NOTE: to avoid warning "Unbalanced calls to begin/end appearance transitions for"
                                OperationQueue.main.addOperation {
                                    
                                    delegate.window?.rootViewController?.present(lockScreenViewNavigatorController, animated: false, completion: nil)
                                }
                            }
                        }
                    }
                }
            } else {
                
                self.authenticatedOk = true
                //self.navigationController?.popViewController(animated: true)
                print("no auth support")
                
                if let accounts = self.loadAccounts() {
                    
                    self.incomeList += accounts
                }
                    
                self.reloadData()
                //self.navigationItem.leftBarButtonItem?.isEnabled = true
                //self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        } else {
            
            self.authenticatedOk = true
            //self.navigationItem.leftBarButtonItem?.isEnabled = false
            //self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        authenticate()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        guard let split = self.parent?.parent?.parent as? UISplitViewController else {
            fatalError("Exception: locate split view")
        }
        
        if split.isCollapsed {
            
            self.navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
        }
        
        if split.viewControllers.count > 1 {
            
            guard let _ = split.viewControllers.last as? UINavigationController else {
                fatalError( "Exception: navigation controller is expected" )
            }
        }
        
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        
        loadDataInTableSectionCell()

        // Check for force touch feature, and add force touch/previewing capability.
        if traitCollection.forceTouchCapability == .available {
            /*
             Register for `UIViewControllerPreviewingDelegate` to enable
             "Peek" and "Pop".
             (see: MasterViewController+UIViewControllerPreviewing.swift)
             
             The view controller will be automatically unregistered when it is
             deallocated.
             */
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    // MARK: - split view delegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        for row in 0..<incomeList.count {
            
            let indexPath = IndexPath(row: row, section: 0)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        self.delegate = nil
        secondaryViewController.navigationItem.title = "New"
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let incomeDetailTableViewController = navigationController.viewControllers.first as? IncomeDetailTableViewController {
                
                incomeDetailTableViewController.incomeDelegate = self
                incomeDetailTableViewController.isPushinto = true
                
                if !isPopover && incomeDetailTableViewController.modalEditing {
                    
                    incomeDetailTableViewController.isPushinto = false
                    incomeDetailTableViewController.isPopover = true
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
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        
    }

    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        
        return false
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier:    "IncomeDetailNavigationController") as? UINavigationController else {
            fatalError("Exception: IncomeDetailNavigationController is expected")
        }
        
        guard let incomeDetailTableViewController = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
            fatalError("Exception: ExpenseDetailTableViewController is expected")
        }
        
        incomeDetailTableViewController.navigationItem.title = ""
        self.delegate = incomeDetailTableViewController
        
        return incomeDetailNavigationController
    }
    
    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        
        return nil
    }
        


    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if tableSectionCellList[indexPath.section].identifier == "main" {
        
            return indexPath
        } else {
            
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let split = self.parent?.parent?.parent as? UISplitViewController else {
            fatalError("Exception: locate split view")
        }
        
        if split.isCollapsed  {
            
            guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier:    "IncomeDetailNavigationController") as? UINavigationController else {
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let incomeTableView = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
                fatalError("Exception: IncomeDetailTableViewController is expected" )
            }
            
            incomeTableView.setPopover(delegate: self)
            incomeTableView.income = incomeList[indexPath.row]
            incomeDetailNavigationController.modalPresentationStyle = .popover
            self.present(incomeDetailNavigationController, animated: true, completion: nil)
            
            guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                fatalError("Exception: MainSplitViewController is expected")
            }
            
            mainSplitView.popOverNavigatorController = incomeDetailNavigationController
        } else {
            
            guard let detailTableViewController = delegate as? IncomeDetailTableViewController else {
                fatalError("Exception: IncomeDetailTableViewController is expedted" )
            }
            
            detailTableViewController.incomeDelegate = self
            delegate?.incomeSelected(newIncome: incomeList[indexPath.row])
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return tableSectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var nrOfRows = 0
        
        switch tableSectionCellList[section].identifier {
            
            case "main":
                let incomeListStored = tableSectionCellList[section].data as? [XYZAccount]
                nrOfRows = (incomeListStored?.count)!
            
            default:
                let incomeListStored = tableSectionCellList[0].data as? [XYZAccount]
                nrOfRows = (incomeListStored?.count)! > 0 ? 1 : 0
        }
        
        return nrOfRows
        
        //return incomeList.count + ( incomeList.count > 0 ? 1 : 0 )
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        var cell: UITableViewCell?
        
        let identifier = tableSectionCellList[indexPath.section].identifier
       
        switch identifier {
            
            case "main":
                guard let incomecell = tableView.dequeueReusableCell(withIdentifier: "IncomeTableViewCell", for: indexPath) as? IncomeTableViewCell else {
                    fatalError("error on creating cell")
                }

                let incomeListStored = tableSectionCellList[indexPath.section].data as? [XYZAccount]
                let account = incomeListStored![indexPath.row] //incomeList[indexPath.row]
                let currencyCode = account.value(forKey: XYZAccount.currencyCode) as? String ?? Locale.current.currencyCode!
                
                incomecell.bank.text = account.value(forKey: XYZAccount.bank) as? String
                incomecell.account.text = account.value(forKey: XYZAccount.accountNr ) as? String
                incomecell.amount.text = formattingCurrencyValue(input: (account.value(forKey: XYZAccount.amount) as? Double)!, currencyCode)
                incomecell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                cell = incomecell
       
            case "summary":
                guard let newTotalcell = tableView.dequeueReusableCell(withIdentifier: "IncomeTotalTableViewCell", for: indexPath) as? IncomeTotalTableViewCell else {
                    fatalError("error on creating total cell")
                }

                totalCell = newTotalcell
                totalCell?.setAmount(amount: totalOfSection(section: indexPath.section - 1), code: tableSectionCellList[indexPath.section - 1].title!)
                cell = newTotalcell
            
            default:
                fatalError("Exception: section identifier \(identifier) not be handled" )
        }
 
        ///totalCell?.setAmount(amount: total)
        
        return cell!
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        super.setEditing(editing, animated: animated)
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        
        return tableSectionCellList[indexPath.section].identifier == "main" //indexPath.row < incomeList.count
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Delete the row from the data source
            let sectionIncomeList = tableSectionCellList[indexPath.section].data as? [XYZAccount]
            let incomeToBeDeleted = sectionIncomeList![indexPath.row]
            
            let aContext = managedContext()
            let oldIncome = incomeList.remove(at: incomeList.index(of: incomeToBeDeleted)!)   //incomeList.remove(at: indexPath.row)
            aContext?.delete(oldIncome)
            
            self.delegate?.incomeDeleted(deletedIncome: oldIncome)
            reloadData()
        } else if editingStyle == .insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        saveAccounts()
        
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    // Override to support rearranging the table view.

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        return tableSectionCellList[indexPath.section].identifier == "main"
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var indexPath = proposedDestinationIndexPath
        
        if tableSectionCellList[proposedDestinationIndexPath.section].identifier != "main" {
            
            indexPath = sourceIndexPath
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        incomeList.insert(incomeList.remove(at: fromIndexPath.row), at: to.row)

        for (index, account) in incomeList.enumerated() {
            
            account.setValue(index, forKey: XYZAccount.sequenceNr)
        }
        
        saveAccounts()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? "" {
            
            case "AddIncomeDetail":
                fatalError("Exception: AddIncomeDetail is not longer supported")

            case "ShowIncomeDetail":
                guard let incomeDetailView = segue.destination as? IncomeDetailViewController else {
                    fatalError("Unexpected error on casting segue.destination for prepare from table view controller")
                }
                
                if let accountDetail = sender as? IncomeTableViewCell {
                    
                    guard let indexPath = tableView.indexPath(for: accountDetail) else {
                        fatalError("Unexpeted error in getting indexPath for prepare from table view controller");
                    }

                    let account = incomeList[indexPath.row]
                    incomeDetailView.account = account
                } else if let addButtonSender = sender as? UIBarButtonItem, add === addButtonSender {
                    
                    os_log("Adding a new income", log: OSLog.default, type: .debug)
                } else {
                    
                    fatalError("Exception: unknown sender")
                }

            default:
                fatalError("Unexpected error on default for prepare from table view controller")
        }
    }
}
