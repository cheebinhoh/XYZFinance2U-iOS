//
//  XYZMoreTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import os.log
import LocalAuthentication
import CloudKit
import UIKit

class XYZMoreTableViewController: UITableViewController,
    UIDocumentPickerDelegate,
    XYZMoreTextTableViewCellDelegate, XYZSelectionDelegate {
    
    func selectedItem(_ item: String?, sender: XYZSelectionTableViewController) {

        let defaults = UserDefaults.standard;
        defaults.setValue(item, forKey: totalIncomeCurrencyCodeKey)
        
        self.reload()
    }
    
    // MARK: - property
    
    var sectionList = [TableSectionCell]()
    var delegate : UIViewController?
    var popoverView : UIViewController?
    var totalIncomeCurrencyCode : String?
    var totalIncome : Double?
    var lastRateTimestamp : String?
    var rates : [String : Double]?
    var incomeList : [XYZAccount]?
    
    // MARK: - function
    func retrieveExchangeRateAndCalculateTotalIncome() {
        
        let host = "https://api.exchangeratesapi.io/" // "https://api.exchangerate.host/"
        var otherCurrencyCodes = [String]()
        var urlString = host + "latest?base=\(totalIncomeCurrencyCode!)"
        
        guard let incomeList = incomeList else {
            
            return
        }
        
        for income in incomeList {
            
            if let incomeCurrencyCode = income.value(forKey: XYZAccount.currencyCode) as? String {
                
                if incomeCurrencyCode != totalIncomeCurrencyCode! {
                    
                    if !otherCurrencyCodes.contains(incomeCurrencyCode) {
                        
                        otherCurrencyCodes.append(incomeCurrencyCode)
                    }
                }
            }
        }
        
        if otherCurrencyCodes.isEmpty {

            self.calculateTotalIncome()
        } else {
            
            urlString = urlString + "&symbols=" + otherCurrencyCodes.joined(separator: ",")
            
            if let url = URL(string: urlString) {

                print("url : \(url)")

                let configuration = URLSessionConfiguration.ephemeral
                let session = URLSession(configuration: configuration)
                
                session.dataTask(with: url) { data, response, error in
                
                    /*
                    if let _ = error {
                        print("---------- error")
                        self.lastRateTimestamp = nil
                    } else
                    */
                    if let data = data {
                    
                        struct ExchangRateAPIResult : Decodable {
            
                            let rates : [String : Double]
                            let base : String
                            let date : String
                        }
                            
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let res = try? decoder.decode(ExchangRateAPIResult.self, from: data )
                        
                        if let _ = res {
                            
                            self.rates = res?.rates;
                        }
                       
                        self.lastRateTimestamp = res?.date
                        self.calculateTotalIncome()
                    }
                }.resume()
            }
        }
    }
    
    func calculateTotalIncome() {
    
  
        guard let _ = self.lastRateTimestamp else {
            
            self.totalIncome = nil
            return
        }

        self.totalIncome = 0.0
      
        if let incomeList = incomeList {

            for income in incomeList {
                
                let incomeCc = income.value(forKey: XYZAccount.currencyCode) as! String
                let amount = income.value(forKey: XYZAccount.amount) as! Double
                
                let rate = rates?.first(where: {
                    
                    return $0.key == incomeCc
                })

                self.totalIncome = ( self.totalIncome ?? 0.0 )
                    + ( amount / ( rate?.value ?? 1.0 ) )
            }
            
            DispatchQueue.main.async {
            
                self.tableView.reloadData()
            }
        }
    }
    
    func switchChanged(_ value: Bool, _ sender: XYZMoreTableViewCell) {
    
        let defaults = UserDefaults.standard;
        let laContext = LAContext()
        var authError: NSError?
        
        guard let indexPath = tableView.indexPath(for: sender) else {
            
            return
        }
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
        
            case "RequiredAuthentication":
                if #available(iOS 8.0, macOS 10.12.1, *) {
                    
                    if laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                        
                        laContext.evaluatePolicy(.deviceOwnerAuthentication,
                                                 localizedReason: "Authenticate to change the setting".localized() )
                        { (success, error) in
                            
                            DispatchQueue.main.async {
                                
                                if success {
                                    
                                    let required = defaults.value(forKey: requiredAuthenticationKey) as? Bool ?? false
                                    defaults.set(!required, forKey: requiredAuthenticationKey)
                                }
                                
                                self.reload()
                            }
                        }
                    }
                }
                
            case "ToggleShowTotal":
                let showTotalIncome = defaults.value(forKey: showTotalIncomeKey) as? Bool ?? false
                defaults.set(!showTotalIncome, forKey: showTotalIncomeKey)
                
                self.reload()
                
            default:
                fatalError("Invalid option \(sectionList[indexPath.section].cellList[indexPath.row])")
        }
    }
    
    func getMainTableView() -> XYZIncomeTableViewController {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
        
            fatalError("Exception: XYZMainUITabBarController is expected")
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
            let required = defaults.value(forKey: requiredAuthenticationKey) as? Bool ?? false
            var celllist = ["RequiredAuthentication"]
            
            if required {
                
                celllist.append("Lockout")
            }
            
            let logoutSection = TableSectionCell(identifier: "authentication", title: "", cellList: celllist, data: nil)
            sectionList.append(logoutSection)
        }
        
        let defaults = UserDefaults.standard;
        totalIncomeCurrencyCode = defaults.value(forKey: totalIncomeCurrencyCodeKey) as? String
        if totalIncomeCurrencyCode == nil {
            
            totalIncomeCurrencyCode = Locale.current.currencyCode
            defaults.setValue(totalIncomeCurrencyCode, forKey: totalIncomeCurrencyCodeKey)
        }
        
        let showTotal = defaults.value(forKey: showTotalIncomeKey) as? Bool ?? false
        
        var totalCellList = ["ToggleShowTotal"]
        if showTotal {
            
            totalCellList.append("TotalIncome")
            totalCellList.append("TotalIncomeCurrency")
        }
        
        let total = TableSectionCell(identifier: "total", title: "",
                                     cellList: totalCellList, data: nil)
        sectionList.append(total)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        incomeList = appDelegate?.incomeList
        
        retrieveExchangeRateAndCalculateTotalIncome()
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
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Retrieve latest exchange rate".localized())
        refreshControl.addTarget(self, action: #selector(refreshExchangeRate), for: .valueChanged)
        
        // this is the replacement of implementing: "collectionView.addSubview(refreshControl)"
        tableView.refreshControl = refreshControl
    }

    @objc func refreshExchangeRate(refreshControl: UIRefreshControl) {
    
        self.reload()
        
        refreshControl.endRefreshing()
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
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                newcell.title.text = "About".localized()
                newcell.removeUISwitch()
                cell = newcell
            
            case "Export" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                newcell.title.text = "Save to file".localized()
                newcell.accessoryType = .none
                newcell.removeUISwitch()
                cell = newcell
            
            case "SynciCloud" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                newcell.title.text = "Update to iCloud".localized()
                newcell.accessoryType = .none
                newcell.removeUISwitch()
                cell = newcell
            
            case "DeleteData":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                newcell.title.text = "Delete data".localized()
                newcell.accessoryType = .none
                newcell.removeUISwitch()
                cell = newcell
            
            case "Lockout" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                newcell.title.text = "Lock out".localized()
                newcell.accessoryType = .none
                newcell.removeUISwitch()
                cell = newcell

            case "RequiredAuthentication" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }

                let defaults = UserDefaults.standard;
                let required = defaults.value(forKey: requiredAuthenticationKey) as? Bool ?? false
                
                newcell.title.text = "Require authentication".localized()
                newcell.accessoryType = .none
                
                if nil == newcell.optionSwitch {
                    
                    newcell.addUISwitch()
                    newcell.delegate = self
                }
                
                newcell.optionSwitch.isOn = required
                
                // newcell.accessoryType = required ? .checkmark : .none
                cell = newcell
            
            case "ToggleShowTotal" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }

                let defaults = UserDefaults.standard;
                let showTotal = defaults.value(forKey: showTotalIncomeKey) as? Bool ?? false
                
                newcell.title.text = "Show total income".localized()
                newcell.accessoryType = .none
                
                if nil == newcell.optionSwitch {
                    
                    newcell.addUISwitch()
                    newcell.delegate = self
                }
                
                newcell.optionSwitch.isOn = showTotal
                
                // newcell.accessoryType = required ? .checkmark : .none
                cell = newcell
                
            case "TotalIncome":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "moreTableViewCell", for: indexPath) as? XYZMoreTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableViewCell")
                }
                
                if let _ = totalIncome {

                    newcell.title.text = formattingCurrencyValue(of: totalIncome ?? 0.0,
                                                                 as: totalIncomeCurrencyCode ?? Locale.current.currencyCode! )
                } else {
                  
                    newcell.title.text = "-"
                }
                
                if let _ = lastRateTimestamp {
                
                    newcell.title.text = newcell.title.text! + "   (\(lastRateTimestamp!))"
                }
                
                newcell.accessoryType = .none
                newcell.removeUISwitch()
                cell = newcell
                
            case "TotalIncomeCurrency":
                guard let currencycell = tableView.dequeueReusableCell(withIdentifier: "moreSelectionTableViewCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: incomeDetailSelectionCell is failed to be created")
                }
                
                currencycell.setSelection( totalIncomeCurrencyCode! )
                currencycell.selectionStyle = .none
                
                cell = currencycell
            
            default:
                fatalError("Exception: \(sectionList[indexPath.section].cellList[indexPath.row]) is not supported")
        }
        
        return cell!
    }
    
    func loadSettingDetailTableView(_ settingDetail: XYZMoreDetailTableViewController, _ indexPath: IndexPath) {
        
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
        
        var settingDetail: XYZMoreDetailTableViewController?
        
        if let _ = delegate, delegate is XYZMoreDetailTableViewController {
            
            settingDetail = delegate as? XYZMoreDetailTableViewController
        } else {
            
            guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "settingDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating settingDetailNavigationController")
            }
            
            settingDetail = settingDetailNavigationController.viewControllers.first as? XYZMoreDetailTableViewController

            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                
                fatalError("Exception: XYZMainUITabBarController is expected")
            }
            
            tabBarController.popOverAlertController = settingDetailNavigationController
            settingDetail?.showBarButtons()
            popoverView = settingDetail
            self.present(settingDetailNavigationController, animated: false, completion: nil)
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
                guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                    
                    fatalError("Exception: XYZMainUITabBarController is expected" )
                }
                
                tabBarController.popOverAlertController = uiDocumentPicker
                
                self.present(uiDocumentPicker, animated: true, completion: nil)
            } catch {/* error handling here */
                
                fatalError("Exception: error \(error)")
            }
        }
    }
    
    func deleteIncomesLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZAccount.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        for income in (appDelegate?.incomeList)! {
            
            let recordName = income.value(forKey: XYZAccount.recordId) as? String
            deleteRecordList.append(recordName!)
            
            managedContext()?.delete(income)
        }
        
        let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
        zone.setValue(savedDeleteRecordList, forKey: XYZiCloudZone.deleteRecordIdList)

        saveManageContext()
        appDelegate?.incomeList = [XYZAccount]()
        zone.data = appDelegate?.incomeList
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let incomeNavController = tabBarController.viewControllers?[0] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let incomeView = incomeNavController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected")
        }
        
        incomeView.reloadData()
        
        fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                             zones: [ckrecordzone],
                             iCloudZones: [zone], completionblock: {
                                
        })
    }
    
    func deleteExpensesLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
    
        guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        guard let shareRecordNameData = zone.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteShareRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(shareRecordNameData) as? [String] else {
            
            fatalError("Exception: deleteShareRecordList is expected as [String]")
        }
        
        for expense in (appDelegate?.expenseList)! {
            
            let recordName = expense.value(forKey: XYZExpense.recordId) as? String
            deleteRecordList.append(recordName!)
            
            if let shareRecordName = expense.value(forKey: XYZExpense.shareRecordId) as? String {
                
                deleteShareRecordList.append(shareRecordName)
            }
            
            managedContext()?.delete(expense)
        }
        
        let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
        zone.setValue(savedDeleteRecordList, forKey: XYZiCloudZone.deleteRecordIdList)
        
        let savedDeleteShareRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordList, requiringSecureCoding: false)
            
        zone.setValue(savedDeleteShareRecordList, forKey: XYZiCloudZone.deleteShareRecordIdList)
        
        saveManageContext()
        appDelegate?.expenseList = [XYZExpense]()
        zone.data = appDelegate?.expenseList
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabBarController.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
            
            fatalError("Exception: XYZExpenseTableViewController is expected")
        }
        
        expenseView.reloadData()
        
        fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                             zones: [ckrecordzone],
                             iCloudZones: [zone], completionblock: {

        })
    }
    
    func deletebudgetsLocallyAndFromiCloud() {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZBudget.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
            
            fatalError("Exception: iCloudZoen is expected")
        }
        
        guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
            
            fatalError("Exception: data is expected for deleteRecordIdList")
        }
        
        guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
            
            fatalError("Exception: deleteRecordList is expected as [String]")
        }
        
        for budget in (appDelegate?.budgetList)! {
            
            let recordName = budget.value(forKey: XYZBudget.recordId) as? String
            deleteRecordList.append(recordName!)
            
            managedContext()?.delete(budget)
        }
        
        let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
        zone.setValue(savedDeleteRecordList, forKey: XYZiCloudZone.deleteRecordIdList)
        
        saveManageContext()
        appDelegate?.budgetList = [XYZBudget]()
        zone.data = appDelegate?.budgetList
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let budgetNavController = tabBarController.viewControllers?[2] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let budgetView = budgetNavController.viewControllers.first as? XYZBudgetTableViewController else {
            
            fatalError("Exception: XYZBudgetTableViewController is expected")
        }
        
        budgetView.reloadData()
        
        fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                             zones: [ckrecordzone],
                             iCloudZones: [zone],
                             completionblock: { })
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected" )
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
                
                tabBarController.popOverAlertController = nil
            })
            
            optionMenu.addAction(cancelAction)
            tabBarController.popOverAlertController = optionMenu
            
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
                
                tabBarController.popOverAlertController = nil
            })
            
            optionMenu.addAction(cancelAction)
            tabBarController.popOverAlertController = optionMenu
            
            present(optionMenu, animated: true, completion: nil)
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "SynciCloud" {
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteOption = UIAlertAction(title: "Update to iCloud".localized(), style: .default, handler: { (action) in
                
                tabBarController.popOverAlertController = nil
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                appDelegate?.syncWithiCloudAndCoreData()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:{ (action) in
             
                tabBarController.popOverAlertController = nil
            })
            
            optionMenu.addAction(deleteOption)
            optionMenu.addAction(cancelAction)
            
            tabBarController.popOverAlertController = optionMenu
            present(optionMenu, animated: true, completion: nil)
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "Lockout" {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.lastAuthenticated = nil
            
            let tableViewController = getMainTableView()
            
            tableViewController.lockout()
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "RequiredAuthentication" {
        
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "ToggleShowTotal" {
    
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "TotalIncome" {
    
            
        } else if sectionList[indexPath.section].cellList[indexPath.row] == "TotalIncomeCurrency" {

            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "currency"
            
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
            selectionTableViewController.setSelectedItem(totalIncomeCurrencyCode ?? "USD")
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)
        } else {
            
            showAbout(indexPath)
        }
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
            
            guard let _ = occurrenceDates.firstIndex(where: {
                
                return $0 >= startDate! && $0 <= Date()
            }) else {
                
                return false
            }
            
            return true
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
                        
                        let index = occurrenceDates.firstIndex(where: {
                            
                            return $0 >= startDate! && $0 <= startDate!
                        })
                        
                        found = nil != index
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
