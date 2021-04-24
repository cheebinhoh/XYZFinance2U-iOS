//
//  XYZIncomeTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//
//  QA status: checked on feb-10, 2018

import UIKit
import LocalAuthentication
import CoreData
import CloudKit
import UserNotifications
import NotificationCenter
import os.log

protocol XYZIncomeSelectionDelegate: class {
    
    func incomeSelected(newIncome: XYZAccount?)
    func incomeDeleted(deletedIncome: XYZAccount)
}

class XYZIncomeTableViewController: UITableViewController,
    UIViewControllerPreviewingDelegate,
    XYZTableViewReloadData,
    XYZIncomeDetailDelegate {
    
    // MARK: - property

    let mainSection = 0
    
    var sectionExpandStatus = [Bool]()
    var sectionList = [TableSectionCell]()
    var currencyCodes = [String]()
    var authenticatedMechanismExist = false
    var authenticatedOk = false
    var iCloudEnable = false
    var lockScreenDisplayed = false
    
    weak var delegate: XYZIncomeSelectionDelegate?
    weak var detailViewController: UIViewController?
    weak var totalCell: XYZIncomeTotalTableViewCell?
    
    var total: Double {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        return (appDelegate?.incomeList)!.reduce(0.0) { (result, account) in
        
            return result + account.amount
        }
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var add: UIBarButtonItem!
    
    // MARK: - IBAction
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        
        guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "incomeDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating IncomeDetailNavigationController")
        }
        
        guard let incomeDetailTableView = incomeDetailNavigationController.viewControllers.first as? XYZIncomeDetailTableViewController else {
            
            fatalError("Exception: eror on casting first view controller to XYZIncomeDetailTableViewController" )
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected" )
        }

        tabBarController.popOverNavigatorController = incomeDetailNavigationController
        
        incomeDetailTableView.currencyCodes = currencyCodes
        incomeDetailTableView.setDelegate(delegate: self)

        incomeDetailNavigationController.modalPresentationStyle = .popover
        self.present(incomeDetailNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func unwindToIncomeTableView(sender: UIStoryboardSegue) {
        
        fatalError("Exception: execution should not be reached here")
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code you want to implement
        
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code here
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: "Undo last change".localized(), style: .default, handler: { (action) in
            
            self.undoManager?.undo()
            self.undoManager?.removeAllActions()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
 
    // MARK: - 3d touch delegate (peek & pop)
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        // Reuse the "Peek" view controller for presentation.
        
        guard let viewController = viewControllerToCommit as? XYZIncomeDetailViewController else {
            
            fatalError("Exception: XYZIncomeDetailViewController is expected")
        }
 
        if let _ = viewController.income {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            guard let tarBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                
                fatalError("Exception: XYZMainUITabBarController is expected")
            }
            
            tarBarController.popOverAlertController = nil
            
            tableView(tableView, didSelectRowAt: viewController.indexPath!)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location), indexPath.row > 0 else {
            
            return nil
        }
    
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "incomeDetailViewController") as? XYZIncomeDetailViewController else  {
            
            fatalError("Exception: XYZIncomeDetailViewController is expected")
        }
        
        let cell = tableView.cellForRow(at: indexPath)
        
        viewController.preferredContentSize = CGSize(width: 0.0, height: 175)
        previewingContext.sourceRect = (cell?.frame)!
        
        if sectionList[indexPath.section].identifier == "main" {
            
            guard let sectionIncomeList = sectionList[(indexPath.section)].data as? [XYZAccount] else {
                
                fatalError("Exception: [XYZAccount] is expected")
            }
            
            viewController.income = sectionIncomeList[(indexPath.row) - 1]
            viewController.indexPath = indexPath
        }
        
        return viewController
    }
    
    // MARK: - function

    func sectionTotal(section: Int) -> (Double, String) {
    
        let sectionIncomeList = sectionList[section].data as? [XYZAccount]
        
        let total = (sectionIncomeList!).reduce(0.0) { (result, account) in
        
            return result + account.amount
        }
        
        return (total, sectionList[section].title!)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    func saveNewIncome(income: XYZAccount) {
        
        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
            
            self.deleteIncomeWithoutUndo(income: income)
        })
        
        saveNewIncomeWithoutUndo(income: income)
    }
    
    func saveNewIncomeWithoutUndo(income: XYZAccount) {

        let currencyCode = income.currencyCode
        
        if !currencyCodes.contains(currencyCode) {
            
            currencyCodes.append(currencyCode)
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
    }
    
    func softDeleteIncome(income: XYZAccount) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        
        if !(appDelegate?.iCloudZones.isEmpty)! {
            
            guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
                
                fatalError("Exception: iCloudZoen is expected")
            }
            
            guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
                
                fatalError("Exception: data is expected for deleteRecordIdList")
            }
            
            guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
                
                fatalError("Exception: deleteRecordList is expected as [String]")
            }
            
            let recordName = income.recordId
            deleteRecordList.append(recordName)
            
            let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
            zone.setValue(savedDeleteRecordList, forKey: XYZiCloudZone.deleteRecordIdList)
        }
    }
    
    func deleteIncomeWithoutUndo(income: XYZAccount) {
        
        softDeleteIncome(income: income)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let aContext = managedContext()
        let index = appDelegate?.incomeList.firstIndex(of: income)
        let oldIncome = appDelegate?.incomeList.remove(at: index!)
        aContext?.delete(oldIncome!)
        
        self.delegate?.incomeDeleted(deletedIncome: oldIncome!)
        reloadData()
    }
    
    func deleteIncome(income: XYZAccount) {

        let oldBank = income.bank
        let oldAccountNr = income.accountNr
        let oldAmount = income.amount
        let oldPrincipal = income.principal
        let oldDate = income.lastUpdate
        let oldRepeatAction = income.repeatAction
        let oldRemindDate = income.repeatDate
        let oldCurrencyCode = income.currencyCode
        let oldSequenceNr = income.sequenceNr
        
        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
            
            let income = XYZAccount(id: nil, sequenceNr: 0, bank: oldBank, accountNr: oldAccountNr, amount: oldAmount, principal: oldPrincipal, date: oldDate, context: managedContext())
            
            income.repeatAction = oldRepeatAction
            income.repeatDate = oldRemindDate
            income.currencyCode = oldCurrencyCode
            income.sequenceNr = oldSequenceNr
            income.lastRecordChange = Date()
            
            for (index, section) in self.sectionList.enumerated() {
                
                if oldCurrencyCode == section.title {
                    
                    guard var sectionIncomeList = section.data as? [XYZAccount] else {
                        
                        fatalError("Exception: [XYZAccount] is expected")
                    }
                    
                    sectionIncomeList.insert(income, at: oldSequenceNr)
                    
                    self.sectionList[index].data = sectionIncomeList
                    break
                }
            }
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            appDelegate?.incomeList.append(income)
            
            self.reloadData()
        })
        
        deleteIncomeWithoutUndo(income: income)
    }
    
    private func loadDataInTableSectionCell() {
        
        //var currencyList = [String]()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        var currencyList = Set<String>()
        
        (appDelegate?.incomeList)!.forEach { income in

            let currency = income.currencyCode
            
            currencyList.insert(currency)
        }
        
        if currencyList.isEmpty {
            
            currencyList.insert(Locale.current.currencyCode!)
        }
        
        currencyCodes = Array(currencyList)
        
        sectionList.removeAll()
        sectionExpandStatus.removeAll()
        
        for currency in currencyList {
            
            var sectionIncomeList = [XYZAccount]()
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            for income in (appDelegate?.incomeList)! {
                
                if income.currencyCode == currency {
                    
                    sectionIncomeList.append(income)
                }
            }

            if !sectionIncomeList.isEmpty {
                
                sectionExpandStatus.append(true)
                sectionIncomeList = sortAcounts(sectionIncomeList)
                
                let mainSection = TableSectionCell(identifier: "main", title: currency, cellList: [], data: sectionIncomeList)
                sectionList.append(mainSection)
                
                //DEPRECATED: we do not provide sum as a separate cell but part of header for the section
                //let summarySection = TableSectionCell(identifier: "summary", title: nil, cellList: ["sum"], data: nil)
                //tableSectionCellList.append(summarySection)
            }
        }
        
        sectionList = sectionList.sorted(by: { (section1, section2) -> Bool in
            
            section1.title! < section2.title!
        })
    }
    
    func reloadData() {
        
        saveAccounts()
        loadDataInTableSectionCell()

        tableView.reloadData()
    }
    
    func registerNotification(income: XYZAccount) {
        
        let notificationCenter = UNUserNotificationCenter.current()
        let identifier = income.recordId
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeAllDeliveredNotifications()
    
        let bank = income.bank
        let accountNr = income.accountNr
        let repeatAction = income.repeatAction
        let reminddate = income.repeatDate
        
        // setup local notification
        if reminddate != Date.distantPast {
            
            let content = UNMutableNotificationContent()
            content.title = "Income update reminder"
            content.body = "\(String(describing: bank)), \(String(describing: accountNr)) ..."
            content.sound = UNNotificationSound.default
            content.userInfo[XYZAccount.type] = true
            content.userInfo[XYZAccount.recordId] = income.recordId
            
            var units: Set<Calendar.Component> = [ .minute ]
            switch repeatAction {
                
                case XYZAccount.RepeatAction.none.rawValue:
                    units.insert(.year)
                    units.insert(.month)
                    units.insert(.day)
                    units.insert(.hour)
                    units.insert(.minute)
                    
                case XYZAccount.RepeatAction.monthly.rawValue:
                    units.insert(.month)
                    units.insert(.day)
                    units.insert(.hour)
                    units.insert(.minute)
                    
                case XYZAccount.RepeatAction.weekly.rawValue:
                    units.insert(.weekday)
                    units.insert(.hour)
                    units.insert(.minute)
                    
                case XYZAccount.RepeatAction.daily.rawValue:
                    units.insert(.hour)
                    units.insert(.minute)
                    
                case XYZAccount.RepeatAction.hourly.rawValue:
                    units.insert(.minute)
                    
                default:
                    // we need to tolerate value that is not longer valid.
                    break
            }
            
            let dateInfo = Calendar.current.dateComponents(units, from: reminddate)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: ( repeatAction ) != XYZAccount.RepeatAction.none.rawValue )
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { (error : Error?) in
                
                if let _ = error {
                    
                } else {
                    
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
                    
                    let oldSequenceNr = income.sequenceNr
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex
                    income.sequenceNr = sequenceNr
                    
                    if oldSequenceNr != sequenceNr {
                        
                        income.lastRecordChange = Date()
                    }
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        saveManageContext()

        for income in (appDelegate?.incomeList)! {
            
            registerNotification(income: income)
        }
        
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.privateiCloudZones)!)
        zone?.data = appDelegate?.incomeList
        
        fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                             zones: [ckrecordzone], iCloudZones: (appDelegate?.privateiCloudZones)!, completionblock: {
            
        })
    }
    
    func validateiCloud() {
        
        CKContainer.default().accountStatus { (status, error) in
            
            if status == CKAccountStatus.noAccount {

                DispatchQueue.main.async {
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    
                    guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                        
                        fatalError("Exception: XYZMainUITabBarController is expected")
                    }
             
                    self.iCloudEnable = false
                    let alert = UIAlertController(title: "Sign in to icloud",
                                                  message: "Sign in to your iCloud account to keep records in iCloud",
                                                  preferredStyle: UIAlertController.Style.alert )
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
                        
                        alert.dismiss(animated: false, completion: {
                        
                            tabBarController.popOverAlertController = nil
                        })
                    }))
                    
                    tabBarController.popOverAlertController = alert
                    self.present(alert, animated: false, completion: nil)
                }
            } else {
                
                self.iCloudEnable = true
                
                CKContainer.default().requestApplicationPermission(CKContainer.Application.Permissions.userDiscoverability, completionHandler: { (status, error) in
                    
                    if nil != error {
                        
                    }
                })
                
            }
        }
    }
    
    @discardableResult func lockout() -> UINavigationController? {
        
        guard let lockScreenView = self.storyboard?.instantiateViewController(withIdentifier: "lockScreenView") as? XYZLockScreenViewController else {
            
            fatalError("Exception: error on instantiating lockScreenView")
        }
        
        lockScreenView.mainTableViewController = self
        let lockScreenViewNavigatorController = UINavigationController(rootViewController: lockScreenView)
        
        lockScreenViewNavigatorController.modalPresentationStyle = .overFullScreen
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            
            lockScreenDisplayed = true
            
            // NOTE: to avoid warning "Unbalanced calls to begin/end appearance transitions for"
            DispatchQueue.main.async {
                
                appDelegate.window?.rootViewController?.present(lockScreenViewNavigatorController, animated: false, completion: nil)
            }
        }
        
        return lockScreenViewNavigatorController
    }
    
    @discardableResult func authenticate() -> UINavigationController? {
        
        // authentication validation before doing other things
        let laContext = LAContext()
        var authError: NSError?
        authenticatedOk = false
        var lockoutNavigationController: UINavigationController? = nil
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        if #available(iOS 8.0, macOS 10.12.1, *) {

            if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
 
                self.authenticatedMechanismExist = true
                
                let defaults = UserDefaults.standard;
                let required = defaults.value(forKey: requiredAuthenticationKey) as? Bool ?? false
     
                if required {
                    
                    if !lockScreenDisplayed {
                        
                        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                        
                            fatalError("Exception: XYZMainUITabBarController is expected")
                        }
                        
                        if let _ = tabBarController.popOverAlertController {
                            
                            dismiss(animated: false, completion: {
                            
                                tabBarController.popOverAlertController = nil
                            })
                        }
                        
                        if nil == tabBarController.popOverNavigatorController {
                           
                            lockoutNavigationController = lockout()
                        }
                    }
                    
                    if nil == appDelegate?.lastAuthenticated
                        || Date().timeIntervalSince((appDelegate?.lastAuthenticated)!) >= 0.0 {
                       
                        laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                                 localizedReason: "Authenticate to use the app".localized() )
                        { (success, error) in
                    
                            self.authenticatedOk = success
                            
                            if self.authenticatedOk {
                                
                                DispatchQueue.main.async {
                                    
                                    appDelegate?.lastAuthenticated = Date()
            
                                    if self.lockScreenDisplayed {
                                        
                                        self.dismiss(animated: false, completion: nil)
                                        self.lockScreenDisplayed = false
                                    }
                                }
                            } else {

                                if !self.lockScreenDisplayed {
                        
                                    DispatchQueue.main.async {
                                        
                                        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                                        
                                            fatalError("Exception: XYZMainUITabBarController is expected")
                                        }
                                        
                                        tabBarController.popOverNavigatorController?.popToRootViewController(animated: false)
                                        tabBarController.popOverNavigatorController?.dismiss(animated: false, completion: {
                                        
                                        })
                                        
                                        self.dismiss(animated: false, completion: {
                                          
                                            lockoutNavigationController = self.lockout()
                                        })
                                        
                                        lockoutNavigationController = self.lockout()
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
                }
            } else {
                
                self.authenticatedOk = true
            }
        } else {
            
            self.authenticatedOk = true
        }
        
        return lockoutNavigationController
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    
        validateiCloud()
        
        //authenticate()
    
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
                
        tableView.tableFooterView = UIView(frame: .zero)
        navigationItem.setLeftBarButton(self.editButtonItem, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
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
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Retrieve latest update from iCloud".localized())
        refreshControl.addTarget(self, action: #selector(refreshUpdateFromiCloud), for: .valueChanged)
        
        // this is the replacement of implementing: "collectionView.addSubview(refreshControl)"
        tableView.refreshControl = refreshControl
    }

    @objc func refreshUpdateFromiCloud(refreshControl: UIRefreshControl) {

        var zonesToBeFetched = [CKRecordZone]()
        let incomeCustomZone = CKRecordZone(zoneName: XYZAccount.type)
        zonesToBeFetched.append(incomeCustomZone)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let icloudZones = appDelegate?.privateiCloudZones.filter({ (icloudZone) -> Bool in
        
            let name = icloudZone.value(forKey: XYZiCloudZone.name) as? String ?? ""
            
            return name == XYZAccount.type
        })

        fetchiCloudZoneChange(database: CKContainer.default().privateCloudDatabase, zones: zonesToBeFetched, icloudZones: icloudZones!, completionblock: {
            
            for (_, icloudzone) in (icloudZones?.enumerated())! {
                
                let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String
                
                switch zName! {
                    
                    case XYZAccount.type:
                        appDelegate?.incomeList = (icloudzone.data as? [XYZAccount])!
                        appDelegate?.incomeList = sortAcounts((appDelegate?.incomeList)!)
                        
                        DispatchQueue.main.async {
                            
                            self.reloadData()
                            
                            pushChangeToiCloudZone(database: CKContainer.default().privateCloudDatabase, zones: zonesToBeFetched, icloudZones: icloudZones!, completionblock: {
                            
                            })
                        }
     
                    default:
                        fatalError("Exception: \(String(describing: zName)) is not supported")
                }
            }
        })
        
        // somewhere in your code you might need to call:
        refreshControl.endRefreshing()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()

        if sectionList[indexPath.section].identifier == "main" {
            
            let incomeList = sectionList[indexPath.section].data as? [XYZAccount]
            let income = incomeList![indexPath.row - 1]

            let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
                
                self.deleteIncome(income: income)
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (appDelegate?.incomeList.isEmpty)! {
                    
                    self.setEditing(false, animated: true)
                    self.tableView.setEditing(false, animated: false)
                }
                
                handler(true)
            }
            
            commands.append(delete)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        guard sectionList[indexPath.section].identifier == "main" else {
            
            return nil
        }
        
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
            
            case 0:
                sectionExpandStatus[indexPath.section] = !sectionExpandStatus[indexPath.section]
                tableView.reloadData()
            
            default:
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                 
                guard let incomeDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "incomeDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: error on instantiating incomeDetailNavigationController")
                }
                
                guard let incomeTableView = incomeDetailNavigationController.viewControllers.first as? XYZIncomeDetailTableViewController else {
                    
                    fatalError("Exception: XYZIncomeDetailTableViewController is expected" )
                }
                
                incomeTableView.setDelegate(delegate: self)
                
                let sectionIncomeList = sectionList[indexPath.section].data as? [XYZAccount]
                
                incomeTableView.income = sectionIncomeList![indexPath.row - 1]
                incomeDetailNavigationController.modalPresentationStyle = .popover
                incomeTableView.currencyCodes = currencyCodes
                self.present(incomeDetailNavigationController, animated: true, completion: nil)
            
                guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                    
                    fatalError("Exception: XYZMainUITabBarControllerXYZMainUITabBarController is expected" )
                }
            
                tabBarController.popOverNavigatorController = incomeDetailNavigationController

                tableView.deselectRow(at: indexPath, animated: false)
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
                let expanded = sectionExpandStatus[section]
                
                nrOfRows = 1 + ( expanded ? (incomeListStored?.count)! : 0 )
            
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
                let incomeListStored = sectionList[indexPath.section].data as? [XYZAccount]
                
                if indexPath.row > 0 
                {
                    guard let incomecell = tableView.dequeueReusableCell(withIdentifier: "incomeTableViewCell", for: indexPath) as? XYZIncomeTableViewCell else {
                        
                        fatalError("error on creating XYZIncomeTableViewCell")
                    }
                    
                    let account = incomeListStored![indexPath.row - 1]
                    let currencyCode = account.currencyCode
                    
                    incomecell.bank.text = account.bank
                    incomecell.account.text = account.accountNr
                    
                    let principal = account.principal
                    
                    if principal > 0.0 {
                        
                        if incomecell.account.text != "" {
                            
                            incomecell.account.text = incomecell.account.text! + ", "
                        }
                        
                        let earnedAmount = account.amount - principal
                        let percentage = earnedAmount / principal
                        let amountASNSNumber = NSNumber(value: percentage * 100)
                        let formatter = NumberFormatter()
                        
                        formatter.minimumIntegerDigits = 1
                        formatter.minimumFractionDigits = 2
                        formatter.maximumFractionDigits = 2
                        
                        let percentageAsString = formatter.string(from: amountASNSNumber)
                        var percentageSign = ""
                        var percentageDiff = ""
                        switch percentage
                        {
                            case let x where x < 0.0 :
                                percentageDiff = "\(percentageAsString!)%"
                            
                            case let x where x > 0.0 :
                                percentageSign = "+"
                                percentageDiff = "+\(percentageAsString!)%"
                            
                            default:
                                break
                        }
                        
                        incomecell.account.text = incomecell.account.text! + "\(percentageSign)\(formattingCurrencyValue(of: earnedAmount, as: currencyCode)) (\(percentageDiff))"
                    }
                    
                    incomecell.amount.text = formattingCurrencyValue(of: account.amount, as: currencyCode)

                    cell = incomecell
                    
                } else {
                    
                    guard let totalCell = tableView.dequeueReusableCell(withIdentifier: "incomeTotalTableViewCell", for: indexPath) as? XYZIncomeTotalTableViewCell else {
                        
                        fatalError("Exception: error on creating XYZIncomeTotalTableViewCell")
                    }
                    
                    var currencyCode = ""
                    
                    let total = incomeListStored!.reduce(0.0) { (result, account) in
                     
                        return result + account.amount
                    }
                    
                    currencyCode = incomeListStored?.first?.currencyCode ?? Locale.current.currencyCode!
                    
                    totalCell.amount.text = formattingCurrencyValue(of: total, as: currencyCode)
                    totalCell.currency.text = currencyCode.localized()
                    
                    cell = totalCell
                }
       
            case "summary":
                guard let newTotalcell = tableView.dequeueReusableCell(withIdentifier: "incomeTotalTableViewCell", for: indexPath) as? XYZIncomeTotalTableViewCell else {
                    
                    fatalError("Exception: error on creating XYZIncomeTotalTableViewCell")
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
               && indexPath.row > 0
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Delete the row from the data source, the way we handsaveIncomele it is special, we delete it from incomelist, and then reload it in table section
            let sectionIncomeList = sectionList[indexPath.section].data as? [XYZAccount]
            let incomeToBeDeleted = sectionIncomeList![indexPath.row]
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            softDeleteIncome(income: incomeToBeDeleted)
            let identifier = incomeToBeDeleted.recordId
            
            let notificationCenter = UNUserNotificationCenter.current()
  
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
            notificationCenter.removeAllDeliveredNotifications()
  
            let aContext = managedContext()
            let oldIncome = appDelegate?.incomeList.remove(at: (appDelegate?.incomeList.firstIndex(of: incomeToBeDeleted)!)!)
            aContext?.delete(oldIncome!)
            
            self.delegate?.incomeDeleted(deletedIncome: oldIncome!)
            reloadData()
        } else if editingStyle == .insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        saveAccounts()
        
        //navigationItem.rightBarButtonItem?.isEnabled = true
    }

    // Override to support rearranging the table view.
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        return sectionList[indexPath.section].identifier == "main"
               && indexPath.row > 0
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        var indexPath = proposedDestinationIndexPath

        if ( sectionList[proposedDestinationIndexPath.section].identifier != "main" )
           || ( sourceIndexPath.section != proposedDestinationIndexPath.section ) {
            
            indexPath = sourceIndexPath
        } else if indexPath.row <= 0 {
            
            indexPath.row = 1
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
        if var sectionIncomeList = sectionList[to.section].data as? [XYZAccount] {
            
            sectionIncomeList.insert(sectionIncomeList.remove(at: fromIndexPath.row - 1), at: to.row - 1)
            sectionList[to.section].data = sectionIncomeList
        }

        for (sectionIndex, section) in sectionList.enumerated() {
            
            if let sectionIncomeList = section.data as? [XYZAccount] {
                
                for (rowIndex, income) in sectionIncomeList.enumerated() {
                    
                    let sequenceNr = 1000 * sectionIndex + rowIndex // each section is allowed to have 999 records, which is pretty large number, consider the purpose of it.
                    income.sequenceNr = sequenceNr
                    
                    income.lastRecordChange = Date()
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
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 45)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = sectionList[section].title
        title.textColor = UIColor.gray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
        subtotal.text = formattingCurrencyValue(of: amount, as: currency)
        subtotal.textColor = UIColor.gray
        stackView.addArrangedSubview(subtotal)
        
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        return 10
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
                guard let incomeDetailView = segue.destination as? XYZIncomeDetailViewController else {
                    
                    fatalError("Exception: Unexpected error on casting segue.destination for prepare from table view controller")
                }
                
                if let accountDetail = sender as? XYZIncomeTableViewCell {
                    
                    guard let indexPath = tableView.indexPath(for: accountDetail) else {
                        
                        fatalError("Exception: Unexpeted error in getting indexPath for prepare from table view controller");
                    }

                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    let account = appDelegate?.incomeList[indexPath.row]
                    incomeDetailView.account = account
                } else if let addButtonSender = sender as? UIBarButtonItem, add === addButtonSender {
                    
                } else {
                    
                    fatalError("Exception: unknown sender \(segue.identifier ?? "")")
                }

            default:
                fatalError("Unexpected error on default for prepare from table view controller")
        }
    } */
}
