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
    var delegate: SettingDetailTableViewController?
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

        let exportSection = TableSectionCell(identifier: "export", title: "", cellList: ["Export"], data: nil)
        tableSectionCellList.append(exportSection)
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
            
            case "Export" :
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingTableCell", for: indexPath) as? SettingTableViewCell else {
                    
                    fatalError("Exception: error on creating settingTableCell")
                }
                
                newcell.title.text = "Export to icloud drive"
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
        settingDetail.navigationItem.title = "About"
        let footerSection = TableSectionCell(identifier: "footer",
                                             title: "",
                                             cellList: [String](),
                                             data: nil)
        settingDetail.tableSectionCellList.append(footerSection)
        settingDetail.tableView.reloadData()
    }
    
    func showAbout(_ indexPath: IndexPath) {
        
        guard let split = self.parent?.parent?.parent as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected")
        }
        
        if split.isCollapsed {
            
            guard let settingDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: error on instantiating SettingDetailNavigationController")
            }
            
            guard let settingDetail = settingDetailNavigationController.viewControllers.first as? SettingDetailTableViewController else {
                
                fatalError("Exception: SettingDetailTableViewController is expected" )
            }
            
            settingDetailNavigationController.modalPresentationStyle = .popover
            settingDetail.setPopover(true)
            loadSettingDetailTableView(settingDetail, indexPath)
            self.present(settingDetailNavigationController, animated: false, completion: nil)
            
            guard let mainSplitView = self.parent?.parent?.parent as? MainSplitViewController else {
                
                fatalError("Exception: MainSplitViewController is expected")
            }
            
            mainSplitView.popOverNavigatorController = settingDetailNavigationController
        } else {
            
            guard let settingDetail = delegate else {
                
                fatalError("Exception: SettingDetailTableViewController is expedted" )
            }
            
            loadSettingDetailTableView(settingDetail, indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableSectionCellList[indexPath.section].identifier == "export" {
        
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
        } else {
            
            showAbout(indexPath)
        }
        
        //let cell = tableView.cellForRow(at: indexPath)
        //performSegue(withIdentifier: settingList[indexPath.row].segueIdentifier, sender:cell)
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
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
