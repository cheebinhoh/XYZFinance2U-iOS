//
//  IncomeTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on feb-10, 2018

import UIKit
import LocalAuthentication
import CoreData
import CloudKit
import UserNotifications
import NotificationCenter
import os.log

protocol IncomeSelectionDelegate: class {
    
    func incomeSelected(newIncome: XYZAccount?)
    func incomeDeleted(deletedIncome: XYZAccount)
}

class IncomeTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIViewControllerPreviewingDelegate,
    IncomeDetailDelegate {
    
    // MARK: - property
    
    var sectionList = [TableSectionCell]()
    var isPopover = false
    let mainSection = 0
    var currencyCodes = [String]()
    var authenticatedMechanismExist = false
    var authenticatedOk = false
    var iCloudEnable = false
    var lockScreenDisplayed = false
    weak var delegate: IncomeSelectionDelegate?
    weak var detailViewController: UIViewController?
    weak var totalCell: IncomeTotalTableViewCell?
    
    var total: Double {
        
        var sum = 0.0
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for account in (appDelegate?.incomeList)! {
            
            sum = sum + ( account.value(forKey: XYZAccount.amount) as? Double )!
        }
        
        return sum
    }
    
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        mainSplitView.popOverNavigatorController = incomeDetailNavigationController
        
        incomeDetailTableView.currencyCodes = currencyCodes
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
    
    // MARK: - 3d touch delegate (peek & pop)
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        // Reuse the "Peek" view controller for presentation.
        
        guard let viewController = viewControllerToCommit as? IncomeDetailViewController else {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }
 
        if let _ = viewController.income {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverAlertController = nil
            
            tableView(tableView, didSelectRowAt: viewController.indexPath!)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "IncomeDetailViewController") as? IncomeDetailViewController else  {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }

        let indexPath = tableView.indexPathForRow(at: location)
        let cell = tableView.cellForRow(at: indexPath!)
        
        viewController.preferredContentSize = CGSize(width: 0.0, height: 140)
        previewingContext.sourceRect = (cell?.frame)!
        
        if sectionList[indexPath!.section].identifier == "main" {
            
            guard let sectionIncomeList = sectionList[(indexPath?.section)!].data as? [XYZAccount] else {
                
                fatalError("Exception: [XYZAccount] is expected")
            }
            
            viewController.income = sectionIncomeList[(indexPath?.row)!]
            viewController.indexPath = indexPath
        } else {
         
            let (amount, currency) =  sectionTotal(section: indexPath!.section - 1)
            viewController.total = amount
            viewController.currencyCode = currency
        }

        return viewController
    }
    
    
    // MARK: - function

    func sectionTotal(section: Int) -> (Double, String) {
    
        var total = 0.0;
        let sectionIncomeList = sectionList[section].data as? [XYZAccount]
        
        for income in sectionIncomeList! {
        
            total = total + ((income.value(forKey: XYZAccount.amount) as? Double) ?? 0.0 )
        }
        
        return (total, sectionList[section].title!)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func saveNewIncome(income: XYZAccount) {

        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        
        if let _ = currencyCode, !currencyCodes.contains(currencyCode!) {
            
            currencyCodes.append(currencyCode!)
        }
        
        for (index, section) in sectionList.enumerated() {
            
            if currencyCode == section.title {
                
                guard var sectionIncomeList = section.data as? [XYZAccount] else {
                    
                    fatalError("Exception: [XYZAccount] is expected")
                }
                
                sectionIncomeList.append(income)
                
                sectionList[index].data = sectionIncomeList
                break
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.incomeList.append(income)
        
        reloadData()
        
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        if !mainSplitView.isCollapsed  {
         
            if let indexPath = incomeIndex(of: income) {
                
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                delegate?.incomeSelected(newIncome: income)
            }
        }
    }
    
    func incomeIndex(of income: XYZAccount) -> IndexPath? {
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
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

        reloadData()
        saveAccounts()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        if !mainSplitView.isCollapsed {
         
            if let indexPath = incomeIndex(of: income) {
             
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                delegate?.incomeSelected(newIncome: income)
            }
        }
        
        /* DEPRECATED: we do not need that when we have 
        let selectedIndexPath = incomeIndex(of: income)
        let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
        
        if sectionList[(selectedIndexPath?.section)!].title == currencyCode! {
    
            let summaryIndex = IndexPath(row:0, section: (selectedIndexPath?.section)! + 1)
            tableView.reloadRows(at: [selectedIndexPath!, summaryIndex], with: .automatic)
            
            saveAccounts()
        } else {
        
            reloadData()
            saveAccounts()
        }
        */
    }
    
    func softDeleteIncome(income: XYZAccount) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        
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
            
            let recordName = income.value(forKey: XYZAccount.recordId) as? String
            deleteRecordLiset.append(recordName!)
            
            let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
            zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
        }
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
        
        currencyCodes = currencyList
        
        if currencyList.isEmpty {
            
            currencyList.append(Locale.current.currencyCode!)
        }
        
        sectionList.removeAll()
     
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
                
                sectionIncomeList = sortAcounts(sectionIncomeList)
                
                let mainSection = TableSectionCell(identifier: "main", title: currency, cellList: [], data: sectionIncomeList)
                sectionList.append(mainSection)
                
                //DEPRECATED: we do not provide sum as a separate cell but part of header for the section
                //let summarySection = TableSectionCell(identifier: "summary", title: nil, cellList: ["sum"], data: nil)
                //tableSectionCellList.append(summarySection)
            }
        }
        
        /* DEPRECATED: debugging code
        for section in sectionList {
            
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
        */
    }
    
    func reloadData() {
        
        saveAccounts()
        loadDataInTableSectionCell()

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
            content.body = "\(String(describing: bank!)), \(String(describing: accountNr!)) ..."
            content.sound = UNNotificationSound.default()
            content.userInfo[XYZAccount.type] = true
            content.userInfo[XYZAccount.recordId] = income.value(forKey: XYZAccount.recordId) as? String
            
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
                } else {
                    
                    print("-------- success in register notification")
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
        for (sectionIndex, section) in sectionList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, income) in sectionIncomeList.enumerated() {
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex
                    income.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        saveManageContext()

        for income in (appDelegate?.incomeList)! {
            
            registerNotification(income: income)
        }
        
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.privateiCloudZones)!)
        zone?.data = appDelegate?.incomeList
        
        fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone], (appDelegate?.privateiCloudZones)!, {
            
        })
    }
    
    func validateiCloud() {
        
        CKContainer.default().accountStatus { (status, error) in
            
            if status == CKAccountStatus.noAccount {

                DispatchQueue.main.async {
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                        
                        fatalError("Exception: UISplitViewController is expected" )
                    }
                    
                    self.iCloudEnable = false
                    let alert = UIAlertController(title: "Sign in to icloud",
                                                  message: "Sign in to your iCloud account to keep records in iCloud",
                                                  preferredStyle: UIAlertControllerStyle.alert )
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
                        
                        alert.dismiss(animated: false, completion: {
                        
                            mainSplitView.popOverAlertController = nil
                        })
                    }))
                    
                    mainSplitView.popOverAlertController = alert
                    self.present(alert, animated: false, completion: nil)
                }
            } else {
                
                self.iCloudEnable = true
                
                CKContainer.default().requestApplicationPermission(CKApplicationPermissions.userDiscoverability, completionHandler: { (status, error) in
                    
                    if nil != error {
                        
                        print("-------- request application permission error = \(String(describing: error))")
                    }
                })
                
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
            
            //appDelegate.lastAuthenticated = nil
            
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

                self.authenticatedMechanismExist = true
                
                if !lockScreenDisplayed {
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                        
                        fatalError("Exception: UISplitViewController is expected" )
                    }
                    
                    if let _ = mainSplitView.popOverAlertController {
                        
                        dismiss(animated: false, completion: {
                        
                            mainSplitView.popOverAlertController = nil
                        })
                    }
                    
                    if nil == mainSplitView.popOverNavigatorController {
                        
                        lockout()
                    }
                }
        
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                if nil == appDelegate?.lastAuthenticated
                    || Date().timeIntervalSince((appDelegate?.lastAuthenticated)!) >= 30.0 {
                   
                    laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                             localizedReason: "Authenticate to use the app" )
                    { (success, error) in
                
                        self.authenticatedOk = success
                        
                        if self.authenticatedOk {
                            
                            //OperationQueue.main.addOperation
                            DispatchQueue.main.async {
                                
                                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                    
                                    appDelegate.lastAuthenticated = Date()
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
                                
                                DispatchQueue.main.async {
                                    
                                    self.dismiss(animated: false, completion: nil)

                                    self.lockout()
                                }
                            }
                        }
                    }
                } else {
                    
                    appDelegate?.lastAuthenticated = Date()
                    
                    DispatchQueue.main.async {
                        
                        if self.lockScreenDisplayed {
                            
                            self.dismiss(animated: false, completion: nil)
                            self.lockScreenDisplayed = false
                        }
                    }
                }
            } else {
                
                self.authenticatedOk = true

                print("no auth support")
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
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        if mainSplitView.isCollapsed {
            
            self.navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
        }
        
        if mainSplitView.viewControllers.count > 1 {
            
            guard let _ = mainSplitView.viewControllers.last as? UINavigationController else {
                
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for row in 0..<(appDelegate?.incomeList)!.count {
            
            let indexPath = IndexPath(row: row, section: 0)
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        self.delegate = nil
        secondaryViewController.navigationItem.title = "New" //TODO: check if we need this
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let incomeDetailTableViewController = navigationController.viewControllers.first as? IncomeDetailTableViewController {
                
                incomeDetailTableViewController.incomeDelegate = self
                incomeDetailTableViewController.isPushinto = true

                if !isPopover && incomeDetailTableViewController.modalEditing {
                    
                    incomeDetailTableViewController.isPushinto = false
                    incomeDetailTableViewController.isPopover = true
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
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        var amount = 0.0
        
        if sectionList[indexPath.section].identifier == "main" {
            
            let incomeList = sectionList[indexPath.section].data as? [XYZAccount]
            let income = incomeList![indexPath.row]
            
            amount = income.value(forKey: XYZExpense.amount) as? Double ?? 0.0
            
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, handler in
                
                self.deleteIncome(income: income)
                
                handler(true)
            }
            
            commands.append(delete)
        } else {
            
            (amount, _) = sectionTotal(section: indexPath.section - 1)
        }
        
        let more = UIContextualAction(style: .normal, title: "More") { _, _, handler in
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let copyUrlOption = UIAlertAction(title: "Copy amount", style: .default, handler: { (action) in
                
                mainSplitView.popOverAlertController = nil
                UIPasteboard.general.string = "\(amount)"
                handler(true)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                
                mainSplitView.popOverAlertController = nil
                handler(true)
            })
            
            optionMenu.addAction(copyUrlOption)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: {
              
                mainSplitView.popOverAlertController = optionMenu
            })
        }
        
        commands.append(more)
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if sectionList[indexPath.section].identifier == "main" {
        
            return indexPath
        } else {
            
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        if mainSplitView.isCollapsed  {
            
            guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "IncomeDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating ExpenseDetailNavigationController")
            }
            
            guard let incomeTableView = incomeDetailNavigationController.viewControllers.first as? IncomeDetailTableViewController else {
                
                fatalError("Exception: IncomeDetailTableViewController is expected" )
            }
            
            incomeTableView.setPopover(delegate: self)
            
            let sectionIncomeList = sectionList[indexPath.section].data as? [XYZAccount]
            
            incomeTableView.income = sectionIncomeList![indexPath.row]
            incomeDetailNavigationController.modalPresentationStyle = .popover
            incomeTableView.currencyCodes = currencyCodes
            self.present(incomeDetailNavigationController, animated: true, completion: nil)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = incomeDetailNavigationController
        } else {
            
            guard let detailTableViewController = delegate as? IncomeDetailTableViewController else {
                
                fatalError("Exception: IncomeDetailTableViewController is expedted" )
            }
            
            let sectionIncomeList = sectionList[indexPath.section].data as? [XYZAccount]
            detailTableViewController.incomeDelegate = self
            detailTableViewController.currencyCodes = currencyCodes
            delegate?.incomeSelected(newIncome: sectionIncomeList?[indexPath.row])
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var nrOfRows = 0
        
        switch sectionList[section].identifier {
            
            case "main":
                let incomeListStored = sectionList[section].data as? [XYZAccount]
                nrOfRows = (incomeListStored?.count)!
            
            default:
                let incomeListStored = sectionList[0].data as? [XYZAccount]
                nrOfRows = (incomeListStored?.count)! > 0 ? 1 : 0
        }
        
        return nrOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        var cell: UITableViewCell?
        
        let identifier = sectionList[indexPath.section].identifier
       
        switch identifier {
            
            case "main":
                guard let incomecell = tableView.dequeueReusableCell(withIdentifier: "IncomeTableViewCell", for: indexPath) as? IncomeTableViewCell else {
                    
                    fatalError("error on creating cell")
                }

                let incomeListStored = sectionList[indexPath.section].data as? [XYZAccount]
                let account = incomeListStored![indexPath.row]
                let currencyCode = account.value(forKey: XYZAccount.currencyCode) as? String ?? Locale.current.currencyCode!
                
                incomecell.bank.text = account.value(forKey: XYZAccount.bank) as? String
                incomecell.account.text = account.value(forKey: XYZAccount.accountNr ) as? String
                incomecell.amount.text = formattingCurrencyValue(input: (account.value(forKey: XYZAccount.amount) as? Double)!, code: currencyCode)
                incomecell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                cell = incomecell
       
            case "summary":
                guard let newTotalcell = tableView.dequeueReusableCell(withIdentifier: "IncomeTotalTableViewCell", for: indexPath) as? IncomeTotalTableViewCell else {
                    
                    fatalError("Exception: error on creating IncomeTotalTableViewCell")
                }

                totalCell = newTotalcell
                let (amount, currency) = sectionTotal(section: indexPath.section - 1)
                totalCell?.setAmount(amount: amount, code: currency)
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
        
        return sectionList[indexPath.section].identifier == "main" 
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Delete the row from the data source, the way we handsaveIncomele it is special, we delete it from incomelist, and then reload it in table section
            let sectionIncomeList = sectionList[indexPath.section].data as? [XYZAccount]
            let incomeToBeDeleted = sectionIncomeList![indexPath.row]
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            if !mainSplitView.isCollapsed  {
                
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
  
            let aContext = managedContext()
            let oldIncome = appDelegate?.incomeList.remove(at: (appDelegate?.incomeList.index(of: incomeToBeDeleted)!)!)
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
        
        return sectionList[indexPath.section].identifier == "main"
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var indexPath = proposedDestinationIndexPath
        
        if ( sectionList[proposedDestinationIndexPath.section].identifier != "main" )
           || ( sourceIndexPath.section != proposedDestinationIndexPath.section ) {
            
            indexPath = sourceIndexPath
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        if var sectionIncomeList = sectionList[to.section].data as? [XYZAccount] {
            
            sectionIncomeList.insert(sectionIncomeList.remove(at: fromIndexPath.row), at: to.row)
            sectionList[to.section].data = sectionIncomeList
        }

        for (sectionIndex, section) in sectionList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, income) in sectionIncomeList.enumerated() {
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex // each section is allowed to have 999 records, which is pretty large number, consider the purpose of it.
                    income.setValue(sequenceNr, forKey: XYZAccount.sequenceNr)
                    
                    income.setValue(Date(), forKey: XYZAccount.lastRecordChange)
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.incomeList = sortAcounts((appDelegate?.incomeList)!)
 
        saveAccounts()
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
    
    /*
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
     */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*
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
    } */
}
