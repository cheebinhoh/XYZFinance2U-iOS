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
import CloudKit
import UserNotifications
import NotificationCenter

protocol IncomeSelectionDelegate: class {
    
    func incomeSelected(newIncome: XYZAccount?)
    func incomeDeleted(deletedIncome: XYZAccount)
}

class IncomeTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIViewControllerPreviewingDelegate,
    IncomeDetailDelegate {
    
    // MARK: - 3d touch delegate (peek & pop)
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
    }
        
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let indexPath = tableView.indexPathForRow(at: location)
        print("-------- indexpath section = \(String(describing: indexPath?.section)), row = \(String(describing: indexPath?.row))")
        
        let cell = tableView.cellForRow(at: indexPath!)
        
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "IncomeDetailViewController") as? IncomeDetailViewController else  {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }
        
        guard let sectionIncomeList = tableSectionCellList[(indexPath?.section)!].data as? [XYZAccount] else {
            
            fatalError("Exception: [XYZAccount] is expected")
        }
        
        viewController.account = sectionIncomeList[(indexPath?.row)!]
        viewController.preferredContentSize = CGSize(width: 0.0, height: 250)
        previewingContext.sourceRect = (cell?.frame)!
        
        return viewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {

    }
    
    
    // MARK: - property
    
    var tableSectionCellList = [TableSectionCell]()
    var isPopover = false
    let mainSection = 0

    var total: Double {
        
        var sum = 0.0
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for account in (appDelegate?.incomeList)! {
            
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
        
        guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "IncomeDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating IncomeDetailNavigationController")
        }
        
        guard let incomeDetailTableView = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
            
            fatalError("Exception: eror on casting first view controller to IncomeDetailTableViewController" )
        }
        
        guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
            
            fatalError("Exception: MainSplitViewController is expected")
        }
        
        mainSplitView.popOverNavigatorController = incomeDetailNavigationController
        
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
    
    func getTotal() -> Double {
        
        var sum = 0.0
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for account in (appDelegate?.incomeList)! {
            
            sum = sum + ( account.value(forKey: XYZAccount.amount) as? Double )!
        }
        
        return sum
    }
    
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

        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        
        for (index, section) in tableSectionCellList.enumerated() {
            
            if currencyCode == section.title {
                
                guard var sectionIncomeList = section.data as? [XYZAccount] else {
                    
                    fatalError("Exception: [XYZAccount] is expected")
                }
                
                sectionIncomeList.append(income)
                
                tableSectionCellList[index].data = sectionIncomeList
                break
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        income.setValue((appDelegate?.incomeList)!.count, forKey: XYZAccount.sequenceNr)
        appDelegate?.incomeList.append(income)
        
        reloadData()
    }
    
    func incomeIndex(of income: XYZAccount) -> IndexPath? {
        
        for (sectionIndex, section) in tableSectionCellList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, incomeStored) in sectionIncomeList.enumerated() {
                    
                    if income == incomeStored {
                        
                        return IndexPath(row: rowIndex, section: sectionIndex)
                    }
                }
            }
        }
        
        return nil
    }
    
    func saveIncome(income: XYZAccount) {
        
        let selectedIndexPath = incomeIndex(of: income)
        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        
        if tableSectionCellList[(selectedIndexPath?.section)!].title == currencyCode! {
    
            let summaryIndex = IndexPath(row:0, section: (selectedIndexPath?.section)! + 1)
            tableView.reloadRows(at: [selectedIndexPath!, summaryIndex], with: .automatic)
            
            saveAccounts()
        } else {
        
            reloadData()
            saveAccounts()
        }
    }
    
    func softDeleteIncome(income: XYZAccount) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        guard let zone = iCloudZone(of: ckrecordzone, (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        let recordName = income.value(forKey: XYZAccount.recordId) as? String
        deleteRecordLiset.append(recordName!)
        
        let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
        zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
    }
    
    func deleteIncome(income: XYZAccount) {

        softDeleteIncome(income: income)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let aContext = managedContext()
        let index = appDelegate?.incomeList.index(of: income)
        let oldIncome = appDelegate?.incomeList.remove(at: index!)
        aContext?.delete(oldIncome!)
        
        self.delegate?.incomeDeleted(deletedIncome: oldIncome!)
        reloadData()
    }
    
    private func loadDataInTableSectionCell() {
        
        var currencyList = [String]()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        for income in (appDelegate?.incomeList)! {
            
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
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            for income in (appDelegate?.incomeList)! {
                
                if let setCurrency = income.value(forKey: XYZAccount.currencyCode) as? String {
                    
                    if setCurrency == currency {
                        
                        sectionIncomeList.append(income)
                    }
                } else if currency == Locale.current.currencyCode {
                    
                    sectionIncomeList.append(income)
                }
            }
            
            if !sectionIncomeList.isEmpty {
                
                sectionIncomeList = sectionIncomeList.sorted() {
                    
                    (acc1, acc2) in
                    
                    return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
                }
                
                let mainSection = TableSectionCell(identifier: "main", title: currency, cellList: [], data: sectionIncomeList)
                tableSectionCellList.append(mainSection)
                
                let summarySection = TableSectionCell(identifier: "summary", title: nil, cellList: ["sum"], data: nil)
                tableSectionCellList.append(summarySection)
            }
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
                    fatalError("Exception: execution should not be reached here, case = \(section.identifier)")
            }
        }
    }
    
    func reloadData() {
        
        saveAccounts()
        loadDataInTableSectionCell()
        //saveAccounts()

        tableView.reloadData()
    }
    
    func registerNotification(income: XYZAccount) {
        
        let notificationCenter = UNUserNotificationCenter.current()
        let identifier = income.value(forKey: XYZAccount.recordId) as? String
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier!])
        notificationCenter.removeAllDeliveredNotifications()
    
        let bank = income.value(forKey: XYZAccount.bank) as? String
        let accountNr = income.value(forKey: XYZAccount.accountNr) as? String
        let repeatAction = income.value(forKey: XYZAccount.repeatAction) as? String
        let reminddate = income.value(forKey: XYZAccount.repeatDate) as? Date
        
        // setup local notification
        if nil != reminddate {
            
            let content = UNMutableNotificationContent()
            content.title = "Income update reminder"
            content.body = "Check income \(String(describing: bank!)), \(String(describing: accountNr!)) ..."
            content.sound = UNNotificationSound.default()
            
            var units: Set<Calendar.Component> = [ .hour, .minute]
            switch repeatAction ?? "Never" {
                
            case "Never":
                units.insert(.year)
                units.insert(.month)
                units.insert(.day)
                units.insert(.hour)
                units.insert(.minute)
                
            case "Every Month":
                units.insert(.month)
                units.insert(.day)
                units.insert(.hour)
                units.insert(.minute)
                
            case "Every Week":
                units.insert(.weekday)
                units.insert(.hour)
                units.insert(.minute)
                
            case "Every Day":
                units.insert(.hour)
                units.insert(.minute)
                
            case "Every Hour":
                units.insert(.minute)
                
            default:
                fatalError("Exception: \(repeatAction!) is not expected")
            }
            
            let dateInfo = Calendar.current.dateComponents(units, from: reminddate!)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: ( repeatAction ?? "Never" ) != "Never" )
            
            let request = UNNotificationRequest(identifier: identifier!, content: content, trigger: trigger)
            
            notificationCenter.add(request) { (error : Error?) in
                
                if let theError = error {
                    
                    print("-------- notification scheduling error = \(theError.localizedDescription)")
                }
            }
        }
    }
    
    private func saveAccounts() {
        
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
        
        // preprocessing before saving it
        for (sectionIndex, section) in tableSectionCellList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, income) in sectionIncomeList.enumerated() {
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex
                    income.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        /*
        for account in (appDelegate?.incomeList)! {
            
            let bank = account.value(forKey: XYZAccount.bank) as? String ?? ""
            let accountNr = account.value(forKey: XYZAccount.accountNr) as? String ?? ""
            let sequenceNr = account.value(forKey: XYZAccount.sequenceNr) as? Int ?? 0
            
            let recordId = "\(bank):\(accountNr):\(sequenceNr)"
            account.setValue(recordId, forKey: XYZAccount.recordId)
        }
         */
        
        saveManageContext()

        for income in (appDelegate?.incomeList)! {
            
            registerNotification(income: income)
        }
        
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        let zone = iCloudZone(of: ckrecordzone, (appDelegate?.iCloudZones)!)
        zone?.data = appDelegate?.incomeList
        
        //print("-------- after save, petch and update icloud")
        fetchAndUpdateiCloud([ckrecordzone], (appDelegate?.iCloudZones)!, {
            
            //print("-------- done fetch and update icloud")
        })

        /*
        for account in incomeList {
            
            account.saveToiCloud()
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: XYZAccount.type, predicate: predicate)
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        database.perform(query, inZoneWith: nil) { (records, error) in
        
            if nil != error {
                
                print("------- error on query = \(String(describing: error))")
            } else {
                
                var recordIDsToBeDeleted = Set<CKRecordID>()
                
                for record in records! {
                   
                    recordIDsToBeDeleted.insert( record.recordID )
                }
                
                for income in self.incomeList {
                    
                    if let recordId = income.value(forKey: XYZAccount.recordId) as? String {
                    
                        let ckrecordId = CKRecordID(recordName: recordId)

                        recordIDsToBeDeleted.remove(ckrecordId)
                    }
                }
                
                let recordIDsToBeDeletedArray = Array<CKRecordID>( recordIDsToBeDeleted )
                let modifyOperation = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: recordIDsToBeDeletedArray)
                modifyOperation.savePolicy = .ifServerRecordUnchanged
                modifyOperation.modifyRecordsCompletionBlock = { ( saveRecords, deleteRecords, error ) in
                    
                    if nil != error {
                        
                        print("-------- error on saving to icloud \(String(describing: error))")
                    } else {
                        
                        print("-------- delete done")
                    }
                }

                database.add(modifyOperation)
            }
        }
 
        */
    }

    /*
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
     */
    
    func validateiCloud() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        CKContainer.default().accountStatus { (status, error) in
            
            if status == CKAccountStatus.noAccount {
                
                appDelegate?.iCloudEnable = false
                let alert = UIAlertController(title: "Sign in to icloud",
                                              message: "Sign in to your iCloud account to write records", preferredStyle: UIAlertControllerStyle.alert )
                self.present(alert, animated: false, completion: nil)
            } else {
                
    
                appDelegate?.iCloudEnable = true
            }
        }
    }
    
    func lockout() {
        
        guard let lockScreenView = self.storyboard?.instantiateViewController(withIdentifier: "lockScreenView") as? LockScreenViewController else {
            
            fatalError("Exception: error on instantiating lockScreenView")
        }
        
        lockScreenView.mainTableViewController = self
        let lockScreenViewNavigatorController = UINavigationController(rootViewController: lockScreenView)
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            
            lockScreenDisplayed = true
            
            // NOTE: to avoid warning "Unbalanced calls to begin/end appearance transitions for"
            DispatchQueue.main.async {
                
                appDelegate.window?.rootViewController?.present(lockScreenViewNavigatorController, animated: false, completion: nil)
            }
        }
    }
    
    func authenticate() {
        
        // authentication validation before doing other things
        let laContext = LAContext()
        var authError: NSError?
        authenticatedOk = false
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            
            appDelegate.orientation = .portrait
        }
        
        if #available(iOS 8.0, macOS 10.12.1, *) {
            
            if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                
                if !lockScreenDisplayed {
                    
                    guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                        
                        fatalError("Exception: MainSplitViewController is expected")
                    }
                    
                    if nil == mainSplitView.popOverNavigatorController {
                        
                        lockout()
                    }
                }
            
                laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                         localizedReason: "Authenticate to use the app" )
                { (success, error) in
                    self.authenticatedOk = success
                    
                    if self.authenticatedOk {
                        
                        //OperationQueue.main.addOperation
                        DispatchQueue.main.async {
                            
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                
                                appDelegate.orientation = .all
                            }
                            
                            if self.lockScreenDisplayed {
                                
                                self.dismiss(animated: false, completion: nil)
                                self.lockScreenDisplayed = false
                            }
                        }
                    } else {
                        
                        print("authentication fail = \(String(describing: error))")
                        
                        if !self.lockScreenDisplayed {
                            
                            self.dismiss(animated: false, completion: nil)

                            self.lockout()
                        }
                    }
                }
            } else {
                
                self.authenticatedOk = true

                print("no auth support")
                //FIXME: we have problem in multiple fetch
                //let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                //if let accounts = loadAccounts() {
                    
                //    appDelegate?.incomeList = accounts
                //}
                    
                //self.reloadData()
            }
        } else {
            
            self.authenticatedOk = true
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        validateiCloud()
        
        authenticate()
    
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        guard let split = self.parent?.parent?.parent as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected")
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
        
        //incomeList = loadAccounts()!
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for row in 0..<(appDelegate?.incomeList)!.count {
            
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
        
        guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "IncomeDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating IncomeDetailNavigationController")
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
            
            fatalError("Exception: UISplitViewController is expected")
        }
        
        if split.isCollapsed  {
            
            guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "IncomeDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating ExpenseDetailNavigationController")
            }
            
            guard let incomeTableView = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
                
                fatalError("Exception: IncomeDetailTableViewController is expected" )
            }
            
            incomeTableView.setPopover(delegate: self)
            
            let sectionIncomeList = tableSectionCellList[indexPath.section].data as? [XYZAccount]
            
            incomeTableView.income = sectionIncomeList![indexPath.row]
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
            
            let sectionIncomeList = tableSectionCellList[indexPath.section].data as? [XYZAccount]
            detailTableViewController.incomeDelegate = self
            delegate?.incomeSelected(newIncome: sectionIncomeList?[indexPath.row])
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
                    
                    fatalError("Exception: error on creating IncomeTotalTableViewCell")
                }

                totalCell = newTotalcell
                totalCell?.setAmount(amount: totalOfSection(section: indexPath.section - 1), code: tableSectionCellList[indexPath.section - 1].title!)
                cell = newTotalcell
            
            default:
                fatalError("Exception: section identifier \(identifier) not be handled" )
        }
        
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
            
            // Delete the row from the data source, the way we handle it is special, we delete it from incomelist, and then reload it in table section
            let sectionIncomeList = tableSectionCellList[indexPath.section].data as? [XYZAccount]
            let incomeToBeDeleted = sectionIncomeList![indexPath.row]
            
            guard let split = self.parent?.parent?.parent as? UISplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected")
            }
            
            if !split.isCollapsed  {
                
                guard let detailTableViewController = delegate as? IncomeDetailTableViewController else {
                    
                    fatalError("Exception: IncomeDetailTableViewController is expedted" )
                }
                
                if detailTableViewController.income == incomeToBeDeleted {
                    
                    detailTableViewController.income = nil
                    detailTableViewController.reloadData()
                }
            }
            
            softDeleteIncome(income: incomeToBeDeleted)
            let identifier = incomeToBeDeleted.value(forKey: XYZAccount.recordId) as? String
            
            let notificationCenter = UNUserNotificationCenter.current()
  
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier!])
            notificationCenter.removeAllDeliveredNotifications()
  
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let aContext = managedContext()
            let oldIncome = appDelegate?.incomeList.remove(at: (appDelegate?.incomeList.index(of: incomeToBeDeleted)!)!)   //incomeList.remove(at: indexPath.row)
            aContext?.delete(oldIncome!)
            
            self.delegate?.incomeDeleted(deletedIncome: oldIncome!)
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
        
        if ( tableSectionCellList[proposedDestinationIndexPath.section].identifier != "main" )
           || ( sourceIndexPath.section != proposedDestinationIndexPath.section ) {
            
            indexPath = sourceIndexPath
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        if var sectionIncomeList = tableSectionCellList[to.section].data as? [XYZAccount] {
            
            sectionIncomeList.insert(sectionIncomeList.remove(at: fromIndexPath.row), at: to.row)
            tableSectionCellList[to.section].data = sectionIncomeList
        }

        for (sectionIndex, section) in tableSectionCellList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, income) in sectionIncomeList.enumerated() {
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex // each section is allowed to have 999 records, which is pretty large number, consider the purpose of it.
                    income.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
                    
                    income.setValue(Date(), forKey: XYZAccount.lastRecordChange)
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.incomeList = (appDelegate?.incomeList.sorted() {
            
            (acc1, acc2) in
            
            return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
            })!
        
        saveAccounts()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    
        if tableSectionCellList[section].identifier == "summary" {
            
            return 17.5
        } else {
            
            return  CGFloat.leastNormalMagnitude
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 35
        } else {
            
            if tableSectionCellList[section].identifier == "summary" {
             
                return CGFloat.leastNormalMagnitude
            } else {
                
                return 17.5
            }
        }
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
                    
                    fatalError("Exception: Unexpected error on casting segue.destination for prepare from table view controller")
                }
                
                if let accountDetail = sender as? IncomeTableViewCell {
                    
                    guard let indexPath = tableView.indexPath(for: accountDetail) else {
                        
                        fatalError("Exception: Unexpeted error in getting indexPath for prepare from table view controller");
                    }

                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    let account = appDelegate?.incomeList[indexPath.row]
                    incomeDetailView.account = account
                } else if let addButtonSender = sender as? UIBarButtonItem, add === addButtonSender {
                    
                    os_log("Adding a new income", log: OSLog.default, type: .debug)
                } else {
                    
                    fatalError("Exception: unknown sender \(segue.identifier ?? "")")
                }

            default:
                fatalError("Unexpected error on default for prepare from table view controller")
        }
    }
}
