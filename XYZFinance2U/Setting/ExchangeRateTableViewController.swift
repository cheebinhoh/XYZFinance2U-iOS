//
//  ExchangeRateTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/20/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class ExchangeRateTableViewController: UITableViewController {

    // MARK: - property
    
    var isPopover = false
    var tableSectionCellList = [TableSectionCell]()
    var exchangeRates: [XYZExchangeRate]?
    var currencyCodes: [String]?
    
    func setPopover(_ isPopover: Bool) {
        
        self.isPopover = isPopover
        showBarButtons()
    }
    
    func showBarButtons() {
        
        if isPopover {
            
            let backButton = UIButton(type: .custom)
            backButton.setImage(UIImage(named: "BackButton"), for: .normal)
            backButton.setTitle(" Back", for: .normal)
            backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
            backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
            
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
        //let _ = self.navigationController?.popViewController(animated: true)
    }
    
    func loadDataInTableSectionCell() {
        
        tableSectionCellList.removeAll()
        
        if let _ = exchangeRates, let _ = currencyCodes {
        
            for currencyCode in currencyCodes! {
                
                var sectionExchangeRates = [XYZExchangeRate]()
                
                for exchangeRate in exchangeRates! {
                    
                    let base = exchangeRate.value(forKey: XYZExchangeRate.base) as? String
                    
                    if base == currencyCode {
                        
                        sectionExchangeRates.append(exchangeRate)
                    }
                }
                
                let section = TableSectionCell(identifier: currencyCode,
                                               title: currencyCode,
                                               cellList: [],
                                               data: sectionExchangeRates)
                tableSectionCellList.append(section)
            }
        }
        
        print("--- \(tableSectionCellList)")
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
