//
//  XYZBudgetDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 2/15/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

protocol XYZBudgetDetailDelegate: AnyObject {
    
    func saveNewBudget(budget: XYZBudget)
    func saveBudget(budget: XYZBudget)
    func deleteBudget(budget: XYZBudget)
}

class XYZBudgetDetailTableViewController: UITableViewController,
    XYZBudgetSelectionDelegate,
    XYZTextTableViewCellDelegate,
    XYZBudgetDetailDateTableViewCellDelegate,
    XYZBudgetDetailDatePickerTableViewCellDelegate,
    XYZBudgetDetailCommandDelegate,
    XYZSelectionDelegate {
    
    // MARK: - call back
    func executeCommand(sender: XYZBudgetDetailCommandTableViewCell) {

        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: sender.command.text, style: .default, handler: { (action) in
            
            self.budgetDelegate?.deleteBudget(budget: self.budget!)
            self.dismiss(animated: true, completion: nil)
            self.modalEditing = false
        })
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler:nil)
        
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        optionMenu.popoverPresentationController?.sourceView = self.view
        optionMenu.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                                                      width: 0, height: 0)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func dateDidPick(sender: XYZBudgetDetailDatePickerTableViewCell) {
    
        if let budget = budget {
            
            if nrOfHistoricalItems >= historicalStart.count {
        
                if sender.date! > date {
                    
                    historicalStart.append(date)
                    historicalAmount.append(budget.amount)
                    historicalLength.append(budget.length.rawValue)
                }
            } else {
                
                let result = Calendar.current.compare(sender.date!, to: historicalStart.last!, toGranularity: .day)
                
                switch result {
                 
                    case ComparisonResult.orderedDescending:
                        break
                    
                    case ComparisonResult.orderedSame:
                        historicalStart.removeLast()
                        historicalAmount.removeLast()
                        historicalLength.removeLast()
                    
                    case ComparisonResult.orderedAscending:
                        break
                }
            }
        }
        
        date = sender.date!

        let indexPath = tableView.indexPath(for: sender)
 
        let dateIndexPath = IndexPath(row: (indexPath?.row)! - 1, section: (indexPath?.section)!)
        
        tableView.reloadRows(at: [dateIndexPath], with: .none)
        
        if let lastEffectiveIndexPath = lastEffectiveIndexPath {
            
            tableView.reloadRows(at: [lastEffectiveIndexPath], with: .none)
        }
    }
    
    func dateInputTouchUp(sender: XYZBudgetDetailDateTableViewCell) {

        let indexPath = tableView.indexPath(for: sender)
        let showDatePicker = sectionList[(indexPath?.section)!].cellList.count - 1 > (indexPath?.row)!

        if !showDatePicker {
            
            sectionList[(indexPath?.section)!].cellList.insert("datepicker", at: (indexPath?.row)! + 1)
        } else {
            
            sectionList[(indexPath?.section)!].cellList.remove(at: (indexPath?.row)! + 1)
        }
        
        tableView.reloadData()

        if showDatePicker {
            
            let topIndexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
        } else {
            
            tableView.scrollToRow(at: indexPath!, at: .middle, animated: true)
        }
    }
    
    func selectedItem(_ item: String?, sender: XYZSelectionTableViewController) {

        switch sender.selectionIdentifier! {
            case "length":
                length = XYZBudget.Length(rawValue: item!)!
            
            case "currency":
                currencyCode = item!
            
            case "color":
                color = XYZColor(rawValue: item!)!
            
            case "lasteffective":
                break
            
            case "icon":
                iconName = item!
            
            default:
                break
        }
        
        tableView.reloadData() // TODO: how do we improve by just the row, does it worth it?
    }
        
    func textDidEndEditing(sender: XYZTextTableViewCell) {
        
        if let index = tableView.indexPath(for: sender) {
            
            switch sectionList[index.section].cellList[index.row] {
                
                case "budget":
                    budgetType = sender.input.text!
                    navigationItem.rightBarButtonItem?.isEnabled = !budgetType.isEmpty
                
                case "amount":
                    amount = formattingDoubleValueAsDouble(of: sender.input.text!)
                    
                    if let lastEffectiveIndexPath = lastEffectiveIndexPath {
                    
                        tableView.reloadRows(at: [lastEffectiveIndexPath], with: .none)
                    }
                    
                    break
                
                default:
                    fatalError("Exception: \(sectionList[index.section].cellList[index.row] ) is not supported")
            }
        }
    }
    
    func textDidBeginEditing(sender: XYZTextTableViewCell) {
    
    }
    
    func budgetSelected(budget: XYZBudget?) {

        modalEditing = false
        self.budget = budget
        reloadData()
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        navigationItem.leftBarButtonItem = nil
    }
    
    func budgetDeleted(budget: XYZBudget) {
    
    }

    // MARK: - properties
    var budgetDelegate: XYZBudgetDetailDelegate?
    var modalEditing = true
    var budget: XYZBudget?
    var sectionList = [TableSectionCell]()
    var budgetType = ""
    var amount = 0.0
    var currencyCode = Locale.current.currencyCode
    var length: XYZBudget.Length = XYZBudget.Length.none
    var date = Date() 
    var datecell: XYZBudgetDetailDateTableViewCell?
    var currencyCodes = [String]()
    var color = XYZColor.none
    var historicalAmount = [Double]()
    var historicalStart = [Date]()
    var historicalLength = [String]()
    var lastEffectiveIndexPath: IndexPath?
    var nrOfHistoricalItems = 0
    var iconName = ""
    let iconNameList = ["",
                        "autogas",
                        "automative service",
                        "education",
                        "entertainment",
                        "expense",
                        "food",
                        "grocery",
                        "house",
                        "kid",
                        "laundry",
                        "medical",
                        "transport",
                        "travel"]
    
    var isCollapsed: Bool {
    
        return true
    }
    
    // MARK: - IBAction
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func edit(_ sender: Any) {
        
        let  masterViewController = getMasterTableViewController();
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        navigationItem.setRightBarButton(doneButton, animated: true)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        
        masterViewController.navigationItem.leftBarButtonItem?.isEnabled = false
        masterViewController.navigationItem.rightBarButtonItem?.isEnabled = false
        
        modalEditing = true
        
        reloadData()
    }
    
    @IBAction func save(_ sender: Any) {
        
        if nil == budget {
             
            budget = XYZBudget(id: nil,
                               name: budgetType,
                               amount: amount,
                               currency: currencyCode!,
                               length: length,
                               start: date,
                               sequenceNr: 0,
                               context: managedContext())
            
            saveData()
            budgetDelegate?.saveNewBudget(budget: budget!)
        } else {
            
            registerUndoSave(budget: budget!)
            saveData()
            budgetDelegate?.saveBudget(budget: budget!)
        }

        dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - functions
    
    private func getMasterTableViewController() -> XYZBudgetTableViewController {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        guard let tabBarController = appDelegate?.window?.rootViewController as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected")
        }
        
        guard let navController = tabBarController.selectedViewController as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        return (navController.topViewController as? XYZBudgetTableViewController)!
    }

    func registerUndoSave(budget: XYZBudget) {
        
        let oldName = budget.name
        let oldAmount = budget.amount
        let oldCurrency = budget.currency
        let oldStart = budget.start
        let oldLength = budget.length
        let oldColor = budget.color
        let oldHistoricalAmount = budget.historicalAmount
        let oldHistoricalStart = budget.historicalStart
        let oldHistoricalLength = budget.historicalLength
        let oldIconName = budget.iconName
        let oldSequenceNr = budget.sequenceNr
        
        undoManager?.registerUndo(withTarget: budget, handler: { (budget) in
          
            budget.name = oldName
            budget.amount = oldAmount
            budget.currency = oldCurrency
            budget.start = oldStart
            budget.length = oldLength
            budget.color = oldColor
            budget.historicalAmount = oldHistoricalAmount
            budget.historicalStart = oldHistoricalStart
            budget.historicalLength = oldHistoricalLength
            budget.iconName = oldIconName
            budget.sequenceNr = oldSequenceNr
            budget.lastRecordChange = Date()
            
            self.budgetDelegate?.saveBudget(budget: budget)
        })
    }

    func saveData() {
        
        // post processing
        var processedHistoricalAmount = [Double]()
        var processedHistoricalStart = [Date]()
        var processedHistoricalLength = [String]()

        for (index, start) in historicalStart.enumerated() {
            
            let result = Calendar.current.compare(start, to: date, toGranularity: .day)
            
            switch result {
                
                case ComparisonResult.orderedAscending:
                    processedHistoricalStart.append(start)
                    processedHistoricalAmount.append(historicalAmount[index])
                    processedHistoricalLength.append(historicalLength[index])
                
                default:
                    break
            }
        }
        
        var hasChanged = false
        let dataAmount = try! NSKeyedArchiver.archivedData(withRootObject: processedHistoricalAmount, requiringSecureCoding: false)
        let dataDate = try! NSKeyedArchiver.archivedData(withRootObject: processedHistoricalStart, requiringSecureCoding: false)
        let dataLength = try! NSKeyedArchiver.archivedData(withRootObject: processedHistoricalLength, requiringSecureCoding: false)

        if let existingBudgetType = budget?.name, existingBudgetType != budgetType {
            
            hasChanged = true
        } else if let existingAmount = budget?.amount, existingAmount != amount {
            
            hasChanged = true
        } else if let existingCurrencyCode = budget?.currency, existingCurrencyCode != currencyCode {
            
            hasChanged = true
        } else if let existingLength = budget?.length, existingLength != length {
            
            hasChanged = true
        } else if let existingDate = budget?.start, existingDate != date {
            
            hasChanged = true
        } else if let existingColor = budget?.color, existingColor != color.rawValue {
            
            hasChanged = true
        } else if let existingDataAmount = budget?.historicalAmount, existingDataAmount as Data != dataAmount {
            
            hasChanged = true
        } else if let existingDataDate = budget?.historicalAmount, existingDataDate != dataDate {
            
            hasChanged = true
        } else if let existingDataLength = budget?.historicalLength, existingDataLength != dataLength {
            
            hasChanged = true
        } else if let existingIconName = budget?.iconName, existingIconName != iconName {
            
            hasChanged = true
        }
        
        budget?.name = budgetType
        budget?.amount = amount
        budget?.currency = currencyCode!
        budget?.start = date
        budget?.length = length
        budget?.color = color.rawValue
        budget?.historicalAmount = dataAmount
        budget?.historicalStart = dataDate
        budget?.historicalLength = dataLength
        budget?.iconName = iconName
        
        if nil == budget?.lastRecordChange
            || hasChanged {
            
            budget?.lastRecordChange = Date()
        }
    }
    
    func loadDataIntoSectionList() {
    
        sectionList = [TableSectionCell]()
        
        let mainSection = TableSectionCell(identifier: "main", title: nil, cellList: ["budget", "amount", "currency"], data: nil)
        sectionList.append(mainSection)
        
        let lengthSection = TableSectionCell(identifier: "length", title: nil, cellList: ["length", "date"], data: nil)
        sectionList.append(lengthSection)
        
        let lastEffectiveSection = TableSectionCell(identifier: "lasteffective", title: nil, cellList: ["lasteffective"], data: nil)
        sectionList.append(lastEffectiveSection)
        
        let colorSection = TableSectionCell(identifier: "color", title: nil, cellList: ["icon", "color"], data: nil)
        sectionList.append(colorSection)
        
        if modalEditing && nil != budget {
            
            let deleteSection = TableSectionCell(identifier: "delete",
                                                 title: "",
                                                 cellList: ["delete"],
                                                 data: nil)
            sectionList.append(deleteSection)
        }
    }
    
    func reloadData() {
        
        loadData()
        tableView.reloadData()
    }
    
    func loadData() {
        
        if let budget = budget {
            
            if isCollapsed {
                
                navigationItem.title = "Budget".localized()
            }
            
            budgetType = budget.name
            amount = budget.amount
            currencyCode = budget.currency
            length = budget.length
            date = budget.start
            color = XYZColor(rawValue: budget.color)!
            
            let dataAmount = budget.historicalAmount 
            historicalAmount = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataAmount) as? [Double] ?? [Double]()

            let dataStart = budget.historicalStart 
            historicalStart = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataStart) as? [Date] ?? [Date]()

            let dataLength = budget.historicalLength 
            historicalLength = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataLength) as? [String] ?? [String]()

            nrOfHistoricalItems = historicalStart.count
            
            iconName = budget.iconName 
        } else {
            
            budgetType = ""
            amount = 0.0
            currencyCode = Locale.current.currencyCode
            length = XYZBudget.Length.none
            date = Date()
            color = XYZColor.none
            
            if isCollapsed {
                
                navigationItem.title = "New budget".localized()
            }
            
            navigationItem.rightBarButtonItem?.isEnabled = !budgetType.isEmpty
        }

        loadDataIntoSectionList()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.tableFooterView = UIView(frame: .zero)

        navigationItem.largeTitleDisplayMode = .never
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
        navigationItem.setRightBarButton(saveButton, animated: true)
        
        loadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func setDelegate(delegate: XYZBudgetDetailDelegate) {
        
        budgetDelegate = delegate
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return section == 0 ? 35 : 17.5
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionList[section].title
    }

    override func numberOfSections(in tableView: UITableView) -> Int {

        return sectionList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return sectionList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
        
            case "budget":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailTextCell", for: indexPath) as? XYZTextTableViewCell else {
                    
                    fatalError("Exception: budgetDetailTextCell is failed to be created")
                }
            
                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "budget".localized()
                textcell.input.text = budgetType
                textcell.label.text = "Category".localized()
                textcell.enableMonetaryEditing(false)
                
                cell = textcell
            
            case "amount":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailTextCell", for: indexPath) as? XYZTextTableViewCell else {
                    
                    fatalError("Exception: budgetDetailTextCell is failed to be created")
                }

                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.enableMonetaryEditing(true, of: currencyCode!)
                
                textcell.input.placeholder = formattingCurrencyValue(of: 0.0, as: currencyCode)
                textcell.input.text = formattingCurrencyValue(of: amount, as: currencyCode)
                textcell.label.text = "Amount".localized()
                
                cell = textcell

            case "currency":
                guard let currencycell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }

                currencycell.setLabel("Currency".localized())
                currencycell.setSelection(currencyCode ?? "USD")
                currencycell.selectionStyle = .none
                currencycell.icon.image = UIImage(named: "empty")

                cell = currencycell
            
            case "length":
                guard let lengthcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }
                
                lengthcell.setLabel("Period".localized())
                
                var lengthRawValue = "";
                switch length {
                    case .none:
                        lengthRawValue = ""
                    
                    default:
                        lengthRawValue = length.rawValue.localized()
                }

                lengthcell.setSelection(lengthRawValue)
                lengthcell.selectionStyle = .none
                lengthcell.icon.image = UIImage(named: "empty")

                cell = lengthcell
            
            case "lasteffective":
                guard let lasteffectivecell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }
                
                let (retlength, retstart, retamount ) = XYZBudget.getEffectiveBudgetDateAmount(length: length.rawValue,
                                                                                               start: date,
                                                                                               amount: amount,
                                                                                               lengths: historicalLength.reversed(),
                                                                                               starts: historicalStart.reversed(),
                                                                                               amounts: historicalAmount.reversed())
                
                lasteffectivecell.setLabel("Current effective".localized())
                if let retstart = retstart {
                    
                    lasteffectivecell.setSelection("\(formattingCurrencyValue(of: retamount!, as: currencyCode)), \(retlength!.localized()), \(formattingDate(retstart, style: .medium))")
                } else {
                    
                    lasteffectivecell.setSelection("")
                }
                
                if historicalAmount.isEmpty {
                    
                    lasteffectivecell.accessoryType = .none
                } else {
                    
                    lasteffectivecell.accessoryType = .disclosureIndicator
                }

                lasteffectivecell.selectionStyle = .none
                lasteffectivecell.colorView.backgroundColor = UIColor.clear
                lasteffectivecell.icon.image = UIImage(named: "empty")

                cell = lasteffectivecell
            
                lastEffectiveIndexPath = indexPath
            
            case "icon":
                guard let iconcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }

                iconcell.selection.text = ""
                iconcell.setLabel("Icon".localized())
                iconcell.icon.image = UIImage(named: iconName == "" ? "empty" : iconName)
                iconcell.icon.image = iconcell.icon.image?.withRenderingMode(.alwaysTemplate)
                
                if #available(iOS 13.0, *) {
                    
                    iconcell.icon.image?.withTintColor(UIColor.systemBlue)
                } else {
                    // Fallback on earlier versions
                }
                
                iconcell.selectionStyle = .none
                cell = iconcell
            
            case "color":
                guard let colorcell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailSelectionCell", for: indexPath) as? XYZSelectionTableViewCell else {
                    
                    fatalError("Exception: budgetDetailSelectionCell is failed to be created")
                }
                
                colorcell.setLabel("Color".localized())
                colorcell.setSelection(color.rawValue)
                colorcell.colorView.backgroundColor = color.uiColor()
                colorcell.icon.image = UIImage(named: "empty")
                
                colorcell.selectionStyle = .none
                cell = colorcell
            
            case "date":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailDateTextCell", for: indexPath) as? XYZBudgetDetailDateTableViewCell else {
                    
                    fatalError("Exception: XYZBudgetDetailDateTableViewCell is failed to be created")
                }
                
                datecell.dateInput.text = formattingDate(date, style: .medium)
                datecell.delegate = self
                datecell.label.text = "Start date".localized()
                datecell.enableEditing = modalEditing
                
                if sectionList[indexPath.section].cellList.count == indexPath.row + 1 {
            
                    datecell.accessoryView = nil
                    datecell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
                } else {
                    
                    datecell.accessoryType = UITableViewCell.AccessoryType.none
                    datecell.accessoryView = createDownDisclosureIndicatorImage()
                }
                
                self.datecell = datecell
                
                cell = datecell
            
            case "datepicker":
                guard let datepickercell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailDatePickerCell", for: indexPath) as? XYZBudgetDetailDatePickerTableViewCell else {
                    
                    fatalError("Exception: XYZBudgetDetailDatePickerTableViewCell is failed to be created")
                }
                
                datepickercell.setDate(date)
                datepickercell.delegate = self
                
                cell = datepickercell
            
            case "delete":
                guard let deletecell = tableView.dequeueReusableCell(withIdentifier: "budgetDetailCommandTextCell", for: indexPath) as? XYZBudgetDetailCommandTableViewCell else {
                    
                    fatalError("Exception: XYZBudgetDetailCommandTableViewCell is failed to be created")
                }
                
                deletecell.delegate = self
                deletecell.setCommand(command: "\("Delete Budget".localized())")
                
                cell = deletecell
            
             default:
                fatalError("Exception: \(sectionList[indexPath.section].cellList[indexPath.row]) not handle")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {

        guard let _ = tableView.cellForRow(at: indexPath) as? XYZSelectionTableViewCell else {
            
            return nil
        }
        
        return indexPath
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch sectionList[indexPath.section].cellList[indexPath.row] {
            
        case "currency":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "currency"
            
            if !currencyCodes.isEmpty {
                
                selectionTableViewController.setSelections("", false, currencyCodes)
            }
            
            var codeIndex: Character?
            var codes = [String]()
            for code in Locale.isoCurrencyCodes {
                
                if nil == codeIndex {
                    
                    codes.append(code)
                    codeIndex = code.first
                } else if code.first == codeIndex {
                    
                    codes.append(code)
                } else {
                    
                    let identifier = "\(codeIndex!)"
                    
                    selectionTableViewController.setSelections(identifier, true, codes )
                    codes.removeAll()
                    codes.append(code)
                    codeIndex = code.first
                }
            }
            
            let identifier = "\(codeIndex!)"
            
            selectionTableViewController.setSelections(identifier, true, codes )
            selectionTableViewController.setSelectedItem(currencyCode ?? "USD")
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            //nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)

        case "length":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "length"
            selectionTableViewController.setSelections("", false,
                                                       [XYZBudget.Length.none.rawValue,
                                                        XYZBudget.Length.daily.rawValue,
                                                        XYZBudget.Length.weekly.rawValue,
                                                        XYZBudget.Length.biweekly.rawValue,
                                                        XYZBudget.Length.monthly.rawValue,
                                                        XYZBudget.Length.halfyearly.rawValue,
                                                        XYZBudget.Length.yearly.rawValue],
                                                       ["",
                                                        XYZBudget.Length.daily.rawValue.localized(),
                                                        XYZBudget.Length.weekly.rawValue.localized(),
                                                        XYZBudget.Length.biweekly.rawValue.localized(),
                                                        XYZBudget.Length.monthly.rawValue.localized(),
                                                        XYZBudget.Length.halfyearly.rawValue.localized(),
                                                        XYZBudget.Length.yearly.rawValue.localized()]
                                                       )
            selectionTableViewController.setSelectedItem(length.rawValue)
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            //nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)
           
        case "lasteffective":
            if !historicalAmount.isEmpty {
                
                guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                    
                    fatalError("Exception: error on instantiating SelectionNavigationController")
                }
                
                selectionTableViewController.selectionIdentifier = "Effective"
                
                var displayedStrings = [String]()
                var selectionStrings = [String]()
                for (index, amount) in historicalAmount.enumerated() {
                    
                    let date = historicalStart[index]
                    let string = "\(formattingCurrencyValue(of: amount, as: currencyCode)), \(historicalLength[index]), \(formattingDate(date, style: .medium))"

                    selectionStrings.append(string)
                    
                    let displayedString = "\(formattingCurrencyValue(of: amount, as: currencyCode)), \(historicalLength[index].localized()), \(formattingDate(date, style: .medium))"
                    displayedStrings.append(displayedString)
                }
                
                displayedStrings.append("\(formattingCurrencyValue(of: amount, as: currencyCode)), \(length.rawValue.localized()), \(formattingDate(date, style: .medium))")
                
                selectionStrings.append("\(formattingCurrencyValue(of: amount, as: currencyCode)), \(length.rawValue), \(formattingDate(date, style: .medium))")
                
                selectionStrings.reverse()
                displayedStrings.reverse()
                selectionTableViewController.readonly = true
                selectionTableViewController.setSelections("",
                                                           false,
                                                           selectionStrings,
                                                           displayedStrings)
                
                let (retlength, retstart, retamount ) = XYZBudget.getEffectiveBudgetDateAmount(length: length.rawValue,
                                                                                               start: date,
                                                                                               amount: amount,
                                                                                               lengths: historicalLength.reversed(),
                                                                                               starts: historicalStart.reversed(),
                                                                                               amounts: historicalAmount.reversed())
                
                if let retstart = retstart {
                    
                    selectionTableViewController.setSelectedItem("\(formattingCurrencyValue(of: retamount!, as: currencyCode)), \(retlength!), \(formattingDate(retstart, style: .medium))",
                        "\(formattingCurrencyValue(of: retamount!, as: currencyCode)), \(retlength!.localized()), \(formattingDate(retstart, style: .medium))")
                } else {
                    
                   selectionTableViewController.setSelectedItem("")
                }
                
                selectionTableViewController.delegate = self
                
                let nav = UINavigationController(rootViewController: selectionTableViewController)
                //nav.modalPresentationStyle = .popover
                
                self.present(nav, animated: true, completion: nil)
            }
            
        case "icon":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "icon"
            selectionTableViewController.setSelections("",
                                                       false,
                                                       iconNameList)
            selectionTableViewController.setSelectionIcons(imageNames: iconNameList)

            selectionTableViewController.setSelectedItem(iconName)
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            //nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)
            
        case "color":
            guard let selectionTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "selectionTableViewController") as? XYZSelectionTableViewController else {
                
                fatalError("Exception: error on instantiating SelectionNavigationController")
            }
            
            selectionTableViewController.selectionIdentifier = "color"
            selectionTableViewController.setSelections("",
                                                       false,
                                                       [XYZColor.none.rawValue,
                                                        XYZColor.black.rawValue,
                                                        XYZColor.blue.rawValue,
                                                        XYZColor.brown.rawValue,
                                                        XYZColor.cyan.rawValue,
                                                        XYZColor.green.rawValue,
                                                        XYZColor.magenta.rawValue,
                                                        XYZColor.orange.rawValue,
                                                        XYZColor.purple.rawValue,
                                                        XYZColor.red.rawValue,
                                                        XYZColor.yellow.rawValue,
                                                        XYZColor.white.rawValue])
            
            selectionTableViewController.setSelectionColors(colors: [XYZColor.none.uiColor(),
                                                                     XYZColor.black.uiColor(),
                                                                     XYZColor.blue.uiColor(),
                                                                     XYZColor.brown.uiColor(),
                                                                     XYZColor.cyan.uiColor(),
                                                                     XYZColor.green.uiColor(),
                                                                     XYZColor.magenta.uiColor(),
                                                                     XYZColor.orange.uiColor(),
                                                                     XYZColor.purple.uiColor(),
                                                                     XYZColor.red.uiColor(),
                                                                     XYZColor.yellow.uiColor(),
                                                                     XYZColor.white.uiColor()])
            selectionTableViewController.setSelectedItem(color.rawValue)
            selectionTableViewController.delegate = self
            
            let nav = UINavigationController(rootViewController: selectionTableViewController)
            //nav.modalPresentationStyle = .popover
            
            self.present(nav, animated: true, completion: nil)
            
        default:
            fatalError("Exception \(sectionList[indexPath.section].cellList[indexPath.row]) is not handled")
            
        }
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
