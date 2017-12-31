//
//  SettingDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/29/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import UIKit

class SettingDetailTableViewController: UITableViewController {

    var isPopover = false
    var tableSectionCellList = [TableSectionCell]()
    
    func setPopover(_ isPopover: Bool) {
        
        self.isPopover = isPopover
        showBarButtons()
    }
    
    func showBarButtons() {
        
        if isPopover {
            
            let backButton = UIButton(type: .custom)
            backButton.setImage(UIImage(named: "BackButton.png"), for: .normal) // Image can be downloaded from here below link
            backButton.setTitle("Back", for: .normal)
            backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
            backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        
        showBarButtons()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @IBAction func backAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
        //let _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // #warning Incomplete implementation, return the number of sections
        return tableSectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // #warning Incomplete implementation, return the number of rows
        return tableSectionCellList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell?
        
        switch  tableSectionCellList[indexPath.section].cellList[indexPath.row] {
            
            case "about":
                cell = tableView.dequeueReusableCell(withIdentifier: "settingDetailAboutCell", for: indexPath)
            
            default:
                break
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if let _ = tableSectionCellList[section].title {
            
            return ( tableSectionCellList.count - 1 ) == section ? 800 : 40
        } else {
            
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
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
