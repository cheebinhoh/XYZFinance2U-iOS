//
//  CalendarCollectionViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/24/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

//private let reuseIdentifier = "calendarCollectionViewCell"

class CalendarCollectionViewController: UICollectionViewController {

    var sectionList = [TableSectionCell]()
    var indexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.collectionView?.register(UICollectionViewCell.self, forSupplementaryViewOfKind: "UICollectionElementKindSectionFooter", withReuseIdentifier: "calendarCollectionFooterView")
        
        addBackButton()
        loadDataIntoSection()
        // Do any additional setup after loading the view.
    }

    func loadDataIntoSection() {
        
        sectionList = [TableSectionCell]()
        
        let headingSection = TableSectionCell(identifier: "heading", title: "", cellList: ["S", "M", "T", "W", "T", "F", "S"], data: nil)
        sectionList.append(headingSection)
        
        var cellList = [String]()
        for index in 1...7 {
            
            cellList.append("\(index)")
        }
        
        for index in 1...5 {
            
            let bodySection = TableSectionCell(identifier: "body\(index)", title: "", cellList: cellList, data: nil)
            sectionList.append(bodySection)
        }
        
        indexPath = IndexPath(row: 0, section: 1)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func addBackButton() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal) // Image can be downloaded from here below link
        backButton.setTitle(" Back", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    // MARK: - IBAction
    
    @IBAction func backAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
        //let _ = self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {

        return sectionList.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return sectionList[section].cellList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calendarCollectionViewCell", for: indexPath) as? CalendarCollectionViewCell else {
            
            fatalError("Exception: calendarCollectionViewCell is expected")
        }
    
        cell.label.text = sectionList[indexPath.section].cellList[indexPath.row]
        
        if let selectedIndexPath = self.indexPath,
            selectedIndexPath.row == indexPath.row && selectedIndexPath.section == indexPath.section {
            
            //cell.layer.cornerRadius = 8
            cell.label.backgroundColor = UIColor.black
            cell.label.textColor = UIColor.white
        } else {
            
            //cell.layer.cornerRadius = 1
            cell.label.backgroundColor = UIColor.clear
            cell.label.textColor = UIColor.black
        }
        // cell.label.text = sectionList[indexPath.section].cellList[indexPath.row]
        // Configure the cell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
 
        switch kind {
        case UICollectionElementKindSectionFooter:
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: "UICollectionElementKindSectionFooter", withReuseIdentifier: "calendarCollectionFooterView", for: indexPath)
            
            let lineView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 1.0))
            //lineView.layer.borderWidth = 1.0
            lineView.backgroundColor = UIColor.lightGray
            reusableView.addSubview(lineView)
            return reusableView
            
        default:
            return UICollectionReusableView()
        }
    }
    
    // MARK: UICollectionViewDelegate

    // Uncomment this method to specify if the specified item should be highlighted during tracking
    /*
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        
        return true
    }
     */

    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        return sectionList[indexPath.section].identifier != "heading"
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        self.indexPath = indexPath
        
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        print("--------- didDeselectItemAt \(indexPath)")
    }

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
