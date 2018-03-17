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
    ExpenseDetailDelegate,
    BudgetExpenseDelegate {
    
    func saveNewExpense(expense: XYZExpense) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList.append(expense)
        
        saveManageContext()
        
        guard let splitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: MainSplitViewController is expected")
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
    
        guard let budgetNavController = tabbarView.viewControllers?[2] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let budgetView = budgetNavController.viewControllers.first as? BudgetTableViewController else {
            
            fatalError("Exception: ExpenseTableViewController is expected")
        }

        expenseView.updateToiCloud(expense)
        expenseList?.append(expense)
        budgetView.reloadData()
        expenseView.reloadData()
        //reloadData()
        
        let date = expense.value(forKey: XYZExpense.date) as? Date
        
        var dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: date!)
        var startDateOfMonthComponent = Calendar.current.dateComponents([.day, .month, .year], from: startDateOfMonth!)

        var monthStep = 0
        
        if dateComponent.year! != startDateOfMonthComponent.year! {

            let yearStep = abs( startDateOfMonthComponent.year! - dateComponent.year! )
            
            monthStep = ( yearStep - 1 ) * 12
            
            if startDateOfMonthComponent.year! < dateComponent.year! {
                
                monthStep = monthStep + ( 12 - startDateOfMonthComponent.month! )
                monthStep = monthStep + ( dateComponent.month! - 0 )
            } else {
                
                monthStep = monthStep + ( startDateOfMonthComponent.month! - 0 )
                monthStep = monthStep + ( 12 - dateComponent.month! )
                monthStep = monthStep * -1
            }
        
        } else if dateComponent.month! != startDateOfMonthComponent.month! {
            
            monthStep = abs(dateComponent.month! - startDateOfMonthComponent.month!)
            if startDateOfMonthComponent.month! > dateComponent.month! {
          
                monthStep = monthStep * -1
            }
        }

        while monthStep != 0 {
            
            if monthStep > 0 {
                
                moveNextPeriod(self)
                monthStep = monthStep - 1
            } else {
                
                movePreviousPeriod(self)
                monthStep = monthStep + 1
            }
        }

        let indexPath = self.indexPath(of: date!)

        if let _ = indexPath {
            
            self.indexPath = indexPath
            reloadData()
        } else {
        
            reloadData()
        }
    }
    
    func saveExpense(expense: XYZExpense) {
        
    }
    
    func cancelExpense() {
        
    }
    
    func deleteExpense(expense: XYZExpense) {
    
        var foundIndex = -1
        
        for (index, item) in (expenseList?.enumerated())! {
            
            if item == expense {
                
                foundIndex = index
                break
            }
        }
        
        expenseList?.remove(at: foundIndex)
        
        self.reloadData()
    }
    
    var budget: XYZBudget?
    var budgetGroup = ""
    var expenseList: [XYZExpense]?
    var sectionList = [TableSectionCell]()
    var selectedExpenseList: [XYZExpense]?
    var indexPath: IndexPath?
    var monthCalendar = Array(repeating: Array(repeating: 0, count: 7), count: 5)
    var date: Date?
    var selectedDate: Date?
    var startDateOfMonth: Date?
    var budgetExpensesTableViewController: BudgetExpensesTableViewController?
    
    @IBOutlet weak var previousPeriod: UIBarButtonItem!
    @IBOutlet weak var nextPeriod: UIBarButtonItem!
    
    func filterExpenseList(of date: Date) -> [XYZExpense] {

        let targetDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let targetDate = Calendar.current.date(from: targetDateComponents)
       
        let todayComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let todayDate = Calendar.current.date(from: todayComponents)
        
        let minOfTargetOrToday = min(todayDate!, targetDate!)

        return (expenseList?.filter({ (expense) -> Bool in
      
            let recurring = XYZExpense.Length(rawValue: expense.value(forKey: XYZExpense.recurring) as? String ?? XYZExpense.Length.none.rawValue )
            
            if XYZExpense.Length.none == recurring {
                
                var theDate = expense.value(forKey: XYZExpense.date) as? Date
                let theDateComponent = Calendar.current.dateComponents([.day, .month, .year], from: theDate!)
                theDate = Calendar.current.date(from: theDateComponent)
                
                return theDate == date
            } else {
                let occurrenceDates = expense.getOccurenceDates(until: minOfTargetOrToday)

                var found = false
                for theDate in occurrenceDates {

                    let occurentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: theDate)
                    let occurentDate = Calendar.current.date(from: occurentDateComponents)

                    found = targetDate! == occurentDate!
                    
                    if found {
                        
                        break
                    }
                }
                
                return found
            }
        }))!
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if sectionList[indexPath.section].identifier == "table" {

            return CGSize(width: 400.0, height: 500.0)
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
    
    func getDate(of indexPath: IndexPath) -> Date? {
        
        if let _ = startDateOfMonth {
            
            guard let cell = collectionView?.cellForItem(at: indexPath) as? CalendarCollectionViewCell else {
                
                fatalError("Exception: CalendarCollectionViewCell is expected")
            }
            
            let day = Int((cell.label.text)!)
            return Calendar.current.date(byAdding: .day,
                                         value:day! - 1,
                                         to: startDateOfMonth!)
        } else {
        
            return nil
        }
    }
    
    @objc
    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        
        let point = sender.location(in: self.collectionView!)
        let tapIndexPath = self.collectionView?.indexPathForItem(at: point)
        
        if nil != tapIndexPath
            && sectionList[(tapIndexPath?.section)!].identifier != "heading"
            && !(sectionList[(tapIndexPath?.section)!].cellList[(tapIndexPath?.row)!].isEmpty) {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let copyUrlOption = UIAlertAction(title: "Add Expense", style: .default, handler: { (action) in
                
                guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: ExpenseDetailNavigationController is expected")
                }
                
                guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                    
                    fatalError("Exception: ExpenseDetailTableViewController is expected" )
                }
                
                mainSplitView.popOverNavigatorController = expenseDetailNavigationController
                
                let currrency = self.budget?.value(forKey: XYZBudget.currency) as? String
                let budgetGroup = self.budget?.value(forKey: XYZBudget.name) as? String
                
                expenseDetailTableView.presetBudgetCategory = budgetGroup
                expenseDetailTableView.presetCurrencyCode = currrency
                expenseDetailTableView.setPopover(delegate: self)
                
                let date = self.getDate(of: tapIndexPath!)
                expenseDetailTableView.presetDate = date
                
                expenseDetailNavigationController.modalPresentationStyle = .popover
                self.present(expenseDetailNavigationController, animated: true, completion: nil)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                
                mainSplitView.popOverAlertController = nil
            })
            
            optionMenu.addAction(copyUrlOption)
            optionMenu.addAction(cancelAction)
            
            mainSplitView.popOverAlertController = optionMenu
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    @objc func swipeGestureResponder(gesture: UIGestureRecognizer) {
   
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            switch swipeGesture.direction {
         
                case .left:
                    moveNextPeriod(self)
                    break
                
                case .right:
                    movePreviousPeriod(self)
                   break
                
                default:
                    break
            }
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        navigationItem.title = budgetGroup
        collectionView?.isScrollEnabled = false
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        self.collectionView?.register(UICollectionViewCell.self, forSupplementaryViewOfKind: "UICollectionElementKindSectionFooter", withReuseIdentifier: "calendarCollectionFooterView")
        
        addBackButton()
        loadDataIntoSection()
        
        let tapDouble = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        tapDouble.numberOfTapsRequired = 2
        self.collectionView?.addGestureRecognizer(tapDouble)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeGestureResponder))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.collectionView?.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeGestureResponder))
        swipeRight.direction = UISwipeGestureRecognizerDirection.left
        self.collectionView?.addGestureRecognizer(swipeLeft)
        // Do any additional setup after loading the view.
    }
    
    func indexPath(of date: Date) -> IndexPath? {
        
        var dateComponent = Calendar.current.dateComponents([.day, .month, .year], from: date)
        var startDateOfMonthComponent = Calendar.current.dateComponents([.day, .month, .year], from: startDateOfMonth!)
        
        if dateComponent.year! == startDateOfMonthComponent.year!
            && dateComponent.month! == startDateOfMonthComponent.month! {
            
            for (sectionIndex, section) in monthCalendar.enumerated() {
                
                for (rowIndex, row) in section.enumerated() {
                    
                    if row == dateComponent.day! {
                        
                        // row is started with day of week heading.
                        return IndexPath(row: rowIndex, section: sectionIndex + 1)
                    }
                }
            }
        }
        
        return nil
    }
    
    func loadDataIntoSection() {
        
        expenseList = expenseList?.filter({ (expense) -> Bool in
        
            let expenseBudgetGroup = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
            
            return budgetGroup == "" || expenseBudgetGroup.lowercased() == budgetGroup.lowercased()
        })
        
        sectionList = [TableSectionCell]()
        
        let headingSection = TableSectionCell(identifier: "heading", title: "", cellList: ["S", "M", "T", "W", "T", "F", "S"], data: nil)
        sectionList.append(headingSection)
        
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
        
        monthCalendar = Array(repeating: Array(repeating: 0, count: 7), count: 5)
        
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
                    
                    monthCalendar[index - 1][weekdayIndex - 1] = dayComponent.day!
                    
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
        
        if !hasNowDate && nil == indexPath {
            
            indexPath = startIndexPath
        }
        
        let tableSection = TableSectionCell(identifier: "table", title: "Expenses", cellList: ["table"], data: nil)
        sectionList.append(tableSection)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
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
            self.budgetExpensesTableViewController?.delegate = self
            
            self.budgetExpensesTableViewController?.monthYearDate = startDateOfMonth
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
