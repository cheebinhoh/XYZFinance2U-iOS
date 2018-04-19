//
//  ExpenseTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import CoreData
import CloudKit

// MARK: - protocol
protocol ExpenseTableViewDelegate: class {
    
    func expenseSelected(newExpense: XYZExpense?)
    func expenseDeleted(deletedExpense: XYZExpense)
}

class ExpenseTableViewController: UITableViewController,
    UISplitViewControllerDelegate,
    UIViewControllerPreviewingDelegate,
    UISearchControllerDelegate,
    UISearchBarDelegate,
    ExpenseDetailDelegate,
    ExpenseTableViewMonthChange {
    
    func change(_ monthYear: Date!) {

        if let _ = monthYear {
        
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM, YY"
            
            navigationItem.title = "Expenses of \((formatter.string(from: monthYear!)))"
        } else {
            
            filteredExpenseList = nil
            navigationItem.title = "Expenses"
        }
        
        filteredMonthYear = monthYear
        
        reloadData()
    }
    
    func cancelExpense() {
    
    }
    
    // MARK: - property
    weak var searchBar: UISearchBar?
    var filteredMonthYear: Date!
    var searchText: String? = nil
    var searchActive = false
    var currencyCodes = [String]()
    var sectionList = [TableSectionCell]()
    var sectionMonthYearList = [Date]()
    var filteredExpenseList: [XYZExpense]?
    var delegate: ExpenseTableViewDelegate?
    var isPopover = false
    var isCollapsed: Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        return mainSplitView.isCollapsed
    }
    
    // MARK: - IBAction
    @IBAction func navigationTap(_ sender: UITapGestureRecognizer) {
     
        print("****** double tap")
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
            
            fatalError("Exception: ExpenseDetailTableViewController is expected" )
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        mainSplitView.popOverNavigatorController = expenseDetailNavigationController
        
        expenseDetailTableView.setPopover(delegate: self)
        expenseDetailTableView.currencyCodes = currencyCodes
        isPopover = true
        
        expenseDetailNavigationController.modalPresentationStyle = .popover
        self.present(expenseDetailNavigationController, animated: true, completion: nil)
    }
    
    /* DEPRECATED: we do not need it anymore
    @IBAction func unwindToExpenseTableView(sender: UIStoryboardSegue)
    {
        modalEditing = false
        guard let expenseDetail = sender.source as? ExpenseDetailTableViewController, let expense = expenseDetail.expense else  
        {
            return
        }
        
        if tableView.indexPathForSelectedRow == nil
        {
            expenseList.append(expense)
        }
        
        saveManageContext()
        
        reloadData()
    }
     */
    
    // MARK: - 3d touch delegate (peek & pop)
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        
        guard let viewController = viewControllerToCommit as? ExpenseDetailViewController else {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }
        
        if let _ = viewController.expense {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverAlertController = nil
            
            tableView(tableView, didSelectRowAt: viewController.indexPath!)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if let indexPath = tableView.indexPathForRow(at: location), sectionList[indexPath.section].identifier != "searchBar" {
    
            guard let viewController = storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailViewController") as? ExpenseDetailViewController else  {
                
                fatalError("Exception: IncomeDetailViewController is expected")
            }

            let cell = tableView.cellForRow(at: indexPath)
            
            viewController.preferredContentSize = CGSize(width: 0.0, height: 110)
            previewingContext.sourceRect = (cell?.frame)!
            
            guard let sectionExpenseList = sectionList[(indexPath.section)].data as? [XYZExpense] else {
                
                fatalError("Exception: [XYZAccount] is expected")
            }
            
            viewController.expense = sectionExpenseList[(indexPath.row)]
            viewController.indexPath = indexPath

            return viewController
        }
        else {
            
            return nil
        }
    }
    
    //MARK: - function
    
    func sectionTotal(_ section: Int) -> ( Double, String? ) {
        
        var total = 0.0
        let expenseList = sectionList[section].data as? [XYZExpense]
        var usedCurrencyCode: String?
        var hasMultipleCurrency = false
        
        for expense in expenseList! {
        
            let currency = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
            if usedCurrencyCode == nil {
                
                usedCurrencyCode = currency
            } else if usedCurrencyCode != currency {
                
                hasMultipleCurrency = true
            }
            
            let amount = expense.value(forKey: XYZExpense.amount) as? Double
            
            total = total + amount!
        }
        
        return ( total, hasMultipleCurrency ? nil : usedCurrencyCode )
    }
    
    func delete(of indexPath:IndexPath) {
        
        let aContext = managedContext()
        
        var sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
        
        let oldExpense = sectionExpenseList?.remove(at: indexPath.row)
        self.sectionList[indexPath.section].data = sectionExpenseList
        
        let isSoftDelete = self.softDeleteExpense(expense: oldExpense!)
        
        saveManageContext()
        
        if isSoftDelete {
            
            self.updateToiCloud(oldExpense!)
        } else {
            
            self.delegate?.expenseDeleted(deletedExpense: oldExpense!)
            aContext?.delete(oldExpense!)
    
            self.loadExpensesFromSections()
            self.reloadData()
            
            self.updateToiCloud(nil)
        }
    }
    
    func indexPath(of expense:XYZExpense) -> IndexPath? {
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
            if section.identifier != "searchBar" {
            
                let sectionExpenseList = section.data as? [XYZExpense]
                for (rowIndex, cell) in (sectionExpenseList?.enumerated())! {  //(section.expenseList?.enumerated())! {
                    
                    if cell == expense {
                        
                        return IndexPath(row: rowIndex, section: sectionIndex)
                    }
                }
            }
        }
        
        return nil
    }
    
    func deleteExpense(expense: XYZExpense) {
        
        if let selectedIndexPath = indexPath(of: expense) {
            
            let aContext = managedContext()
            var sectionExpenseList = sectionList[selectedIndexPath.section].data as? [XYZExpense]
            
            let oldExpense = sectionExpenseList?.remove(at: selectedIndexPath.row)
            sectionList[selectedIndexPath.section].data = sectionExpenseList
            
            guard oldExpense == expense else {
                
                fatalError("Exception: expense selectedd is not what is to be deleted")
            }

            let isSoftDelete = softDeleteExpense(expense: oldExpense!)
            
            if !isSoftDelete {
                
                delegate?.expenseDeleted(deletedExpense: oldExpense!)
                aContext?.delete(oldExpense!)
            }
            
            saveManageContext()
            loadExpensesFromSections()
            reloadData()
            
            updateToiCloud(nil)
        }
    }
    
    func updateToiCloud(_ expense: XYZExpense?) {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let iCloudZone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!)
        iCloudZone?.data = appDelegate?.expenseList
    
        let lastTokenChangeFetch = iCloudZone?.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date
        
        if let _ = iCloudZone {
        
            fetchAndUpdateiCloud(CKContainer.default().privateCloudDatabase,
                             [ckrecordzone],
                             [iCloudZone!], {
            
            // if we implement synchronization of content, then time to refresh it.
            DispatchQueue.main.async {
                
                appDelegate?.expenseList = (iCloudZone?.data as? [XYZExpense])!
                self.reloadData()
            }
                                
            if let _ = expense {
                
                let newLastTokenChangeFetch = iCloudZone?.value(forKey: XYZiCloudZone.changeTokenLastFetch) as? Date

                    if let shareRecordId = expense?.value(forKey: XYZExpense.shareRecordId) as? String,
                        shareRecordId != "",
                        lastTokenChangeFetch != newLastTokenChangeFetch {
                
                        let ckrecordid = CKRecordID(recordName: shareRecordId, zoneID: ckrecordzone.zoneID)
                        let database = CKContainer.default().privateCloudDatabase
                    
                        database.fetch(withRecordID: ckrecordid , completionHandler: { (ckrecord, error) in
                        
                        // after fetching share record
                            if let _ = error {
                            
                                print("-------- error in getting shared record = \(String(describing: error))")
                            } else {
                            
                                guard let ckshare = ckrecord as? CKShare else {
                                
                                    fatalError("Exception: CKShare is expected")
                                }
                            
                                guard let personList = expense?.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
                                
                                    fatalError("Exception: [XYZExpensePerson] is expected")
                                }
                            
                                var existingParticipants = ckshare.participants
                                var userIdentityLookupInfos = [CKUserIdentityLookupInfo]()
                            
                                for person in personList {
                                
                                    let email = person.value(forKey: XYZExpensePerson.email) as? String
                                                                    
                                    let useridentitylookup = CKUserIdentityLookupInfo(emailAddress: email!)
                                    userIdentityLookupInfos.append(useridentitylookup)
                                }
                            
                                if !userIdentityLookupInfos.isEmpty {
                                
                                // if there are share participant to be looked up
                                    let fetchsharedparticipantOp = CKFetchShareParticipantsOperation(userIdentityLookupInfos: userIdentityLookupInfos)
                                    fetchsharedparticipantOp.fetchShareParticipantsCompletionBlock = { error in
                                    
                                        if let _ = error {
                                        
                                            print("-------- fetchShareParticipantsCompletionBlock error = \(String(describing: error))")
                                        } else {
                                        
                                            if !existingParticipants.isEmpty {
                                            
                                                for existingParticipant in existingParticipants {
                                                
                                                    if existingParticipant.type != .owner {
                                                    
                                                        ckshare.removeParticipant(existingParticipant)
                                                    }
                                                }
                                            }
                                        
                                            let modifyoperation = CKModifyRecordsOperation(recordsToSave: [ckshare], recordIDsToDelete: [])
                                            modifyoperation.modifyRecordsCompletionBlock = {records, recordIDs, error in
                                            
                                                if let _ = error {
                                                
                                                    print("-------- \(String(describing: error))")
                                                } else {
                                                
                                                    DispatchQueue.main.async {
                                                    
                                                        fetchiCloudZoneChange(CKContainer.default().privateCloudDatabase,
                                                                          [ckrecordzone], [iCloudZone!]) {
                                                    
                                                            DispatchQueue.main.async {
                                                            
                                                                appDelegate?.expenseList = (iCloudZone?.data as? [XYZExpense])!
                                                                self.reloadData()
                                                            }
                                                                            
                                                        //We do not need UICloudSharingController
                                                        //    DispatchQueue.main.async {
                                                         
                                                        //      let sharingUI = UICloudSharingController(share: ckshare, container: CKContainer.default())
                                                        //      self.present(sharingUI, animated: false, completion:{
                                                            
                                                        //    })
                                                        //}
                                                        }
                                                    }
                                                }
                                            }
                                        
                                            CKContainer.default().privateCloudDatabase.add(modifyoperation)
                                        }
                                    }
                                
                                    fetchsharedparticipantOp.shareParticipantFetchedBlock = { participant in
                                    
                                    // fetch one participant
                                        for (index, existingParticipant) in existingParticipants.enumerated() {
                                        
                                            if existingParticipant.userIdentity == participant.userIdentity {
                                            
                                                existingParticipants.remove(at: index)
                                                break
                                            }
                                        }
                                    

                                        participant.permission = .readOnly

                                        ckshare.addParticipant(participant)
                                    }
                                
                                    CKContainer.default().add(fetchsharedparticipantOp)
                                } else { // if !userIdentityLookupInfos.isEmpty
                            
                                    if !existingParticipants.isEmpty {
                                    
                                        for existingParticipant in existingParticipants {
                                        
                                            if existingParticipant.type != .owner {
                                            
                                                ckshare.removeParticipant(existingParticipant)
                                            }
                                        }
                                    }
                                
                                    let modifyoperation = CKModifyRecordsOperation(recordsToSave: [ckshare], recordIDsToDelete: [])
                                    modifyoperation.modifyRecordsCompletionBlock = {records, recordIDs, error in
                                    
                                        if let _ = error {
                                        
                                            print("-------- \(String(describing: error))")
                                        } else {
                                        
                                            DispatchQueue.main.async {
                                            
                                                fetchiCloudZoneChange(CKContainer.default().privateCloudDatabase,
                                                                      [ckrecordzone], [iCloudZone!]) {
                                                
                                                    DispatchQueue.main.async {
                                                    
                                                        appDelegate?.expenseList = (iCloudZone?.data as? [XYZExpense])!
                                                        self.reloadData()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                
                                    CKContainer.default().privateCloudDatabase.add(modifyoperation)
                                }
                            }
                        })
                    }
                }
            })
        }
    }
    
    func saveExpense(expense: XYZExpense) {
        
        saveManageContext()
    
        updateToiCloud(expense)
        
        if let _ = filteredMonthYear, let _ = filteredExpenseList {
            
            let dateComponentWanted = Calendar.current.dateComponents([.month, .year], from: filteredMonthYear!)
            
            if let date = expense.value(forKey: XYZExpense.date) as? Date {
                
                let dateComponent = Calendar.current.dateComponents([.month, .year], from: date)
                
                if dateComponent.year! == dateComponentWanted.year!
                    && dateComponent.month! == dateComponentWanted.month! {
                 
                    filteredExpenseList?.append(expense)
                    
                    filteredExpenseList = sortExpenses(filteredExpenseList!)
                }
            }
        }
        
        reloadData()
        
        if let indexPath = self.indexPath(of: expense) {
        
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.bottom)
            delegate?.expenseSelected(newExpense: expense)
        }
    }
    
    func saveNewExpense(expense: XYZExpense) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList.append(expense)

        saveExpense(expense: expense)
    }
    
    func softDeleteExpense(expense: XYZExpense) -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool ?? false
        
        if isShared {
            
            expense.setValue(true, forKey: XYZExpense.isSoftDelete)
            expense.setValue(Date(), forKey: XYZExpense.lastRecordChange)
        }
        
        if !((appDelegate?.iCloudZones.isEmpty)!) {
            
            /* TODO: we need to decline the ckshare
            if let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool, isShared {
            
                guard let icloudZone = GetiCloudZone(of: ckrecordzone, share: true, (appDelegate?.shareiCloudZones)!) else {
                    
                    fatalError("Exception: iCloudZoen is expected")
                }
                
                guard let preChangeToken = expense.value(forKey: XYZExpense.preChangeToken) as? Data else {
                    
                    fatalError("Exception: preChangeToken is expected")
                }
                
                icloudZone.setValue(preChangeToken, forKey: XYZiCloudZone.changeToken)
            }
             */
            
            if isShared {
                
            } else {
                
                guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
                    
                    fatalError("Exception: iCloudZoen is expected")
                }
                
                guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
                    
                    fatalError("Exception: data is expected for deleteRecordIdList")
                }
                
                guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }
                
                let recordName = expense.value(forKey: XYZExpense.recordId) as? String
                deleteRecordLiset.append(recordName!)
                
                let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
                zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
                
                guard let shareRecordNameData = zone.value(forKey: XYZiCloudZone.deleteShareRecordIdList) as? Data else {
                    
                    fatalError("Exception: data is expected for deleteRecordIdList")
                }
                
                guard var deleteShareRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: shareRecordNameData) as? [String]) else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }

                if let shareRecordName = expense.value(forKey: XYZExpense.shareRecordId) as? String {
                
                    deleteShareRecordLiset.append(shareRecordName)
                    
                    let savedDeleteShareRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordLiset )
                    zone.setValue(savedDeleteShareRecordLiset, forKey: XYZiCloudZone.deleteShareRecordIdList)
                }
            }
        }
        
        return isShared // if it is shared, then we softdelete it by keeping
    }
    
    func reloadData() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.expenseList = sortExpenses(loadExpenses()!)
        loadExpensesIntoSections()
        tableView.reloadData()
    }
    
    private func loadExpensesFromSections() {
        
        var expenseList = [XYZExpense]()
        
        for section in sectionList {
            
            if section.identifier != "searchBar" {
                
                let sectionExpenseList = section.data as? [XYZExpense]
                for expense in sectionExpenseList! {
                    
                    expenseList.append(expense)
                }
            }
        }
        
        expenseList = sortExpenses(expenseList)

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList = expenseList
    }
    
    private func loadExpensesIntoSections() {

        let calendar = Calendar.current

        // FIXME to improve performance
        currencyCodes = [String]()
        sectionList = [TableSectionCell]()
        sectionMonthYearList = [Date]()
        var sectionExpenseList: [XYZExpense]?
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
        // var expenseList = filteredExpenseList != nil ? filteredExpenseList : (appDelegate?.expenseList)!
        var expenseList = appDelegate?.expenseList
        
        if let _ = searchText, !(searchText?.isEmpty)! {
            
            expenseList = expenseList?.filter({ (expense) -> Bool in
                
                let detail = expense.value(forKey: XYZExpense.detail) as? String ?? ""
                let category = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
                
                return detail.lowercased().range(of: searchText!.lowercased()) != nil
                    || category.lowercased().range(of: searchText!.lowercased()) != nil
            })
        }
        
        if let monthYear = filteredMonthYear {
            
            let dateComponentWanted = Calendar.current.dateComponents([.month, .year], from: monthYear)
    
            var lastDateOfTheMonthYear = Calendar.current.date(from: dateComponentWanted)
            lastDateOfTheMonthYear = Calendar.current.date(byAdding: .month, value: 1, to: lastDateOfTheMonthYear!)
            lastDateOfTheMonthYear = Calendar.current.date(byAdding: .day, value: -1, to: lastDateOfTheMonthYear!)
            
            expenseList = expenseList?.filter({ (expense) -> Bool in
            
                let occurenceDates = expense.getOccurenceDates(until: lastDateOfTheMonthYear!)
                let filteredOcurenceDates = occurenceDates.filter { (date) -> Bool in
                    
                    
                    let dateComponent = Calendar.current.dateComponents([.month, .year], from: date)
                    
                    return dateComponent.year! == dateComponentWanted.year!
                        && dateComponent.month! == dateComponentWanted.month!
                }
                
                
                return !filteredOcurenceDates.isEmpty
            })
        }
        
        expenseList = sortExpenses(expenseList!)
        
        var dateComponentWanted: DateComponents?
        
        if let _ = filteredMonthYear {
        
            dateComponentWanted = Calendar.current.dateComponents([.month, .year], from: filteredMonthYear!)
        }
        
        for expense in expenseList! {
            
            guard let _ = expense.value(forKey: XYZExpense.date) as? Date else {
                
                continue
            }
            
            let isSoftDelete = expense.value(forKey: XYZExpense.isSoftDelete) as? Bool ?? false
            
            if isSoftDelete {
                
                continue
            }
            
            let occurenceDates = expense.getOccurenceDates(until: Date())
            
            for date in occurenceDates {
                
                var needed = true
                
                if let _ = dateComponentWanted {
                    
                    let dateComponent = Calendar.current.dateComponents([.month, .year], from: date)
                    
                    needed = ( dateComponent.year! == dateComponentWanted?.year! )
                               && (dateComponent.month! == dateComponentWanted?.month! )
                }
                
                if needed {
                    
                    let currency = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
                    let dateFormatter = DateFormatter()
                    let month = calendar.component(.month, from: date)
                    let year = calendar.component(.year, from: date)
                    let title = "\(year), \(dateFormatter.shortMonthSymbols[month - 1])"
                    let identifier = "\(year), \(month), \(currency!)"
                    
                    let monthYearComponent =  Calendar.current.dateComponents([.month, .year], from: date)
                    let monthYearDate = Calendar.current.date(from: monthYearComponent)
                    
                    var foundIndex = -1
                    for (index, section) in sectionList.enumerated() {
                        
                        if section.identifier == identifier {
                            
                            foundIndex = index
                            break
                        }
                    }

                    if foundIndex < 0 {
                        
                        foundIndex = sectionList.count;
                        let newSection = TableSectionCell(identifier: identifier, title: title, cellList: [], data: nil)
                        sectionExpenseList = [XYZExpense]()
                        sectionList.append(newSection)
                        sectionMonthYearList.append(monthYearDate!)
                    } else {
                        
                        sectionExpenseList = sectionList[foundIndex].data as? [XYZExpense]
                    }
                    
                    sectionExpenseList?.append(expense)
                    sectionList[foundIndex].data = sectionExpenseList
                    
                    let currencyCode = expense.value(forKey: XYZExpense.currencyCode) as? String ?? Locale.current.currencyCode
                    if !currencyCodes.contains(currencyCode!) {
                        
                        currencyCodes.append(currencyCode!)
                    }
                }
            }
        }
        
        sectionList = sectionList.sorted(by: { (section1, section2) -> Bool in
            
            let tokens1 = section1.identifier.split(separator: ",")
            let tokens2 = section2.identifier.split(separator: ",")
           
            let year1 = Int(tokens1[0])
            let year2 = Int(tokens2[0])
            let month1 = Int(tokens1[1].trimmingCharacters(in: CharacterSet.whitespaces))
            let month2 = Int(tokens2[1].trimmingCharacters(in: CharacterSet.whitespaces))
            let currency1 = tokens1[2]
            let currency2 = tokens2[2]
            
            return year1! >= year2!
                   && month1! >= month2!
                   && currency1 <= currency2
        })
        
        let newSection = TableSectionCell(identifier: "searchBar", title: "", cellList: ["searchBar"], data: nil)
        sectionList.insert(newSection, at: 0)
        sectionMonthYearList.insert(Date(), at: 0)
    }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.setLeftBarButton(self.editButtonItem, animated: true)

        // Check for force touch feature, and add force touch/previewing capability.
        if traitCollection.forceTouchCapability == .available {
            
            /*
             Register for `UIViewControllerPreviewingDelegate` to enable
             "Peek" and "Pop".
             (see: MasterViewController+UIViewControllerPreviewing.swift)
             
             The view controller will be automatically unregistered when it is
             deallocated.
             */
            registerForPreviewing(with: self, sourceView: view)
        }

        //let tapDouble = UITapGestureRecognizer(target: self, action: #selector(navigationTap(_:)))
        //tapDouble.numberOfTapsRequired = 2
        //navigationItem.titleView?.addGestureRecognizer(tapDouble)
        
        let searchBarController: UISearchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchBarController
        searchBar = searchBarController.searchBar
        searchBar?.setShowsCancelButton(false, animated: true)
        searchBarController.delegate = self
        searchBar?.delegate = self
        self.definesPresentationContext = true
        
        loadExpensesIntoSections()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Search delegate
    func didDismissSearchController(_ searchController: UISearchController) {
    
        print("************* dismiss")
        
        if let _ = searchText, !((searchText?.isEmpty)!), searchActive  {
            
            searchBar?.text = searchText
        } else {
            
            searchBar?.text = ""
            filteredExpenseList = nil
            reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        print("************* begin editing")
        
        //searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        print("************* end editing")
        
        searchText = searchBar.text
        //searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        print("************* cancel button")
        
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchActive = false;
        searchText = nil
        searchBar.resignFirstResponder()
        
        filteredExpenseList = nil
        reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        print("************* search button")
        
        searchActive = true;
        searchBar.resignFirstResponder()
        
        reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        print("************* textDidChange")

        searchBar.showsCancelButton = !searchText.isEmpty
        
        if searchText.isEmpty {
            
            if let _ = filteredExpenseList {
                
                filteredExpenseList = nil
                reloadData()
            }
        } else {
            
            /*
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let expenseList = (appDelegate?.expenseList)!
            filteredExpenseList = expenseList.filter({ (expense) -> Bool in
            
                let detail = expense.value(forKey: XYZExpense.detail) as? String ?? ""
                let category = expense.value(forKey: XYZExpense.budgetCategory) as? String ?? ""
                
                return detail.lowercased().range(of: searchText.lowercased()) != nil
                       || category.lowercased().range(of: searchText.lowercased()) != nil
            })
            */
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {

        return nil
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        var commands = [UIContextualAction]()
        
        if sectionList[indexPath.section].identifier == "searchBar" {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? ExpenseTableViewMonthCell else {
                
                fatalError("Exception: ExpenseTableViewMonthCell is expected")
            }
            
            let prevMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: cell.date!)
            cell.setDate(prevMonthDate!)
            cell.drawSelectionState()
            
            filteredMonthYear = nil
            filteredExpenseList = nil
            reloadData()
        } else {

            let copy = UIContextualAction(style: .normal, title: NSLocalizedString("Copy", comment:"") ) { _, _, handler in
                
                guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                    
                    fatalError("Exception: ExpenseDetailNavigationController is expected")
                }
                
                guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                    
                    fatalError("Exception: ExpenseDetailTableViewController is expected" )
                }
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                    
                    fatalError("Exception: UISplitViewController is expected" )
                }
                
                mainSplitView.popOverNavigatorController = expenseDetailNavigationController
                
                //let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
                let sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
                let expense = sectionExpenseList![indexPath.row]
                let detail = expense.value(forKey: XYZExpense.detail) as? String
                let amount = expense.value(forKey: XYZExpense.amount) as? Double
                let budgetGroup = expense.value(forKey: XYZExpense.budgetCategory) as? String
                let date = Date()
                let currency = expense.value(forKey: XYZExpense.currencyCode) as? String
                
                expenseDetailTableView.presetAmount = amount
                expenseDetailTableView.presetDate = date
                expenseDetailTableView.presetDetail = detail
                expenseDetailTableView.presetBudgetCategory = budgetGroup
                expenseDetailTableView.presetCurrencyCode = currency
                expenseDetailTableView.setPopover(delegate: self)
                self.isPopover = true
                
                expenseDetailNavigationController.modalPresentationStyle = .popover
                handler(true)
                self.present(expenseDetailNavigationController, animated: true, completion: nil)
            }
            
            copy.backgroundColor = UIColor.blue
            commands.append(copy)
            
            return UISwipeActionsConfiguration(actions: commands)
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        if sectionList[indexPath.section].identifier == "searchBar" {
            
            guard let cell = tableView.cellForRow(at: indexPath) as? ExpenseTableViewMonthCell else {
                
                fatalError("Exception: ExpenseTableViewMonthCell is expected")
            }
            
            let nextMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: cell.date!)
            cell.setDate(nextMonthDate!)
            cell.drawSelectionState()
    
            filteredMonthYear = nil
            filteredExpenseList = nil
            reloadData()
        } else {
            
            guard let sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense] else {
                
                fatalError("Exception: [XYZExpense] is expected")
            }
        
            let expense = sectionExpenseList[indexPath.row]
            let isShared = expense.value(forKey: XYZExpense.isShared) as? Bool
            
            let delete = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment:"")) { _, _, handler in
                
                // Delete the row from the data source
                self.delete(of: indexPath)
                
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (appDelegate?.expenseList.isEmpty)! {
                    
                    self.setEditing(false, animated: true)
                    self.tableView.setEditing(false, animated: false)
                }
                
                handler(true)
            }
        
            commands.append(delete)
        
            if !(isShared!) {
                
                if let url = expense.value(forKey: XYZExpense.shareUrl) as? String {
                    
                    let more = UIContextualAction(style: .normal, title: NSLocalizedString("More", comment:"")) { _, _, handler in
                        
                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                        guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                            
                            fatalError("Exception: UISplitViewController is expected" )
                        }
                        
                        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        let copyUrlOption = UIAlertAction(title: NSLocalizedString("Share expense url", comment:""), style: .default, handler: { (action) in
                            
                            let vc = UIActivityViewController(activityItems: [url], applicationActivities: [])
                            self.present(vc, animated: true, completion: nil)
                            //UIPasteboard.general.string = "\(url)"

                            mainSplitView.popOverAlertController = nil
                            handler(true)
                        })
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                            
                            mainSplitView.popOverAlertController = nil
                            handler(true)
                        })
                        
                        optionMenu.addAction(copyUrlOption)
                        optionMenu.addAction(cancelAction)
                        
                        mainSplitView.popOverAlertController = optionMenu
                        self.present(optionMenu, animated: true, completion: nil)
                    }
                    
                    commands.append(more)
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        super.setEditing(editing, animated: animated)
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return sectionList[indexPath.section].identifier != "searchBar"
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        var result = UITableViewCellEditingStyle.none
        
        if sectionList[indexPath.section].identifier != "searchBar" {
            
            result = UITableViewCellEditingStyle.delete
        }
        
        return result
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if sectionList[section].identifier == "searchBar" {
            
            return sectionList[section].cellList.count
        } else {
            
            let sectionExpenseList = sectionList[section].data as? [XYZExpense]
        
            return (sectionExpenseList?.count) ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        switch sectionList[indexPath.section].identifier {
          /*
            case "searchBar":
                guard let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewSearchCell", for: indexPath) as? ExpenseTableViewSearchCell else {
                    
                    fatalError("error on ExpenseTableViewSearchCell cell")
                }
                
                searchBar = expenseCell.searchBar
                searchBar?.delegate = self
                cell = expenseCell
          */
            
            case "searchBar":
                guard let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewMonthCell", for: indexPath) as? ExpenseTableViewMonthCell else {
                    
                    fatalError("error on ExpenseTableViewMonthCell cell")
                }
            
                expenseCell.delegate = self
                
                if nil == filteredMonthYear {
                    
                    expenseCell.index = nil
                }
                
                expenseCell.drawSelectionState()
                cell = expenseCell

            default:
                guard let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewCell", for: indexPath) as? ExpenseTableViewCell else {
                
                    fatalError("error on ExpenseTableViewCell cell")
                }
                
                let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
                expenseCell.monthYearDate = sectionMonthYearList[indexPath.section]
                
                expenseCell.setExpense(expense: (sectionExpenseList?[indexPath.row])!)
                cell = expenseCell
        }
        
        return cell!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return sectionList[indexPath.section].identifier != "identifier"
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Delete the row from the data source
            delete(of: indexPath)
        } else if editingStyle == .insert {
            
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
            fatalError("Exception: not yet done")
        }
        
        saveManageContext()
        
        reloadData()
    }

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

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
        if sectionList[section].identifier == "searchBar" {
            
            return nil
        } else {
            
            let stackView = UIStackView()
            let title = UILabel()
            let subtotal = UILabel()
            let (amount, currencyCode) = sectionTotal(section)
            
            stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 45)
            stackView.isLayoutMarginsRelativeArrangement = true
            
            title.text = sectionList[section].title
            title.textColor = UIColor.gray
            stackView.axis = .horizontal
            stackView.addArrangedSubview(title)
            
            if let currencyCode = currencyCode {
                
                subtotal.text = formattingCurrencyValue(input: amount, code: currencyCode)
                subtotal.textColor = UIColor.gray
                stackView.addArrangedSubview(subtotal)
            }
            
            return stackView
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.isCollapsed {
            
            guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let expenseTableView = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
                
                fatalError("Exception: ExpenseDetailTableViewController is expected" )
            }
            
            expenseTableView.setPopover(delegate: self)
            let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
            
            expenseTableView.currencyCodes = currencyCodes
            expenseTableView.expense = sectionExpenseList?[indexPath.row]
            expenseDetailNavigationController.modalPresentationStyle = .popover
            self.present(expenseDetailNavigationController, animated: true, completion: nil)
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                
                fatalError("Exception: UISplitViewController is expected" )
            }
            
            mainSplitView.popOverNavigatorController = expenseDetailNavigationController
        } else {
            
            guard let detailTableViewController = delegate as? ExpenseDetailTableViewController else {
                
                fatalError("Exception: ExpenseDetailTableViewController is expedted" )
            }
            
            detailTableViewController.currencyCodes = currencyCodes
            detailTableViewController.expenseDelegate = self
           
            let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
            
            delegate?.expenseSelected(newExpense: sectionExpenseList?[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return sectionList[section].identifier == "searchBar" ?  CGFloat.leastNormalMagnitude : 35
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return CGFloat.leastNormalMagnitude
    }

    // MARK: - Navigation

    /* Deprecated need:
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier ?? ""
        {
        case "ShowExpenseDetail":
            guard let expenseDetailView = segue.destination as? ExpenseDetailTableViewController else
            {
                fatalError("Exception: Unexpected error on casting segue.destination to ExpenseDetailTableViewController")
            }
            
            if let accountDetail = sender as? ExpenseTableViewCell
            {
                guard let indexPath = tableView.indexPath(for: accountDetail) else
                {
                    fatalError("Unexpeted error in getting indexPath for prepare from table view controller");
                }
                
                expenseDetailView.expense = sectionList[indexPath.section].expenseList?[indexPath.row]
            }
            
            if let _ = expenseDetailView.expense
            {
                expenseDetailView.navigationItem.title = ""
            }
            else
            {
                expenseDetailView.navigationItem.title = "New"
            }
            
            modalEditing = true
            
        default:
            fatalError("Unexpected error on default for prepare from table view controller")
        }
    }
     */
 
    // MARK: - splitview delegate
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseDetailTableViewController = expenseDetailNavigationController.viewControllers.first as? ExpenseDetailTableViewController else {
            
            fatalError("Exception: ExpenseDetailTableViewController is expected")
        }
        
        expenseDetailTableViewController.navigationItem.title = ""
        self.delegate = expenseDetailTableViewController
        
        return expenseDetailNavigationController
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        
        self.delegate = nil
        secondaryViewController.navigationItem.title = "New"
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        for expense in (appDelegate?.expenseList)! {
            
            let indexPath = self.indexPath(of: expense)
            
            if let _ = indexPath {
                
                tableView.deselectRow(at: indexPath!, animated: false)
            }
        }
        
        if let navigationController = secondaryViewController as? UINavigationController {
            
            if let expenseDetailTableViewController = navigationController.viewControllers.first as? ExpenseDetailTableViewController {
                
                expenseDetailTableViewController.expenseDelegate = self
                expenseDetailTableViewController.isPushinto = true
                
                if !isPopover && expenseDetailTableViewController.modalEditing {
                    
                    expenseDetailTableViewController.isPushinto = false
                    expenseDetailTableViewController.isPopover = true
                    navigationController.modalPresentationStyle = .popover

                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    guard let mainSplitView = appDelegate?.window?.rootViewController as? MainSplitViewController else {
                        
                        fatalError("Exception: UISplitViewController is expected" )
                    }
                    
                    mainSplitView.popOverNavigatorController = navigationController
                    
                    OperationQueue.main.addOperation {
                        
                       self.present(navigationController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        navigationItem.leftBarButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        isPopover = false
        
        return true
    }
    
    /* Deprecated need: we do not need to prevent landscape mode as we use PopOver view for adding Expense
    func splitViewControllerSupportedInterfaceOrientations(_ splitViewController: UISplitViewController) -> UIInterfaceOrientationMask
    {
        return modalEditing ? UIInterfaceOrientationMask.portrait : UIInterfaceOrientationMask.all
    }
     */
    
}
