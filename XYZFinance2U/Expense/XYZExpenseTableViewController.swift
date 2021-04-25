//
//  XYZExpenseTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/7/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import CoreData
import CloudKit

// MARK: - protocol
protocol XYZExpenseTableViewDelegate: class {
    
    func expenseSelected(expense: XYZExpense?)
    func expenseDeleted(expense: XYZExpense)
}

class XYZExpenseTableViewController: UITableViewController,
    XYZTableViewReloadData,
    UIViewControllerPreviewingDelegate,
    UISearchControllerDelegate,
    UISearchBarDelegate,
    XYZExpenseDetailDelegate {
    
    func change(_ monthYear: Date!) {

        if let _ = monthYear {
        
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM, YY"
            
            navigationItem.title = "\("Expenses -".localized()) \((formatter.string(from: monthYear!)))"
        } else {
            
            filteredExpenseList = nil
            navigationItem.title = "\("Expenses".localized())"
        }
        
        filteredMonthYear = monthYear
        
        reloadData()
    }
    
    func cancelExpense() {
    
    }
    
    // MARK: - property
    
    var sectionExpandStatus = [Bool]()
    weak var searchBar: UISearchBar?
    var filteredMonthYear: Date!
    var searchText: String? = nil
    var searchActive = false
    var currencyCodes = [String]()
    var sectionList = [TableSectionCell]()
    var sectionMonthYearList = [Date]()
    var filteredExpenseList: [XYZExpense]?
    var delegate: XYZExpenseTableViewDelegate?
    var isCollapsed: Bool {
        
        return true
    }
    
    // MARK: - IBAction
    @IBAction func navigationTap(_ sender: UITapGestureRecognizer) {
     
    }
    
    @IBAction func add(_ sender: UIBarButtonItem) {
        
        guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
            
            fatalError("Exception: ExpenseDetailNavigationController is expected")
        }
        
        guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
            
            fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarControllerXYZMainUITabBarController is expected" )
        }
        
        tabBarController.popOverNavigatorController = expenseDetailNavigationController
        
        expenseDetailTableView.setDelegate(delegate: self)
        expenseDetailTableView.currencyCodes = currencyCodes
        
        expenseDetailNavigationController.modalPresentationStyle = .popover
        self.present(expenseDetailNavigationController, animated: true, completion: nil)
    }
    
    // MARK: - 3d touch delegate (peek & pop)
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        
        guard let viewController = viewControllerToCommit as? XYZExpenseDetailViewController else {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }
        
        if let _ = viewController.expense {
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                
                fatalError("Exception: XYZMainUITabBarControllerXYZMainUITabBarController is expected" )
            }
            
            tabBarController.popOverAlertController = nil
            
            tableView(tableView, didSelectRowAt: viewController.indexPath!)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location), indexPath.row > 0 else {
            
            return nil
        }
        
        guard let viewController = storyboard?.instantiateViewController(withIdentifier: "expenseDetailViewController") as? XYZExpenseDetailViewController else  {
            
            fatalError("Exception: IncomeDetailViewController is expected")
        }

        let cell = tableView.cellForRow(at: indexPath)
        
        viewController.preferredContentSize = CGSize(width: 0.0, height: 110)
        previewingContext.sourceRect = (cell?.frame)!
        
        guard let sectionExpenseList = sectionList[(indexPath.section)].data as? [XYZExpense] else {
            
            fatalError("Exception: [XYZAccount] is expected")
        }
        
        viewController.expense = sectionExpenseList[(indexPath.row - 1)]
        viewController.indexPath = indexPath

        return viewController
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    
        // code you want to implement
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code here
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: "Undo last change".localized(), style: .default, handler: { (action) in
            
            self.undoManager?.undo()
            self.undoManager?.removeAllActions()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: - function
    
    func sectionTotal(_ section: Int) -> ( Double, String? ) {
        
        var total = 0.0
        let expenseList = sectionList[section].data as? [XYZExpense]
        var usedCurrencyCode: String?
        var hasMultipleCurrency = false
        
        for expense in expenseList! {
        
            let currency = expense.currencyCode
            if usedCurrencyCode == nil {
                
                usedCurrencyCode = currency
            } else if usedCurrencyCode != currency {
                
                hasMultipleCurrency = true
            }
            
            total = total + expense.amount
        }
        
        return ( total, hasMultipleCurrency ? nil : usedCurrencyCode )
    }
    
    func deleteWithoutUndo(of indexPath:IndexPath) {
        
        let aContext = managedContext()
        
        var sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
        
        let oldExpense = sectionExpenseList?.remove(at: indexPath.row - 1)
        self.sectionList[indexPath.section].data = sectionExpenseList
        
        let isSoftDelete = self.softDeleteExpense(expense: oldExpense!)
        
        saveManageContext()
        
        if isSoftDelete {
            
            self.updateToiCloud(oldExpense!)
        } else {
            
            self.delegate?.expenseDeleted(expense: oldExpense!)
            aContext?.delete(oldExpense!)
            
            self.loadExpensesFromSections()
            self.reloadData()
            
            self.updateToiCloud(nil)
        }
    }
    
    func delete(of indexPath:IndexPath) {
        
        var sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
        
        let oldExpense = sectionExpenseList?.remove(at: indexPath.row - 1)
        registerUndoDeleteExpense(expense: oldExpense!)
        
        deleteWithoutUndo(of: indexPath)
    }
    
    func indexPath(of expense:XYZExpense) -> IndexPath? {
        
        for (sectionIndex, section) in sectionList.enumerated() {
            
            let sectionExpenseList = section.data as? [XYZExpense]
            for (rowIndex, cell) in (sectionExpenseList?.enumerated())! {  //(section.expenseList?.enumerated())! {
                
                if cell == expense {
                    
                    return IndexPath(row: rowIndex, section: sectionIndex)
                }
            }
        }
        
        return nil
    }

    func registerUndoDeleteExpense(expense: XYZExpense)
    {
        let oldRecordId = expense.recordId
        let oldDetail = expense.detail
        let oldAmount = expense.amount
        let oldDate = expense.value(forKey: XYZExpense.date) as? Date ?? Date()
        let oldIsShared = expense.isShared // if we can save it, it means it is not readonly
        let oldShareUrl = expense.shareUrl
        let oldShareRecordId = expense.shareRecordId
        let oldHasLocation = expense.hasLocation
        let oldCurrencyCode = expense.currencyCode
        let oldBudgetCategory = expense.budgetCategory
        let oldRecurring = expense.value(forKey: XYZExpense.recurring)
        let oldRecurringStopDate = expense.value(forKey: XYZExpense.recurringStopDate)
        let oldLocation = expense.value(forKey: XYZExpense.loction)
        let oldReceiptList = expense.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt>
        let oldPersonList = expense.getPersons()
        
        undoManager?.registerUndo(withTarget: self, handler: { (viewController) in
            
            let newExpense = XYZExpense(id: oldRecordId, detail: oldDetail, amount: oldAmount, date: oldDate, context: managedContext())
            
            newExpense.shareRecordId = oldShareRecordId
            newExpense.shareUrl = oldShareUrl
            newExpense.isShared = oldIsShared
            newExpense.hasLocation = oldHasLocation
            newExpense.currencyCode = oldCurrencyCode
            newExpense.budgetCategory = oldBudgetCategory
            newExpense.setValue(oldRecurring, forKey: XYZExpense.recurring)
            newExpense.setValue(oldRecurringStopDate, forKey: XYZExpense.recurringStopDate)
            newExpense.setValue(oldLocation, forKey: XYZExpense.loction)
            newExpense.setValue(oldReceiptList, forKey: XYZExpense.receipts)
            newExpense.setValue(oldPersonList, forKey: XYZExpense.persons)
            
            self.saveNewIncomeWithoutUndo(expense: newExpense)
        })
    }
    
    func deleteExpense(expense: XYZExpense) {

        registerUndoDeleteExpense(expense: expense)
        deleteExpenseWithoutUndo(expense: expense)
    }
    
    func deleteExpenseWithoutUndo(expense: XYZExpense) {
        
        if let selectedIndexPath = indexPath(of: expense) {

            // for some reason that the row is missing header
            var index = selectedIndexPath
            index.row = index.row + 1;
            
            deleteWithoutUndo(of: index)
        }
    }
    
    func updateToiCloud(_ expense: XYZExpense?) {
        
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let iCloudZone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!)
        iCloudZone?.data = appDelegate?.expenseList
    
        let lastTokenChangeFetch = iCloudZone?.changeTokenLastFetch
        
        if let _ = iCloudZone {
        
            fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                                 zones: [ckrecordzone],
                                 iCloudZones: [iCloudZone!], completionblock: {
            
            // if we implement synchronization of content, then time to refresh it.
            DispatchQueue.main.async {
                
                appDelegate?.expenseList = (iCloudZone?.data as? [XYZExpense])!
                self.reloadData()
            }
                                
            if let _ = expense {
                
                let newLastTokenChangeFetch = iCloudZone?.changeTokenLastFetch

                    if let shareRecordId = expense?.shareRecordId,
                        shareRecordId != "",
                        lastTokenChangeFetch != newLastTokenChangeFetch {
                
                        let ckrecordid = CKRecord.ID(recordName: shareRecordId, zoneID: ckrecordzone.zoneID)
                        let database = CKContainer.default().privateCloudDatabase
                    
                        database.fetch(withRecordID: ckrecordid , completionHandler: { (ckrecord, error) in
                        
                        // after fetching share record
                            if let _ = error {
                            
                            } else {
                            
                                guard let ckshare = ckrecord as? CKShare else {
                                
                                    fatalError("Exception: CKShare is expected")
                                }
                            
                                guard let personList = expense?.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
                                
                                    fatalError("Exception: [XYZExpensePerson] is expected")
                                }
                            
                                var existingParticipants = ckshare.participants
                                var userIdentityLookupInfos = [CKUserIdentity.LookupInfo]()
                            
                                for person in personList {
                                
                                    let email = person.value(forKey: XYZExpensePerson.email) as? String
                                                                    
                                    let useridentitylookup = CKUserIdentity.LookupInfo(emailAddress: email!)
                                    userIdentityLookupInfos.append(useridentitylookup)
                                }
                            
                                if !userIdentityLookupInfos.isEmpty {
                                
                                // if there are share participant to be looked up
                                    let fetchsharedparticipantOp = CKFetchShareParticipantsOperation(userIdentityLookupInfos: userIdentityLookupInfos)
                                    fetchsharedparticipantOp.fetchShareParticipantsCompletionBlock = { error in
                                    
                                        if let _ = error {

                                        } else {
                                        
                                            if !existingParticipants.isEmpty {
                                            
                                                for existingParticipant in existingParticipants {
                                                
                                                    //if existingParticipant.type != .owner {
                                                    if existingParticipant.permission != .readWrite {
                                                        
                                                        ckshare.removeParticipant(existingParticipant)
                                                    }
                                                }
                                            }
                                        
                                            let modifyoperation = CKModifyRecordsOperation(recordsToSave: [ckshare], recordIDsToDelete: [])
                                            modifyoperation.modifyRecordsCompletionBlock = {records, recordIDs, error in
                                            
                                                if let _ = error {
                                                
                                                } else {
                                                
                                                    DispatchQueue.main.async {
                                                    
                                                        fetchiCloudZoneChange(database: CKContainer.default().privateCloudDatabase,
                                                                              zones: [ckrecordzone], icloudZones: [iCloudZone!]) {
                                                    
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
                                        
                                            //if existingParticipant.type != .owner {
                                            if existingParticipant.permission != .readWrite  {
                                                    
                                                ckshare.removeParticipant(existingParticipant)
                                            }
                                        }
                                    }
                                
                                    let modifyoperation = CKModifyRecordsOperation(recordsToSave: [ckshare], recordIDsToDelete: [])
                                    modifyoperation.modifyRecordsCompletionBlock = {records, recordIDs, error in
                                    
                                        if let _ = error {
                                        
                                        } else {
                                        
                                            DispatchQueue.main.async {
                                            
                                                fetchiCloudZoneChange(database: CKContainer.default().privateCloudDatabase,
                                                                      zones: [ckrecordzone], icloudZones: [iCloudZone!]) {
                                                
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
        
        /*
        if let indexPath = self.indexPath(of: expense) {
        
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableView.ScrollPosition.bottom)
            delegate?.expenseSelected(newExpense: expense)
        }

        */
    }
    
    func saveNewExpense(expense: XYZExpense) {
        
        undoManager?.registerUndo(withTarget: self, handler: { (controller) in
            
            self.deleteExpenseWithoutUndo(expense: expense)
        })
        
        saveNewIncomeWithoutUndo(expense: expense)
    }
    
    func saveNewIncomeWithoutUndo(expense: XYZExpense) {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.expenseList.append(expense)

        saveExpense(expense: expense)
    }
    
    func softDeleteExpense(expense: XYZExpense) -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
        
        if expense.isShared {
            
            expense.isSoftDelete = true
            expense.lastRecordChange = Date()
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
            
            if expense.isShared {
                
            } else {
                
                guard let zone = GetiCloudZone(of: ckrecordzone, share: false, icloudZones: (appDelegate?.iCloudZones)!) else {
                    
                    fatalError("Exception: iCloudZoen is expected")
                }
                
                let data = zone.deleteRecordIdList
                
                guard var deleteRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String] else {
                    
                    fatalError("Exception: deleteRecordList is expected as [String]")
                }
                
                deleteRecordList.append(expense.recordId)
                
                let savedDeleteRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteRecordList, requiringSecureCoding: false)
                zone.deleteRecordIdList = savedDeleteRecordList!
                
                let shareRecordNameData = zone.deleteShareRecordIdList
                
                guard var deleteShareRecordList = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(shareRecordNameData) as? [String] else {
                    
                    fatalError("Exception: deleteShareRecordList is expected as [String]")
                }

                if expense.shareRecordId != "" {
                
                    deleteShareRecordList.append(expense.shareRecordId)
                    
                    let savedDeleteShareRecordList = try? NSKeyedArchiver.archivedData(withRootObject: deleteShareRecordList, requiringSecureCoding: false)
                    zone.deleteShareRecordIdList = savedDeleteShareRecordList!
                }
            }
        }
        
        return expense.isShared // if it is shared, then we softdelete it by keeping
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
            
            let sectionExpenseList = section.data as? [XYZExpense]
            for expense in sectionExpenseList! {
                
                expenseList.append(expense)
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
        
        sectionExpandStatus.removeAll()
        
        if let _ = searchText, !(searchText?.isEmpty)! {
            
            expenseList = expenseList?.filter({ (expense) -> Bool in
                
                let detail = expense.detail
                let category = expense.budgetCategory
                
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
            
            if expense.isSoftDelete {
                
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
                    
                    let currency = expense.currencyCode
                    let dateFormatter = DateFormatter()
                    let month = calendar.component(.month, from: date)
                    let year = calendar.component(.year, from: date)
                    let title = "\(year), \(dateFormatter.shortMonthSymbols[month - 1])"
                    let identifier = "\(year), \(month), \(currency)"
                    
                    let monthYearComponent =  Calendar.current.dateComponents([.month, .year], from: date)
                    let monthYearDate = Calendar.current.date(from: monthYearComponent)
                    
                    var foundIndex = sectionList.firstIndex {
                        
                        return $0.identifier == identifier
                    } ?? -1

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
                    
                    let currencyCode = expense.currencyCode
                    if !currencyCodes.contains(currencyCode) {
                        
                        currencyCodes.append(currencyCode)
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
        
        sectionExpandStatus = Array(repeating: true, count: sectionList.count)
        //let newSection = TableSectionCell(identifier: "searchBar", title: "", cellList: ["searchBar"], data: nil)
        //sectionList.insert(newSection, at: 0)
        //sectionMonthYearList.insert(Date(), at: 0)
    }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
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
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Retrieve latest update from iCloud".localized())
        refreshControl.addTarget(self, action: #selector(refreshUpdateFromiCloud), for: .valueChanged)
        
        // this is the replacement of implementing: "collectionView.addSubview(refreshControl)"
        tableView.refreshControl = refreshControl
    }
    
    @objc func refreshUpdateFromiCloud(refreshControl: UIRefreshControl) {
        
        var zonesToBeFetched = [CKRecordZone]()
        let incomeCustomZone = CKRecordZone(zoneName: XYZExpense.type)
        zonesToBeFetched.append(incomeCustomZone)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let icloudZones = appDelegate?.privateiCloudZones.filter({ (icloudZone) -> Bool in
            
            return icloudZone.name == XYZExpense.type
        })
        
        fetchiCloudZoneChange(database: CKContainer.default().privateCloudDatabase, zones: zonesToBeFetched, icloudZones: icloudZones!, completionblock: {
            
            for (_, icloudzone) in (icloudZones?.enumerated())! {
                
                switch icloudzone.name {
                    
                    case XYZExpense.type:
                        
                        appDelegate?.expenseList = (icloudzone.data as? [XYZExpense])!

                        DispatchQueue.main.async {

                            self.reloadData()
                            
                            pushChangeToiCloudZone(database: CKContainer.default().privateCloudDatabase, zones: zonesToBeFetched, icloudZones: icloudZones!, completionblock: {
                                
                            })
                        }
                    
                    default:
                        fatalError("Exception: \(String(describing: icloudzone.name)) is not supported")
                }
            }
        })
        
        // somewhere in your code you might need to call:
        refreshControl.endRefreshing()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Search delegate
    func didDismissSearchController(_ searchController: UISearchController) {
    
        if let _ = searchText, !((searchText?.isEmpty)!), searchActive  {
            
            searchBar?.text = searchText
        } else {
            
            searchBar?.text = ""
            filteredExpenseList = nil
            reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        //searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        searchText = searchBar.text
        //searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
          
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchActive = false;
        searchText = nil
        searchBar.resignFirstResponder()
        
        filteredExpenseList = nil
        reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchActive = true;
        searchBar.resignFirstResponder()
        
        reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchBar.showsCancelButton = !searchText.isEmpty
        
        if searchText.isEmpty {
            
            if let _ = filteredExpenseList {
                
                filteredExpenseList = nil
                reloadData()
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        return nil
    }

    override func tableView(_ tableView: UITableView,
                            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        var commands = [UIContextualAction]()
        
        let copy = UIContextualAction(style: .normal, title: "Copy".localized() ) { _, _, handler in
            
            guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
                
                fatalError("Exception: ExpenseDetailNavigationController is expected")
            }
            
            guard let expenseDetailTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
                
                fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
            }
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate

            guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                
                fatalError("Exception: XYZMainUITabBarControllerXYZMainUITabBarController is expected" )
            }
            
            tabBarController.popOverNavigatorController = expenseDetailNavigationController
            
            //let sectionBudgetList = self.sectionList[indexPath.section].data as? [XYZBudget]
            let sectionExpenseList = self.sectionList[indexPath.section].data as? [XYZExpense]
            let expense = sectionExpenseList![indexPath.row - 1 ]
            let detail = expense.detail
            let amount = expense.amount
            let budgetGroup = expense.budgetCategory
            let date = Date()
            let currency = expense.currencyCode
            
            expenseDetailTableView.presetAmount = amount
            expenseDetailTableView.presetDate = date
            expenseDetailTableView.presetDetail = detail
            expenseDetailTableView.presetBudgetCategory = budgetGroup
            expenseDetailTableView.presetCurrencyCode = currency
            expenseDetailTableView.setDelegate(delegate: self)
        
            expenseDetailNavigationController.modalPresentationStyle = .popover
            handler(true)
            self.present(expenseDetailNavigationController, animated: true, completion: nil)
        }
        
        copy.backgroundColor = UIColor.systemBlue
        commands.append(copy)
        
        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var commands = [UIContextualAction]()
        
        let delete = UIContextualAction(style: .destructive, title: "Delete".localized()) { _, _, handler in
            
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

        return UISwipeActionsConfiguration(actions: commands)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        navigationItem.rightBarButtonItem?.isEnabled = !editing
        
        super.setEditing(editing, animated: animated)
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        

        return UITableViewCell.EditingStyle.delete
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionExpenseList = sectionList[section].data as? [XYZExpense]
    
        var numRows = ( sectionExpenseList?.count ?? 0 ) + 1
        if !sectionExpandStatus[section] {
            
            numRows = 1
        }
        
        return numRows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        switch sectionList[indexPath.section].identifier {
            // used to have other

            default:
                switch indexPath.row {
                    
                    case 0:
                        guard let totalCell = tableView.dequeueReusableCell(withIdentifier: "expenseTotalTableViewCell", for: indexPath) as? XYZExpenseTableViewCell else {
                            
                            fatalError("error on XYZExpenseTableViewCell cell")
                        }
                    
                        var currency = "";
                        var total = 0.0
                        
                        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
                        for expense in sectionExpenseList! {
                            
                            total = total + expense.amount
                            currency = expense.currencyCode
                        }
                        
                        totalCell.detail.text = currency
                        totalCell.amount.text = formattingCurrencyValue(of: total, as: currency)
                        totalCell.date.text = sectionList[indexPath.section].title
                        totalCell.dotColorView.isHidden = true
                        
                        cell = totalCell
                    
                    default:
                        guard let expenseCell = tableView.dequeueReusableCell(withIdentifier: "expenseTableViewCell", for: indexPath) as? XYZExpenseTableViewCell else {
                        
                            fatalError("error on XYZExpenseTableViewCell cell")
                        }
                        
                        let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
                        expenseCell.monthYearDate = sectionMonthYearList[indexPath.section]
                        
                        expenseCell.setExpense(expense: (sectionExpenseList?[indexPath.row - 1])!)
                        cell = expenseCell
                }
        }
        
        return cell!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Return false if you do not want the specified item to be editable.
        return sectionList[indexPath.section].identifier != "identifier"
               && indexPath.row > 0
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
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
    
        let stackView = UIStackView()
        let title = UILabel()
        let subtotal = UILabel()
        let (amount, currencyCode) = sectionTotal(section)
        
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 45)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        title.text = sectionList[section].title
        title.textColor = UIColor.gray
        stackView.axis = .horizontal
        stackView.addArrangedSubview(title)
        
        if let currencyCode = currencyCode {
            
            subtotal.text = formattingCurrencyValue(of: amount, as: currencyCode)
            subtotal.textColor = UIColor.gray
            stackView.addArrangedSubview(subtotal)
        }

        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        
            case 0:
                sectionExpandStatus[indexPath.section] = !sectionExpandStatus[indexPath.section]
                
                tableView.reloadData()
            
            default:
                if self.isCollapsed {
                    
                    guard let expenseDetailNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "expenseDetailNavigationController") as? UINavigationController else {
                        
                        fatalError("Exception: ExpenseDetailNavigationController is expected")
                    }
                    
                    guard let expenseTableView = expenseDetailNavigationController.viewControllers.first as? XYZExpenseDetailTableViewController else {
                        
                        fatalError("Exception: XYZExpenseDetailTableViewController is expected" )
                    }
                    
                    tableView.deselectRow(at: indexPath, animated: false)
                    
                    expenseTableView.setDelegate(delegate: self)
                    let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
                    
                    expenseTableView.currencyCodes = currencyCodes
                    expenseTableView.expense = sectionExpenseList?[indexPath.row - 1]
                    expenseDetailNavigationController.modalPresentationStyle = .popover
                    self.present(expenseDetailNavigationController, animated: true, completion: nil)
                    
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    
                    guard let tabBarController = appDelegate?.window?.rootViewController as? XYZMainUITabBarController else {
                        
                        fatalError("Exception: XYZMainUITabBarControllerXYZMainUITabBarController is expected" )
                    }
                    
                    tabBarController.popOverNavigatorController = expenseDetailNavigationController
                } else {
                    
                    guard let detailTableViewController = delegate as? XYZExpenseDetailTableViewController else {
                        
                        fatalError("Exception: XYZExpenseDetailTableViewController is expedted" )
                    }
                    
                    detailTableViewController.currencyCodes = currencyCodes
                    detailTableViewController.expenseDelegate = self
                   
                    let sectionExpenseList = sectionList[indexPath.section].data as? [XYZExpense]
                    
                    delegate?.expenseSelected(expense: sectionExpenseList?[indexPath.row - 1])
                }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 10
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
            guard let expenseDetailView = segue.destination as? XYZExpenseDetailTableViewController else
            {
                fatalError("Exception: Unexpected error on casting segue.destination to XYZExpenseDetailTableViewController")
            }
            
            if let accountDetail = sender as? XYZExpenseTableViewCell
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
}
