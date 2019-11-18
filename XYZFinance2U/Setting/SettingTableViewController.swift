//
//  XYZSettingTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 - 2019 CB Hoh. All rights reserved.
//

import os.log
import LocalAuthentication
import CloudKit
import UIKit

class XYZSettingTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIDocumentPickerDelegate,
    SettingTextTableViewCellDelegate {
    
    // MARK: - property
    var sectionList = [TableSectionCell]()
    var delegate: UIViewController?
    var popoverView: UIViewController?
    var isCollapsed: Bool {
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            return split.isCollapsed
        } else {
            
            return true
        }
    }
    
    // MARK: - function
    
    func switchChanged(_ value: Bool, _ sender: SettingTableViewCell) {
    
        let defaults = UserDefaults.standard;
        let laContext = LAContext()
        var authError: NSError?
        
        if #available(iOS 8.0, macOS 10.12.1, *) {
            
            if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                
                laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                         localizedReason: "Authenticate to change the setting".localized() )
                { (success, error) in
                    
                    DispatchQueue.main.async {
                        
                        if success {
                            
                            let required = defaults.value(forKey: requiredauthenticationKey) as? Bool ?? false
                            defaults.set(!required, forKey: requiredauthenticationKey)
                        }
                        
                        self.reload()
                    }
                }
            }
        }
    }
    
    func getMainTableView() -> XYZIncomeTableViewController {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let split = appDelegate?.window?.rootViewController as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        guard let tabBarController = split.viewControllers.first as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected" )
        }
        
        return tableViewController
    }
    
    func reload() {
        
        loadDataIntoSection()
        tableView.reloadData()
    }
    
    func loadDataIntoSection() {
        
        sectionList = [TableSectionCell]()
        
        let mainSection = TableSectionCell(identifier: "main", title: "", cellList: ["About"], data: nil)
        sectionList.append(mainSection)
        
        let tableViewController = getMainTableView()
        
        var exportSection = TableSectionCell(identifier: "export", title: "",
                                             cellList: ["Export"], data: nil)
        
        if tableViewController.iCloudEnable {
            
            exportSection.cellList.append("DeleteData")
        }

        sectionList.append(exportSection)
        
        if tableViewController.authenticatedMechanismExist {
            
            let defaults = UserDefaults.standard;
            let required = defaults.value(forKey: requiredauthenticationKey) as? Bool ?? false
            var celllist = ["requiredauthentication"]
            
            if required {
                
                celllist.append("Lockout")
            }
            
            let logoutSection = TableSectionCell(identifier: "authentication", title: "", cellList: celllist, data: nil)
            sectionList.append(logoutSection)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.tableFooterView = UIView(frame: .zero)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        loadDataIntoSection()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sectionList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
            
            case "About" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "About".localized()
                cell = newcell
            
            case "Export" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Save to file".localized()
                newcell.accessoryType = .none
                cell = newcell
            
            case "SynciCloud" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Update to iCloud".localized()
                newcell.accessoryType = .none
                cell = newcell
            
            case "DeleteData":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Delete data".localized()
                newcell.accessoryType = .none
                cell = newcell
            
            case "Lockout" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Lock out".localized()
                newcell.accessoryType = .none
                cell = newcell

            case "requiredauthentication" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }

                let defaults = UserDefaults.standard;
                let required = defaults.value(forKey: requiredauthenticationKey) as? Bool ?? false
                
                newcell.title.text = "Require authentication".localized()
                newcell.accessoryType = .none
                
                if nil == newcell.optionSwitch {
                    
                    newcell.addUISwitch()
                    newcell.delegate = self
                }
                
                newcell.optionSwitch.isOn = required
                
                // newcell.accessoryType = required ? .checkmark : .none
                cell = newcell
            
            default:
                fatalError("Exception: \(sectionList[indexPath.section].cellList[indexPath.row]) is not supported")
        }
        
        return cell!
    }
    
    func loadSettingDetailTableView(_ settingDetail: SettingDetailTableViewController, _ indexPath: IndexPath) {
        
        settingDetail.tableSectionCellList.removeAll()

        let aboutSection = TableSectionCell(identifier: "about", title: "", cellList: ["about"], data: nil)
        settingDetail.tableSectionCellList.append(aboutSection)
        
        //https://fixer.io is no longer available as a free service, discommision it.
        //let disclaimerSection = TableSectionCell(identifier: "disclaimer", title: "", cellList: ["disclaimer"], data: nil)
        //settingDetail.tableSectionCellList.append(disclaimerSection)
        
        let creditSection = TableSectionCell(identifier: "credit", title: "", cellList: ["credit"], data: nil)
        settingDetail.tableSectionCellList.append(creditSection)
        
        settingDetail.navigationItem.title = "About".localized()
        let footerSection = TableSectionCell(identifier: "footer", title: "", cellList: [String](), data: nil)
        settingDetail.tableSectionCellList.append(footerSection)
        
        settingDetail.tableView.reloadData()
    }
    
    
    func showAbout(_ indexPath: IndexPath) {
        
        var settingDetail: SettingDetailTableViewController?
        
        if let _ = delegate, delegate is SettingDetailTableViewController {
            
            settingDetail = delegate as? SettingDetailTableViewController
        } else {
            
            guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating SettingDetailNavigationController")
            }
            
            settingDetail = settingDetailNavigationController.viewControllers.first as? SettingDetailTableViewController

            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                
                fatalError("Exception: XYZMainSplitViewController is expected" )
            }
            
            if mainSplitView.isCollapsed {
                
                mainSplitView.popOverAlertController = settingDetailNavigationController
                settingDetail?.setPopover(true)
                popoverView = settingDetail
                self.present(settingDetailNavigationController, animated: false, completion: nil)
            } else {
                
                delegate = settingDetail!
                mainSplitView.viewControllers.remove(at: 1)
                mainSplitView.viewControllers.insert(settingDetailNavigationController, at: 1)
            }
        }
        
        loadSettingDetailTableView(settingDetail!, indexPath)
    }
    
    func saveContent(_ content: String, file: String) {
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            do {
                
                try content.write(to: fileURL, atomically: false, encoding: .utf8)
                
                let uiDocumentPicker = UIDocumentPickerViewController(urls: [fileURL], in: UIDocumentPickerMode.exportToService)
                uiDocumentPicker.delegate = self
                uiDocumentPicker.modalPresentationStyle = UIModalPresentationStyle.formSheet
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
                    
                    fatalError("Exception: XYZMainSplitViewController is expected" )
                }
                
                mainSplitView.popOverAlertController = uiDocumentPicker
                
                self.present(uiDocumentPicker, animated: true, completion: nil)
            } catch {/* error handling here */
                
                fatalError("Exception: error \(error)")
            }
        }
    }
    
    func deleteIncomesLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        for income in (appDelegate?.incomeList)! {
            
            let recordName = income.value(forKey: XYZAccount.recordId) as? String
            deleteRecordLiset.append(recordName!)
            
            managedContext()?.delete(income)
        }
        
        let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
        zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)

        saveManageContext()
        appDelegate?.incomeList = [XYZAccount]()
        zone.data = appDelegate?.incomeList
        
        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let incomeNavController = tabbarView.viewControllers?[0] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let incomeView = incomeNavController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected")
        }
        
        incomeView.reloadData()
        
        fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone],
                             [zone], {
                                
        })
    }
    
    func deleteExpensesLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        guard let shareRecordNameData = zone.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteShareRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: shareRecordNameData) as? [String]) else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        for expense in (appDelegate?.expenseList)! {
            
            let recordName = expense.value(forKey: XYZExpense.recordId) as? String
            deleteRecordLiset.append(recordName!)
            
            if let shareRecordName = expense.value(forKey: XYZExpense.shareRecordId) as? String {
                
                deleteShareRecordLiset.append(shareRecordName)
            }
            
            managedContext()?.delete(expense)
        }
        
        let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
        zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
        
        let savedDeleteShareRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordLiset )
        zone.setValue(savedDeleteShareRecordLiset, forKey: XYZiCloudZone.deleteShareRecordIdList)
        
        saveManageContext()
        appDelegate?.expenseList = [XYZExpense]()
        zone.data = appDelegate?.expenseList
        
        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? ExpenseTableViewController else {
            
            fatalError("Exception: ExpenseTableViewController is expected")
        }
        
        expenseView.reloadData()
        
        fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone],
                             [zone], {

        })
    }
    
    func deletebudgetsLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZBudget.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        for budget in (appDelegate?.budgetList)! {
            
            let recordName = budget.value(forKey: XYZBudget.recordId) as? String
            deleteRecordLiset.append(recordName!)
            
            managedContext()?.delete(budget)
        }
        
        let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset)
        zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
        
        saveManageContext()
        appDelegate?.budgetList = [XYZBudget]()
        zone.data = appDelegate?.budgetList
        
        guard let splitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
        }
        
        guard let tabbarView = splitView.viewControllers.first as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let budgetNavController = tabbarView.viewControllers?[2] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let budgetView = budgetNavController.viewControllers.first as? BudgetTableViewController else {
            
            fatalError("Exception: ExpenseTableViewController is expected")
        }
        
        budgetView.reloadData()
        
        fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone],
                             [zone],
                             { })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? XYZMainSplitViewController else {
            
            fatalError("Exception: XYZMainSplitViewController is expected" )
        }
        
        if sectionList[indexPath.section].cellList[indexPath.row] == "Export" {
        
            let dateFormatter = DateFormatter();
            
            dateFormatter.dateFormat = "MM-dd-yyyy"
            let datetoday = dateFormatter.string(from: Date())
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let saveIncomeOption = UIAlertAction(title: "Save incomes".localized(), style: .default, handler: { (action) in
                
                let file = AppDelegate.appName + "-income-\(datetoday).csv"
                let text = self.incomeFileContent()
                
                self.saveContent(text, file: file)
            })

            optionMenu.addAction(saveIncomeOption)
            
            let saveExpenseOption = UIAlertAction(title: "Save expenses".localized(), style: .default, handler: { (action) in
                
                let file = AppDelegate.appName + "-expense-\(datetoday).csv"
                let text = self.expenseFileContent()
                
                self.saveContent(text, file: file)
            })
            
            optionMenu.addAction(saveExpenseOption)
            
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:{ (action) in
                
                mainSplitView.popOverAlertController = nil
            })
            
            optionMenu.addAction(cancelAction)
            mainSplitView.popOverAlertController = optionMenu
            
            present(optionMenu, animated: true, completion: nil)
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "DeleteData" {
        
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteIncomes = UIAlertAction(title: "Delete incomes".localized(), style: .default, handler: { (action) in

                self.deleteIncomesLocallyAndFromiCloud()
            })
            
            optionMenu.addAction(deleteIncomes)
            
            let deleteExpenses = UIAlertAction(title: "Delete expenses".localized(), style: .default, handler: { (action) in
                
                self.deleteExpensesLocallyAndFromiCloud()
            })
            
            optionMenu.addAction(deleteExpenses)
            
            let deletebudgets = UIAlertAction(title: "Delete budgets".localized(), style: .default, handler: { (action) in
                
                self.deletebudgetsLocallyAndFromiCloud()
            })
            
            optionMenu.addAction(deletebudgets)
            
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:{ (action) in
                
                mainSplitView.popOverAlertController = nil
            })
            
            optionMenu.addAction(cancelAction)
            mainSplitView.popOverAlertController = optionMenu
            
            present(optionMenu, animated: true, completion: nil)
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "SynciCloud" {
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteOption = UIAlertAction(title: "Update to iCloud".localized(), style: .default, handler: { (action) in
                
                mainSplitView.popOverAlertController = nil
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                appDelegate?.syncWithiCloudAndCoreData()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:{ (action) in
             
                mainSplitView.popOverAlertController = nil
            })
            
            optionMenu.addAction(deleteOption)
            optionMenu.addAction(cancelAction)
            
            mainSplitView.popOverAlertController = optionMenu
            present(optionMenu, animated: true, completion: nil)
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "Lockout" {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.lastAuthenticated = nil
            
            let tableViewController = getMainTableView()
            
            tableViewController.lockout()
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "requiredauthentication" {
        
            /*
            let defaults = UserDefaults.standard;
            let laContext = LAContext()
            var authError: NSError?
            
            if #available(iOS 8.0, macOS 10.12.1, *) {
                
                if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                    
                    laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                             localizedReason: "Authenticate to change the setting" )
                    { (success, error) in
                        
                        if success {
                            
                            DispatchQueue.main.async {
                                
                                let required = defaults.value(forKey: "requiredauthentication") as? Bool ?? false
                                defaults.set(!required, forKey: "requiredauthentication")
                                self.reload()
                            }
                        }
                    }
                }
            }
            */
        } else {
            
            showAbout(indexPath)
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        if let _ = popoverView {
            
            dismiss(animated: false, completion: nil)
            popoverView = nil
        }
        
        guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: error on instantiating ExpenseDetailNavigationController")
        }

        guard let settingDetailTableViewController = settingDetailNavigationController.viewControllers.first as? SettingDetailTableViewController else {
            
            fatalError("Exception: SettingDetailTableViewController is expected")
        }
        
        delegate = settingDetailTableViewController
    
        return settingDetailNavigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        /* DEPRECATED
        for (sectionIndex, section) in tableSectionCellList.enumerated() {
            
            for (rowIndex, _) in section.cellList.enumerated() {
                
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let settingDetailTableViewController = navigationController.viewControllers.first as? SettingDetailTableViewController {
                
                if !settingDetailTableViewController.isPopover {
                    
                    //settingDetailTableViewController.setPopover(true)
                    //navigationController.modalPresentationStyle = .popover
                    //OperationQueue.main.addOperation {
                    //
                    //    self.present(navigationController, animated: true, completion: nil)
                    //}
                }
            }
        }
    
        return true
        */
        
        delegate = nil
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 17.5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionList[section].title
    }

    func incomeFileContent() -> String {

        
        var text = "Number\tBank\tAccountNr\tBalance\tPrincipal\tCurrency\tLastUpdate\n"
        let incomeList = sortAcounts(loadAccounts()!)
        
        for (index, income) in incomeList.enumerated() {
            
            let bank = income.value(forKey: XYZAccount.bank) as? String ?? ""
            let accountNr = income.value(forKey: XYZAccount.accountNr) as? String ?? ""
            let amount = income.value(forKey: XYZAccount.amount) as? Double ?? 0.0
            let currency = income.value(forKey: XYZAccount.currencyCode) as? String ?? ""
            let principal = income.value(forKey: XYZAccount.principal) as? Double ?? 0.0
            let lastUpdate = formattingDate(income.value(forKey: XYZAccount.lastUpdate) as? Date ?? Date(), style: .short )
            
            text = text + "\(index)\t\(bank)\t\(accountNr.isEmpty ? " " : accountNr)\t\(amount)\t\(principal)\t\(currency)\t\(lastUpdate)\n"
        }
        
        return text
    }
    
    func expenseFileContent() -> String {
        
        var currencyCodes: Set<String> = []
        var text = "Number\tDetail\tDate\tCurrency\tAmount\tCategory\n"
        let expenseList = sortExpenses(loadExpenses()!)

        expenseList.forEach { (expense) in
        
            let currencyCode = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
            currencyCodes.insert(currencyCode!)
        }
        
        // now but only year, month, day
        let nowDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let nowDate = Calendar.current.date(from: nowDateComponents)
        
        // 12 month ago and 1st day of the month
        var startDate = Calendar.current.date(byAdding: .month, value: -12, to: nowDate!)
        startDate = Calendar.current.date(byAdding: .day, value: (nowDateComponents.day! * -1) + 1, to: startDate!)
        
        let filteredExpenseList = expenseList.filter { (expense) -> Bool in
        
            let occurrenceDates = expense.getOccurenceDates(until: Date())
            var found = false
            
            for occurDate in occurrenceDates {
                
                if occurDate >= startDate! && occurDate <= Date() {
                    
                    found = true
                    break
                }
            }
            
            return found
        }
        
        var index = 0
        let originalStartDate = startDate!
        
        for currencyCode in currencyCodes.sorted() {

            startDate = originalStartDate
            
            while startDate! <= nowDate! {
                
                let dayfilteredExpenseList = filteredExpenseList.filter { (expense) -> Bool in
                    
                    let expenseCurrencyCode = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
                    var found = false
                    
                    if expenseCurrencyCode == currencyCode {
                        
                        let occurrenceDates = expense.getOccurenceDates(until: startDate!)
                        
                        for occurDate in occurrenceDates {
                            
                            if occurDate >= startDate! && occurDate <= startDate! {
                                
                                found = true
                                break
                            }
                        }
                    }
                    
                    return found
                }
                
                for expense in dayfilteredExpenseList {
                    
                    let detail = expense.value(forKey: XYZExpense.detail) as? String ?? ""
                    let amount = expense.value(forKey: XYZExpense.amount) as? Double ?? 0.0
                    let date = formattingDate(startDate!, style: .short)
                    
                    let category = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
                    
                    text = text + "\(index)\t\(detail)\t\(date)\t\(currencyCode)\t\(amount)\t\(category)\n"
                    
                    index = index + 1
                }
                
                startDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate!)
            }
        }
        
        return text
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
