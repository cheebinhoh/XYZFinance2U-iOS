//
//  XYZMoreDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/29/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

class XYZMoreDetailTableViewController: UITableViewController {

    // MARK: - property
    
    var tableSectionCellList = [TableSectionCell]()
    
    // MARK: - function
    
    func showBarButtons() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal)
        backButton.setTitle(" \("Back".localized())", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
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
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return tableSectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableSectionCellList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell?

        switch  tableSectionCellList[indexPath.section].cellList[indexPath.row] {
            
            case "about":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingDetailAboutCell", for: indexPath) as? XYZMoreDetailAboutTableViewCell else {
                    
                    fatalError("Exception: errpr on creating XYZMoreDetailAboutTableViewCell")
                }
                
                let textVersion
                    = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                
                let textHeading = """
                
                \(AppDelegate.appName)
                """
                
                let headingAttributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.font: newcell.content.font!,
                                                                         NSAttributedString.Key.link: "https://apps.apple.com/us/app/xyzfinance2u-finance/id1341502993"]
                let headingAttributeText = NSMutableAttributedString(string: textHeading, attributes: headingAttributes)
   
                var attributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.font: newcell.content.font!]
                
                if #available(iOS 13.0, *) {
                    
                    attributes?[NSAttributedString.Key.foregroundColor] = UIColor.label
                } else {
                    
                    // Fallback on earlier versions
                }
                
                let authorPreText = """
                (\(textVersion)) \("was created by ".localized())
                """
                
                let attributeAuthorPreText = NSAttributedString(string: authorPreText, attributes: attributes)
                headingAttributeText.append(attributeAuthorPreText)

                let authorText = """
                \("Chee Bin Hoh".localized())

                """
                
                let authorTextAttributes: [NSAttributedString.Key: Any]? = [NSAttributedString.Key.font: newcell.content.font!,
                                                                            NSAttributedString.Key.link: "https://www.linkedin.com/in/cheebinhoh"]
                
                let attributeAuthorText = NSAttributedString(string: authorText, attributes: authorTextAttributes)
                headingAttributeText.append(attributeAuthorText)

                
                let copyRightText = """
                
                \u{A9} \("2017 - 2020 Chee Bin Hoh, All rights reserved.".localized())

                """
                
                let attributeCopyRightText = NSAttributedString(string: copyRightText, attributes: attributes)
                headingAttributeText.append(attributeCopyRightText)
                
                newcell.content.attributedText = headingAttributeText

                cell = newcell
            
            case "credit":
                guard let newcell = tableView.dequeueReusableCell(withIdentifier: "settingDetailAboutCell", for: indexPath) as? XYZMoreDetailAboutTableViewCell else {
                    
                    fatalError("Exception: errpr on creating XYZMoreDetailAboutTableViewCell")
                }
                
                let text = """
                
                \("The icons are from Noun Project by".localized()) Yoraslav Samoylov, Sumhi_icon, Shmidt Sergey, Sandy Priyasa, Sophia Bai, ProSymbols, Mike Ashley, Krishna, Gregor Cresnar, Dinosoft Lab, Delwar Hossain, Arien Coquet.

                \("The foreign exchange rate is from".localized()) \(exchangeAPIWeb). \(
                "It is a free service and use it at your discretion.".localized())

                """
                
                newcell.content.text = text
                cell = newcell
            
                default:
                    break
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 17.5
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
