//
//  CalendarCollectionViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/24/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

class CalendarCollectionViewController: UICollectionViewController,
    UICollectionViewDelegateFlowLayout,
    BudgetExpenseDelegate {
        
    func deleteExpense(expense: XYZExpense) {
    
        var foundIndex = -1
        
        for (index, item) in (expenseList?.enumerated())! {
            
            if item == expense {
                
                foundIndex = index
                break
            }
        }
        
        expenseList?.remove(at: foundIndex)
        
        collectionView?.reloadItems(at: [indexPath!])
    }
    
    var budgetGroup = ""
    var expenseList: [XYZExpense]?
    var sectionList = [TableSectionCell]()
    var selectedExpenseList: [XYZExpense]?
    var indexPath: IndexPath?
    var date: Date?
    var selectedDate: Date?
    var startDateOfMonth: Date?
    var budgetExpensesTableViewController: BudgetExpensesTableViewController?
    
    @IBOutlet weak var previousPeriod: UIBarButtonItem!
    @IBOutlet weak var nextPeriod: UIBarButtonItem!
    
    func filterExpenseList(of date: Date) -> [XYZExpense] {
        
        let dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: date)

        return (expenseList?.filter({ (expense) -> Bool in
            
            if let date = expense.value(forKey: XYZExpense.date) as? Date {
             
               let expenseDateComponent = Calendar.current.dateComponents([.day, .month, .year], from: date)
                
               return expenseDateComponent.day! == dateComponent.day!
                      && expenseDateComponent.month! == dateComponent.month!
                      && expenseDateComponent.year! == dateComponent.year!
            } else {
            
                return false
            }
        }))!
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if sectionList[indexPath.section].identifier == "table" {

            return CGSize(width: 400.0, height: 350.0)
        } else {
        
            if collectionView.frame.width >= 414.0 {
                
                return CGSize(width: 50, height: 40.0)
            } else {
                
                return CGSize(width: 40, height: 30.0)
            }
        }
    }
    
    func reloadData() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.expenseList = loadExpenses()!
        
        guard let splitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        guard let tabbarView = splitView.viewControllers.first as? MainUITabBarController else {
            
            fatalError("Exception: MainUITabBarController is expected")
        }
        
        guard let expenseNavController = tabbarView.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? ExpenseTableViewController else {
            
            fatalError("Exception: ExpenseTableViewController is expected")
        }
        
        expenseView.reloadData()
        
        guard let budgetNavController = tabbarView.viewControllers?[2] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let budgetView = budgetNavController.viewControllers.first as? BudgetTableViewController else {
            
            fatalError("Exception: ExpenseTableViewController is expected")
        }
        
        budgetView.reloadData()
        
        loadDataIntoSection()
        collectionView?.reloadData()
    }
    
    @IBAction func movePreviousPeriod(_ sender: Any) {
    
        startDateOfMonth = Calendar.current.date(byAdding: .month,
                                                 value:-1,
                                                 to: startDateOfMonth!)
        selectedExpenseList = nil
        indexPath = nil
        self.reloadData()
    }
    
    @IBAction func moveNextPeriod(_ sender: Any) {
    
        startDateOfMonth = Calendar.current.date(byAdding: .month,
                                          value:1,
                                          to: startDateOfMonth!)
        selectedExpenseList = nil
        indexPath = nil
        self.reloadData()
    }
    
    func setDate(_ date: Date) {
        
        self.date = date
        let dayComponent = Calendar.current.dateComponents([.day,], from: date)
        startDateOfMonth = Calendar.current.date(byAdding: .day,
                                                 value:( -1 * dayComponent.day!) + 1,
                                                 to: date)
        
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: startDateOfMonth!)
        startDateOfMonth = Calendar.current.date(from: dateComponents)
    }
    
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
        
        expenseList = expenseList?.filter({ (expense) -> Bool in
        
            let expenseBudgetGroup = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
            
            return budgetGroup == "" || expenseBudgetGroup.lowercased() == budgetGroup.lowercased()
        })
        
        sectionList = [TableSectionCell]()
        
        let headingSection = TableSectionCell(identifier: "heading", title: "", cellList: ["S", "M", "T", "W", "T", "F", "S"], data: nil)
        sectionList.append(headingSection)
        
        //let dayComponent = Calendar.current.dateComponents([.day,], from: date!)
        var startDate = startDateOfMonth
  
        var dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: startDate!)
        startDate = Calendar.current.date(from: dateComponent)
        
        dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let nowDate = Calendar.current.date(from: dateComponent)
        
        let targetMonthComponent = Calendar.current.dateComponents([.month,], from: startDate!)
     
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        let monthYear = dateFormatter.string(from: startDate!)
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton"), for: .normal) // Image can be downloaded from here below link
        backButton.setTitle(" \(monthYear)", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        //indexPath = nil
        var hasNowDate = false
        var startIndexPath = IndexPath(row: 100, section: 100)
        for index in 1...6 {
      
            var needSection = false
            var cellList = [String]()
            for weekdayIndex in 1...7 {
                
                let weekDayComponent = Calendar.current.dateComponents([.weekday], from: startDate!)
                let monthComponent = Calendar.current.dateComponents([.month,], from: startDate!)

                if weekDayComponent.weekday! == weekdayIndex
                   && monthComponent.month! == targetMonthComponent.month! {
                    
                    if index < startIndexPath.section
                        || (index == startIndexPath.section && (weekdayIndex - 1) < startIndexPath.row ) {
                        
                        startIndexPath = IndexPath(row: weekdayIndex - 1, section: index)
                    }
                    
                    let dayComponent = Calendar.current.dateComponents([.day,], from: startDate!)
                    cellList.append("\(dayComponent.day!)")

                    if startDate! == nowDate! {
                        
                        hasNowDate = true
    
                        if nil == indexPath {
 
                            indexPath = IndexPath(row: weekdayIndex - 1, section: index)
                        }
                    }

                    startDate = Calendar.current.date(byAdding: .day,
                                                      value:1,
                                                      to: startDate!)
                    
                    
                    needSection = true
                } else {
                    
                    cellList.append("")
                }
            }
            
            if needSection {
                
                let bodySection = TableSectionCell(identifier: "body\(index)", title: "", cellList: cellList, data: nil)
                sectionList.append(bodySection)
            }
        }
        
        if !hasNowDate {
            
            indexPath = startIndexPath
        }
        
        let tableSection = TableSectionCell(identifier: "table", title: "Expenses", cellList: ["table"], data: nil)
        sectionList.append(tableSection)
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
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientation = UIInterfaceOrientationMask.all
        
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
        
        let returnCell: UICollectionViewCell
        
        if sectionList[indexPath.section].identifier == "table" {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calendarCollectionTableViewCell", for: indexPath) as? CalendarCollectionTableViewCell else {
                
                fatalError("Exception: calendarCollectionViewCell is expected")
            }
            
            if !cell.stack.subviews.isEmpty {
                
                for subview in cell.stack.subviews {
                    
                    cell.stack.removeArrangedSubview(subview)
                }
                
                self.budgetExpensesTableViewController = nil
            }

            guard let budgetExpensesTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "budgetExpensesTableViewController") as? BudgetExpensesTableViewController else {
            
                fatalError("Exception: budgetExpensesTableViewController is expected")
            }
        
            self.budgetExpensesTableViewController = budgetExpensesTableViewController
            cell.stack.addArrangedSubview(budgetExpensesTableViewController.tableView)
            budgetExpensesTableViewController.delegate = self
            
            self.budgetExpensesTableViewController?.loadData(of: selectedExpenseList)
            self.budgetExpensesTableViewController?.tableView.reloadData()
            
            returnCell = cell
        } else {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "calendarCollectionViewCell", for: indexPath) as? CalendarCollectionViewCell else {
                
                fatalError("Exception: calendarCollectionViewCell is expected")
            }
        
            let dayString = sectionList[indexPath.section].cellList[indexPath.row]
            cell.label.text = dayString
            
            var thisDate: Date?
            var expenseList: [XYZExpense]?
            if sectionList[indexPath.section].identifier != "heading" && !dayString.isEmpty {
                
                let day = Int(dayString)
                let dayComponent = Calendar.current.dateComponents([.day,], from: startDateOfMonth!)
                thisDate = Calendar.current.date(byAdding: .day,
                                                 value:( -1 * dayComponent.day!) + day!,
                                                 to: startDateOfMonth!)
                
                expenseList = filterExpenseList(of: thisDate!)
            }
        
            let dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: Date())
            let nowDate = Calendar.current.date(from: dateComponent)
            
            if let _ = expenseList, !(expenseList?.isEmpty)! {
                
                cell.indicator.backgroundColor = UIColor.blue
            } else {
                
                cell.indicator.backgroundColor = UIColor.clear
            }
            
            if let selectedIndexPath = self.indexPath,
                selectedIndexPath.row == indexPath.row && selectedIndexPath.section == indexPath.section {
                
                selectedDate = thisDate
                selectedExpenseList = expenseList
            
                if nowDate == thisDate {
                    
                    cell.label.backgroundColor = UIColor.red
                    cell.label.textColor = UIColor.white
                } else {
                    
                    cell.label.backgroundColor = UIColor.black
                    cell.label.textColor = UIColor.white
                }
            } else {
                
                cell.label.backgroundColor = UIColor.clear
                
                if nil == thisDate {
                    
                    cell.label.textColor = UIColor.lightGray
                } else if nowDate == thisDate {
                 
                    cell.label.textColor = UIColor.red
                } else {
                    
                    cell.label.textColor = UIColor.black
                }
            }
            
            returnCell = cell
        }
    
        return returnCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
 
        switch kind {
        case UICollectionElementKindSectionFooter:
            let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: "UICollectionElementKindSectionFooter", withReuseIdentifier: "calendarCollectionFooterView", for: indexPath)
            
            let height = 1.0
            
            let lineView = UIView(frame: CGRect(x: 0, y: 0,
                                                width: 500,
                                                height: height))
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
               && !(sectionList[indexPath.section].cellList[indexPath.row].isEmpty)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        self.indexPath = indexPath
        
        collectionView.reloadData()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        print("--------- didDeselectItemAt \(indexPath)")
    }

    
    
    /*
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        let cellsize = CGSize(width: 50.0, height: 40.0)
        
        return cellsize
    }*/
    
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
