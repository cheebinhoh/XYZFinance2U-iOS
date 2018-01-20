//
//  SettingTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/14/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIDocumentPickerDelegate {
    
    // MARK: - property
    
    var tableSectionCellList = [TableSectionCell]()
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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.tableFooterView = UIView(frame: .zero)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let mainSection = TableSectionCell(identifier: "main", title: "", cellList: ["About"], data: nil)
        tableSectionCellList.append(mainSection)
        
        let helperSection = TableSectionCell(identifier: "ex", title: "", cellList: ["ExchangeRate"], data: nil)
        tableSectionCellList.append(helperSection)

        let exportSection = TableSectionCell(identifier: "export", title: "", cellList: ["Export", "SynciCloud"], data: nil)
        tableSectionCellList.append(exportSection)
        
        let logoutSection = TableSectionCell(identifier: "lockout", title: "", cellList: ["lockout"], data: nil)
        tableSectionCellList.append(logoutSection)
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return tableSectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableSectionCellList[section].cellList.count //settingList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        switch tableSectionCellList[indexPath.section].cellList[indexPath.row] {
            
            case "About" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = tableSectionCellList[indexPath.section].cellList[indexPath.row]
                cell = newcell
            
            case "ExchangeRate" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Foreign exchange rate"
                cell = newcell
            
            case "Export" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Export to iCloud drive"
                newcell.accessoryType = .none
                cell = newcell
            
            case "SynciCloud" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Sync with iCloud"
                newcell.accessoryType = .none
                cell = newcell
            
        case "lockout" :
            guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                
                fatalError("Exception: error on creating settingTableCell")
            }
            
            newcell.title.text = "lock out"
            newcell.accessoryType = .none
            cell = newcell

            default:
                fatalError("Exception: \(tableSectionCellList[indexPath.section].cellList[indexPath.row]) is not supported")
        }
        
        return cell!
    }
    
    func loadSettingDetailTableView(_ settingDetail: SettingDetailTableViewController, _ indexPath: IndexPath) {
        
        settingDetail.tableSectionCellList.removeAll()

        let aboutSection = TableSectionCell(identifier: "about", title: "", cellList: ["about"], data: nil)
        settingDetail.tableSectionCellList.append(aboutSection)
        
        let disclaimerSection = TableSectionCell(identifier: "disclaimer", title: "", cellList: ["disclaimer"], data: nil)
        settingDetail.tableSectionCellList.append(disclaimerSection)
        
        settingDetail.navigationItem.title = "About"
        let footerSection = TableSectionCell(identifier: "footer",
                                             title: "",
                                             cellList: [String](),
                                             data: nil)
        settingDetail.tableSectionCellList.append(footerSection)
        settingDetail.tableView.reloadData()
    }
    
    func showExchangeRate(_ indexPath: IndexPath) {
        
        var settingDetail: ExchangeRateTableViewController?
        
        if let _ = delegate, delegate is ExchangeRateTableViewController {
            
            settingDetail = delegate as? ExchangeRateTableViewController
        } else {
            
            guard let exDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExchangeRateNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating SettingDetailNavigationController")
            }
            
            settingDetail = exDetailNavigationController.viewControllers.first as? ExchangeRateTableViewController
            
            guard let splitView = self.parent?.parent?.parent as? MainSplitViewController else {
                
                fatalError("Exception: MainSplitViewController is expected")
            }
            
            if splitView.isCollapsed {
                
                settingDetail?.setPopover(true)
                popoverView = settingDetail
                self.present(exDetailNavigationController, animated: false, completion: nil)
            } else {
                
                delegate = settingDetail!
                splitView.viewControllers.remove(at: 1)
                splitView.viewControllers.insert(exDetailNavigationController, at: 1)
            }
        }
        
        if nil != settingDetail {
            
            let aContext = managedContext()
            var exchangeRates = loadExchangeRates()
            var exchangeRatesNeed = [XYZExchangeRate]()
            let incomeList = loadAccounts()
            var currencyCodes = [String]()
            
            for income in incomeList! {
                
                let currencyCode = income.value(forKey: XYZAccount.currencyCode) as? String
                
                if !currencyCodes.contains(currencyCode!) {
                    
                    currencyCodes.append(currencyCode!)
                }
            }
            
            for currencyCodeFrom in currencyCodes {
                
                for currencyCodeTo in currencyCodes {
                    
                    if currencyCodeFrom != currencyCodeTo {
                        
                        let id = "\(currencyCodeFrom)-\(currencyCodeTo)"
                        
                        var exchangeRateToBeUpdated: XYZExchangeRate?
                        
                        for exchangeRate in exchangeRates! {
                            
                            if id == ( exchangeRate.value(forKey: XYZExchangeRate.recordId) as? String ?? "") {
                                
                                exchangeRateToBeUpdated = exchangeRate
                                break
                            }
                        }
                        
                        if nil == exchangeRateToBeUpdated {
                            
                            exchangeRateToBeUpdated = XYZExchangeRate(id,
                                                                      currencyCodeFrom,
                                                                      currencyCodeTo,
                                                                      0.0,
                                                                      context: aContext)
                            
                            exchangeRates?.append(exchangeRateToBeUpdated!)
                        } else {
                            
                            // do nothing
                        }
                        
                        exchangeRatesNeed.append(exchangeRateToBeUpdated!)
                        
                        let url = URL(string: "https://api.fixer.io/latest?base=\(currencyCodeFrom)&symbols=\(currencyCodeTo)")
                        
                        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                            
                            do {
                                
                                if nil != error {
                                    
                                    print("-------- error = \(String(describing: error))")
                                } else {
                                    
                                    let dictResult = try JSONSerialization.jsonObject(with: data!,
                                                                                  options: JSONSerialization.ReadingOptions.mutableContainers) as! [String: Any]
                                    let rates = dictResult["rates"] as! [String: Double]
                                    let value = rates[currencyCodeTo]

                                    exchangeRateToBeUpdated?.setValue(value, forKey: XYZExchangeRate.rate)

                                    DispatchQueue.main.async {

                                        settingDetail?.reloadExchangeRate( exchangeRateToBeUpdated! )
                                    }
                                }
                            } catch {
                                
                                print("-------- error in JSONSerialization = \(error)")
                            }
                        }
                        
                        task.resume()
                    }
                }
            }
            
            for exchangeRate in exchangeRates! {
                
                if !exchangeRatesNeed.contains(exchangeRate) {
                    
                    aContext?.delete(exchangeRate)
                }
            }
            
            settingDetail?.exchangeRates = exchangeRatesNeed
            settingDetail?.currencyCodes = currencyCodes
            settingDetail?.loadDataInTableSectionCell()
            
            saveManageContext()
        }
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

            guard let splitView = self.parent?.parent?.parent as? MainSplitViewController else {
                
                fatalError("Exception: MainSplitViewController is expected")
            }
            
            if splitView.isCollapsed {
                
                settingDetail?.setPopover(true)
                popoverView = settingDetail
                self.present(settingDetailNavigationController, animated: false, completion: nil)
            } else {
                
                delegate = settingDetail!
                splitView.viewControllers.remove(at: 1)
                splitView.viewControllers.insert(settingDetailNavigationController, at: 1)
            }
        }
        
        loadSettingDetailTableView(settingDetail!, indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableSectionCellList[indexPath.section].cellList[indexPath.row] == "Export" {
        
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteOption = UIAlertAction(title: "Export to icloud drive", style: .default, handler: { (action) in
                
                let file = AppDelegate.appName + "-export.csv"
                let text = self.incomeFileContent()
                
                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    
                    let fileURL = dir.appendingPathComponent(file)
                    
                    //writing
                    do {
                        try text.write(to: fileURL, atomically: false, encoding: .utf8)
                        
                        let uiDocumentPicker = UIDocumentPickerViewController(urls: [fileURL], in: UIDocumentPickerMode.exportToService)
                        uiDocumentPicker.delegate = self
                        uiDocumentPicker.modalPresentationStyle = UIModalPresentationStyle.formSheet
                        self.present(uiDocumentPicker, animated: true, completion: nil)
                    } catch {/* error handling here */
                        
                        fatalError("Exception: error \(error)")
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
            
            optionMenu.addAction(deleteOption)
            optionMenu.addAction(cancelAction)
            
            present(optionMenu, animated: true, completion: nil)
        } else if tableSectionCellList[indexPath.section].cellList[indexPath.row] == "SynciCloud" {
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let deleteOption = UIAlertAction(title: "Sync with iCloud", style: .default, handler: { (action) in
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                appDelegate?.syncWithiCloudAndCoreData()
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
            
            optionMenu.addAction(deleteOption)
            optionMenu.addAction(cancelAction)
            
            present(optionMenu, animated: true, completion: nil)
        } else if tableSectionCellList[indexPath.section].identifier == "lockout" {
            
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
            
            guard let tableViewController = navController.viewControllers.first as? IncomeTableViewController else {
                
                fatalError("Exception: IncomeTableViewController is expected" )
            }
            
            tableViewController.lockout()
        } else if tableSectionCellList[indexPath.section].cellList[indexPath.row] == "ExchangeRate" {
            
            showExchangeRate(indexPath)
            
            // we either provide a way to fetch the rate and then update income table, or we enhance
            // income table to allow us to fetch the rate.
            /*
            let url = URL(string: "https://api.fixer.io/latest?base=USD&symbols=MYR")
            
            let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                
                print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "-")
            }

            task.resume()
             */
        } else {
            
            showAbout(indexPath)
        }
        
        //let cell = tableView.cellForRow(at: indexPath)
        //performSegue(withIdentifier: settingList[indexPath.row].segueIdentifier, sender:cell)
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
        
        if section == 0 {
            
            return 35
        } else {
            
            return 17.5
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
    }

    func incomeFileContent() -> String {

        var text = "Number\tBank\tAccountNr\tBalance\tCurrency\tLastUpdate\n"
        let incomeList = loadAccounts()!.sorted() {
            
            (acc1, acc2) in
            
            return ( acc1.value(forKey: XYZAccount.sequenceNr) as! Int ) < ( acc2.value(forKey: XYZAccount.sequenceNr) as! Int)
        }
        
        for (index, income) in incomeList.enumerated() {
            
            let bank = income.value(forKey: XYZAccount.bank) as? String ?? ""
            let accountNr = income.value(forKey: XYZAccount.accountNr) as? String ?? ""
            let amount = income.value(forKey: XYZAccount.amount) as? Double ?? 0.0
            let currency = income.value(forKey: XYZAccount.currencyCode) as? String ?? ""
            let lastUpdate = formattingDate(date: income.value(forKey: XYZAccount.lastUpdate) as? Date ?? Date(), .short )
            
            text = text + "\(index)\t\(bank)\t\(accountNr.isEmpty ? " " : accountNr)\t\(amount)\t\(currency)\t\(lastUpdate)\n"
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
