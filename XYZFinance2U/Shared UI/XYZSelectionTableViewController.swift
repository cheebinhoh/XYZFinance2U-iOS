//
//  XYZSelectionTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/3/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

protocol XYZSelectionDelegate: class {
    
    func selectedItem(_ item: String?, sender: XYZSelectionTableViewController)
}

class XYZSelectionTableViewController: UITableViewController {

    // MARK: - property
    
    var delegate: XYZSelectionDelegate?
    var tableSectionList = [TableSectionCell]()
    var selectedItem: String?
    var selectionIdentifier: String?
    var hasIndexing: Bool = false
    var sectionTitles = [String]()
    var caseInsensitive = false
    var selectionColors = [UIColor]()
    var readonly = false
    var imageNames: [String]?
    var displayedString = [String]()
    
    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)
        addBackButton()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addBackButton() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal) 
        backButton.setTitle(" \("Back".localized())", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }

    // MARK: - IBAction
    @IBAction func backAction(_ sender: UIButton) {

        delegate?.selectedItem(selectedItem, sender: self)
        dismiss(animated: true, completion: nil)
    }

    func setSelectedItem(_ item: String?,
                         _ displayedItem: String? = nil) {
        
        self.selectedItem = item
        
        navigationItem.title = displayedItem ?? ( self.selectedItem?.localized() ?? "" )
        
        found:
            for (sectionIndex, section) in tableSectionList.enumerated() {
            
                for (rowIndex, code) in section.cellList.enumerated() {
                    
                    if code == item {
                        
                        let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                        
                        break found
                    }
                }
            }
    }
    
    func setSelectionColors(colors: [UIColor]) {
        
        selectionColors = colors
    }
    
    func setSelectionIcons(imageNames: [String]) {
        
        self.imageNames = imageNames
    }
    
    func setSelections(_ sectionIdentifier: String,
                       _ indexing: Bool,
                       _ selection: [String],
                       _ displayedString: [String] = [String]()) {
        
        self.displayedString = displayedString
        
        if indexing {
        
            sectionTitles.append(sectionIdentifier)
        }
        
        var sectionIndex: Int?
        
        for (index, section) in tableSectionList.enumerated() {
            
            if section.identifier == sectionIdentifier {
                
                sectionIndex = index
                break
            }
        }
        
        if sectionIndex == nil {
            
            let newSection = TableSectionCell(identifier: sectionIdentifier, title: sectionIdentifier, cellList: [], data: nil)
            sectionIndex = tableSectionList.count /// tihis is old count before we insert new one below.
            
            tableSectionList.insert(newSection, at: sectionIndex!)
        }
    
        tableSectionList[sectionIndex!].cellList = selection
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return tableSectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                
        return tableSectionList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "selectionItemCell", for: indexPath) as? XYZSelectionItemTableViewCell else {
            
            fatalError("Exception: errpt on creating selectionItemCell")
        }
        
        if displayedString.isEmpty {
            
            cell.label.text = tableSectionList[indexPath.section].cellList[indexPath.row].localized()
        } else {
            
            cell.label.text = displayedString[indexPath.row]
        }
        
        if !selectionColors.isEmpty {
            
            cell.color = selectionColors[indexPath.row]
        }
        
        if let _ = imageNames {
            
            let iconName = imageNames![indexPath.row]
            
            if iconName != "" {
                
                cell.icon.image = UIImage(named: imageNames![indexPath.row])
                cell.icon.image = cell.icon.image?.withRenderingMode(.alwaysTemplate)
                
                if #available(iOS 13.0, *) {
                    
                    cell.icon.image?.withTintColor(UIColor.systemBlue)
                } else {
                    // Fallback on earlier versions
                }
                
            } else {
                
                cell.icon.image = UIImage(named: "bigemptyspace")
            }
        }
        
        if tableSectionList[indexPath.section].cellList[indexPath.row] == self.selectedItem
           || ( caseInsensitive
                && tableSectionList[indexPath.section].cellList[indexPath.row].lowercased() == self.selectedItem?.lowercased() ) {
            
            cell.accessoryType = .checkmark
        } else {
            
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionList[section].title
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {

        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 17.5
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        for (sectionIndex, section) in tableSectionList.enumerated() {
            
            for (rowIndex, _ ) in section.cellList.enumerated() {
                
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                let cell = tableView.cellForRow(at: indexPath)
                cell?.accessoryType = .none
            }
        }
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        selectedItem = tableSectionList[indexPath.section].cellList[indexPath.row];

        let displayedSelectedItem = displayedString.isEmpty ? (selectedItem!).localized() : displayedString[indexPath.row]

        navigationItem.title = displayedSelectedItem
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return sectionTitles.isEmpty ? nil : sectionTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        
        guard let index = sectionTitles.firstIndex(of: title) else {
            
            return -1;
        }
        
        return index
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        return readonly ? nil : indexPath
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