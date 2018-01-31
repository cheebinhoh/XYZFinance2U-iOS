//
//  ExpenseDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/10/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import UIKit
import CoreLocation
import CloudKit

// MARK: - protocol
protocol ExpenseDetailDelegate: class {
    
    func saveNewExpense(expense: XYZExpense)
    func saveExpense(expense: XYZExpense)
    func deleteExpense(expense: XYZExpense)
}

class ExpenseDetailTableViewController: UITableViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    ExpenseDetailTextTableViewCellDelegate,
    ExpenseDetailDateTableViewCellDelegate,
    ExpenseDetailDatePickerTableViewCellDelegate,
    ExpenseDetailImagePickerTableViewCellDelegate,
    ExpenseDetailImageViewTableViewCellDelegate,
    ExpenseTableViewDelegate,
    ExpenseDetailCommandDelegate,
    ExpenseDetailLocationDelegate,
    ExpenseDetailLocationPickerDelegate,
    ExpenseDetailLocationViewDelegate {
 
    
    // MARK: - nested type
    struct ImageSet {
        
        var image: UIImage?
        var selected = false
    }
    
    // MARK: - protocol implementation
    func newlocation(coordinte: CLLocationCoordinate2D?) {
        
        if nil == coordinte {
            
            cllocation = nil
        } else {
            
            cllocation = CLLocation(latitude: (coordinte?.latitude)!, longitude: (coordinte?.longitude)!)
        }
        
        //locationCoordinate = coordinte
        hasgeolocation = nil != cllocation //nil != coordinte
    }

    func locationTouchUp(_ sender: ExpenseDetailLocationPickerTableViewCell) {
        
        showLocationView()
    }
    
    func locationSwitch(_ yesno: Bool, _ sender: ExpenseDetailLocationTableViewCell) {
        
        hasLocation = yesno
        
        loadDataInTableSectionCell()
        tableView.reloadData()
    }
    
    func executeCommand(_ sender: ExpenseDetailCommandTableViewCell) {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let deleteOption = UIAlertAction(title: sender.command.text, style: .default, handler: { (action) in
            
            self.expenseDelegate?.deleteExpense(expense: self.expense!)
            
            if self.isPushinto {
                
                self.navigationController?.popViewController(animated: true)
            } else if self.isCollapsed {
                
                self.dismiss(animated: true, completion: nil)
            } else {
                
                self.navigationItem.rightBarButtonItem = nil
                self.navigationItem.leftBarButtonItem = nil
                self.expense = nil
                self.reloadData()
                
                let masterViewController  = self.getMasterTableViewController()
                
                masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
                masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler:nil)
            
        optionMenu.addAction(deleteOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func expenseSelected(newExpense: XYZExpense?) {
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        navigationItem.setLeftBarButton(nil, animated: true)
        
        modalEditing = false
        expense = newExpense
        reloadData()
        
        if isShared {
            
            navigationItem.title = "Shared"
        } else {
            
            navigationItem.title = ""
        }
    }
    
    func expenseDeleted(deletedExpense: XYZExpense) {
        
        expense = nil
        reloadData()
    }
    
    // MARK: - data mamipulation
    private func loadDataInTableSectionCell() {
        
        tableSectionCellList.removeAll()
        
        var mainSectionCellList = ["text", "amount", "date", "location"]
        
        if hasLocation {
            
            let locationIndex = mainSectionCellList.index(of: "location")
            mainSectionCellList.insert("locationPicker", at: locationIndex! + 1)
        }
        
        let mainSection = TableSectionCell(identifier: "main",
                                           title: "",
                                           cellList: mainSectionCellList,
                                           data: nil)
        tableSectionCellList.append(mainSection)
        
        let imageSecteion = TableSectionCell(identifier: "image",
                                             title: "",
                                             cellList: ["image"],
                                             data: nil)
        tableSectionCellList.append(imageSecteion)
        
        if !isShared {
            
            let needEmail = !emails.isEmpty
                            || modalEditing
            
            if needEmail {
                
                var emailList = Array(repeating: "email", count: emails.count)
                if modalEditing {
                    
                    emailList.append("newemail")
                }
                
                let emailSection = TableSectionCell(identifier: "email",
                                                    title: "",
                                                    cellList: emailList,
                                                    data: nil)
                tableSectionCellList.append(emailSection)
            }
        }
        
        if ( modalEditing || isShared ) && nil != expense {
            
            let deleteSection = TableSectionCell(identifier: "delete",
                                                 title: "",
                                                 cellList: ["delete"],
                                                 data: nil)
            tableSectionCellList.append(deleteSection)
        }
    }
    
    func reloadData() {
        
        loadData()
        
        tableView.reloadData()
    }
    
    func saveData() {
        
        var hasChanged = false
        
        if let existingDetail = expense?.value(forKey: XYZExpense.detail) as? String, existingDetail != detail {
            
            hasChanged = true
        } else if let existingAmount = expense?.value(forKey: XYZExpense.amount) as? Double, existingAmount != amount {
            
            hasChanged = true
        } else if let existingDate = expense?.value(forKey: XYZExpense.date) as? Date, existingDate != date {
            
            hasChanged = true
        }/* else if let existingHasLocation = expense?.value(forKey: XYZExpense.hasgeolocation) as? Bool, existingHasLocation != hasLocation {
            
            hasChanged = true
        }*/
        
        expense?.setValue(detail, forKey: XYZExpense.detail)
        expense?.setValue(amount, forKey: XYZExpense.amount)
        expense?.setValue(date, forKey: XYZExpense.date)
        expense?.setValue(false, forKey: XYZExpense.isShared) // if we can save it, it means it is not readonly
    
        if hasLocation, let _ = cllocation {
            
            let data = NSKeyedArchiver.archivedData(withRootObject: cllocation!)
            
            if let existingData = expense?.value(forKey: XYZExpense.loction) as? Data, existingData != data {
                
                hasChanged = true
            }
            
            expense?.setValue(data, forKey: XYZExpense.loction)
        } else {
            
            if let _ = expense?.value(forKey: XYZExpense.loction) as? Data {
                
                hasChanged = true
            }
            
            expense?.setValue(nil, forKey: XYZExpense.loction)
        }
        
        for (index, image) in imageSet!.enumerated() {
            
            guard var receiptList = expense?.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt> else {
                fatalError("Exception: [XYZExpenseReceipt] is expected")
            }
            
            if image.selected {
                
                var data: NSData?
                
                if let jpegdata = UIImageJPEGRepresentation(image.image!, 0) as NSData? {
                    
                    data = jpegdata
                } else if let pngdata = UIImagePNGRepresentation(image.image!) as NSData? {
                    
                    data = pngdata
                }
                
                let (_, hasImageChanged) = (expense?.addReceipt(sequenceNr: index, image: data!))!
                
                if hasImageChanged {
                    
                    hasChanged = true
                }
                
            } else {
                
                var receiptToBeDeleted: XYZExpenseReceipt?
                
                for receipt in receiptList {
                    
                    if let sequenceNr = receipt.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int, sequenceNr == index {
                        
                        receiptToBeDeleted = receipt;
                        break
                    }
                }
                
                if let _ = receiptToBeDeleted {
                    
                    if !hasChanged {

                        hasChanged = true
                    }
                    
                    receiptList.remove(receiptToBeDeleted!)
                    expense?.setValue(receiptList, forKey: XYZExpense.receipts)
                }
            }
        }
        
        guard let personList = expense?.value(forKey: XYZExpense.persons) as? Set<XYZExpensePerson> else {
            
            fatalError("Exception: [XYZExpensePerson] is expected")
        }
        
        var toBeRemovedRange = personList.count..<personList.count
        
        if emails.count < personList.count {
            
            toBeRemovedRange = emails.count..<personList.count
        }
        
        for (index, email) in emails.enumerated() {
            
            let (_, hasChangePerson) = (expense?.addPerson(sequenceNr: index, name: email, email: email, paid: paids[index]))!
            
            if hasChangePerson {
                
                hasChanged = true
            }
        }
        
        for index in toBeRemovedRange {
            
            hasChanged = true
            expense?.removePerson(sequenceNr: index, context: managedContext())
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
            guard let zone = GetiCloudZone(of: ckrecordzone, share: false, (appDelegate?.iCloudZones)!) else {
                
                fatalError("Exception: iCloudZoen is expected")
            }
            
            guard let data = zone.value(forKey: XYZiCloudZone.deleteRecordIdList) as? Data else {
                
                fatalError("Exception: data is expected for deleteRecordIdList")
            }
            
            guard var deleteRecordLiset = (NSKeyedUnarchiver.unarchiveObject(with: data) as? [String]) else {
                
                fatalError("Exception: deleteRecordList is expected as [String]")
            }
            
            let recordName = "\((expense?.value(forKey: XYZExpense.recordId) as? String)!)-\(index)"
            deleteRecordLiset.append(recordName)
            
            let savedDeleteRecordLiset = NSKeyedArchiver.archivedData(withRootObject: deleteRecordLiset )
            zone.setValue(savedDeleteRecordLiset, forKey: XYZiCloudZone.deleteRecordIdList)
        }
        
        if nil == expense?.value(forKey: XYZExpense.lastRecordChange) as? Date
            || hasChanged {
            
            expense?.setValue(Date(), forKey: XYZExpense.lastRecordChange)
        }
    }
    
    func loadData() {
        
        detail = ""
        amount = 0.0
        date = Date()
        emails = [String]()
        paids = [Bool]()
        imageSet = Array(repeating: ImageSet(image: UIImage(named:"defaultPhoto")!, selected: false ), count: imageSetCount)
        cllocation = nil
        hasgeolocation = false
        hasLocation = false
        
        if nil != expense {
            
            detail = (expense?.value(forKey: XYZExpense.detail) as! String)
            date = (expense?.value(forKey: XYZExpense.date) as? Date) ?? Date()
            amount = (expense?.value(forKey: XYZExpense.amount) as? Double) ?? 0.0
            isShared = (expense?.value(forKey: XYZExpense.isShared) as? Bool) ?? false
            
            if isShared {
                
                modalEditing = false
            }
            
            if let data = expense?.value(forKey: XYZExpense.loction) as? Data {
                
                cllocation = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLLocation
            }
            
            hasLocation = nil != cllocation
            hasgeolocation = hasLocation
            
            guard let receiptList = expense?.value(forKey: XYZExpense.receipts) as? Set<XYZExpenseReceipt> else {
                fatalError("Exception: [XYZExpenseReceipt] is expected")
            }
            
            for receipt in receiptList {
                
                let data = receipt.value(forKey: XYZExpenseReceipt.image) as? NSData
                
                guard let image = UIImage(data: data! as Data ) else {
                    fatalError("Exception: ui image is expected")
                }
                
                let seqNr = receipt.value(forKey: XYZExpenseReceipt.sequenceNr) as? Int
                imageSet?[seqNr!].image = image
                imageSet?[seqNr!].selected = true
            }
            
            let personList = expense?.getPersons()
            
            for person in personList!.sorted(by: { (person1, person2) -> Bool in
                let seq1 = person1.value(forKey: XYZExpensePerson.sequenceNr) as? Int
                let seq2 = person2.value(forKey: XYZExpensePerson.sequenceNr) as? Int
                
                return seq1! < seq2!
            }) {
                
                let email = person.value(forKey: XYZExpensePerson.email) as? String
                let paid = person.value(forKey: XYZExpensePerson.paid) as? Bool
                emails.append( email! )
                
                paids.append( paid! )
            }
            
            if isShared {
           
                navigationItem.setRightBarButton(nil, animated: true)
                
                if isPopover {
                
                    let backButton = UIBarButtonItem(title: " Back", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.cancel(_:)))
                    navigationItem.setLeftBarButton(backButton, animated: true)
                }
                //let backButton = UIButton(type: .custom)
                //backButton.setImage(UIImage(named: "BackButton.png"), for: .normal)
                //backButton.setTitle(" Back", for: .normal)
                //backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
                //backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
            }
        }
        
        loadDataInTableSectionCell()
    }
    
    // MARK: - image mamipulation
    func viewImage(_ sender: ExpenseDetailImagePickerTableViewCell, _ imageView: UIImageView, _ index: Int) {
        
        newImageIndex = index
        
        guard let expenseDetailImageNavigationController = self.storyboard?.instantiateViewController(withIdentifier:    "ExpenseDetailImageViewController") as? ExpenseDetailImageViewController else {
            fatalError("Exception: ExpenseDetailImageViewController is expected")
        }
        
        expenseDetailImageNavigationController.isEditable = modalEditing
        expenseDetailImageNavigationController.delegate = self
        expenseDetailImageNavigationController.image = imageSet?[newImageIndex!].image
        
        let nav = UINavigationController(rootViewController: expenseDetailImageNavigationController)
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true, completion: nil)
    }
    
    func viewImage(_ sender: ExpenseDetailImageViewController) {
        
        if let image = sender.image {
            
            imageSet![newImageIndex!].image =  image
            imageSet![newImageIndex!].selected = true
        } else {
            
            imageSet![newImageIndex!].image =  UIImage(named:"defaultPhoto")!
            imageSet![newImageIndex!].selected = false
        }
        
        if let indexPath = tableView.indexPath(for: imagecell!) {
            
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss( animated: true, completion: nil )
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
    
        imageSet![newImageIndex!].image = image
        imageSet![newImageIndex!].selected = true
        
        imagecell?.setImage(image: image, at: newImageIndex!)

        dismiss( animated: true, completion: nil )
    }
    
    func pickImage(_ sender:ExpenseDetailImagePickerTableViewCell, _ imageView: UIImageView, _ index: Int) {
        
        newImageIndex = index
        
        var isCollapsed = true
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            isCollapsed = split.isCollapsed
        }
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(title: "Take photo", style: .default, handler: { (action) in
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
    
            if isCollapsed
            {
                self.present( imagePicker, animated: true, completion: nil)
            }
            else
            {
                imagePicker.modalPresentationStyle = UIModalPresentationStyle.popover
                self.navigationController?.present(imagePicker, animated: true, completion: nil)
            }
        })
        
        let photoOption = UIAlertAction(title: "Choose photo", style: .default, handler: { (action) in
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            
            if isCollapsed
            {
                self.present( imagePicker, animated: true, completion: nil)
            }
            else
            {
                imagePicker.modalPresentationStyle = UIModalPresentationStyle.popover
                self.navigationController?.present(imagePicker, animated: true, completion: nil)
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        optionMenu.addAction(cameraOption)
        optionMenu.addAction(photoOption)
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    // MARK: - date mamipulation
    func dateDidPick(_ sender: ExpenseDetailDatePickerTableViewCell) {
        
        datecell?.dateInput.text = formattingDate(date: sender.date ?? Date(), .medium )
        date = sender.date ?? Date()
    }
    
    func dateInputTouchUp(_ sender:ExpenseDetailDateTableViewCell) {
        
        let indexPath = tableView.indexPath(for: sender)
        
        if !showDatePicker {
            
            tableSectionCellList[(indexPath?.section)!].cellList.insert("datepicker", at: (indexPath?.row)! + 1)
        } else {
            
            tableSectionCellList[(indexPath?.section)!].cellList.remove(at: (indexPath?.row)! + 1)
        }
        
        showDatePicker = !showDatePicker
        
        tableView.reloadData()
    }
    
    // MARK: - text mamipulation
    func switchChanged(_ yesno: Bool, _ sender: ExpenseDetailTextTableViewCell) {
        
        guard let index = tableView.indexPath(for: sender) else {
            fatalError("Exception: index path is expected")
        }
        
        paids[index.row] = yesno
    }
    
    func textDidBeginEditing(_ sender:ExpenseDetailTextTableViewCell) {
        
        guard let index = tableView.indexPath(for: sender) else {
            fatalError("Exception: index path is expected")
        }
        
        switch tableSectionCellList[index.section].cellList[index.row] {
            
            case "newemail":
                if index.row >= emails.count {
                    
                    sender.input.becomeFirstResponder()
                    tableSectionCellList[index.section].cellList.insert("email",
                                                                        at: tableSectionCellList[index.section].cellList.count - 1)
                    emails.append("")
                    paids.append(false)
                    
                    guard let textcell = tableView.cellForRow(at: index) as? ExpenseDetailTextTableViewCell else {
                    
                        fatalError("Exception: ExpenseDetailTextTableViewCell is expected")
                    }
                    
                    if nil == textcell.optionSwitch {
                        
                        textcell.addUISwitch()
                    }
                    
                    let newIndexPath = IndexPath(row: tableSectionCellList[index.section].cellList.count - 1,
                                                 section: index.section)
                    tableView.insertRows(at: [newIndexPath], with: .fade)
                }
                
                break
            
            default:
                break
        }
    }
    
    func textDidEndEditing(_ sender: ExpenseDetailTextTableViewCell)
    {
        if modalEditing {
            
            guard let index = tableView.indexPath(for: sender) else {
                
                return // case where I click on a textcell and then click on email toward bottom of the table view list, then textcell is not longer available
            }
            
            switch tableSectionCellList[index.section].cellList[index.row] {
                
                case "text":
                    detail = sender.input.text!
                
                case "amount":
                    amount = formattingDoubleValueAsDouble(input: sender.input.text!)
                
                case "email":
                    emails[index.row] = sender.input.text!
                
                case "newemail":
                    break // case where we do not yet end editing but then delete the cell
                
                default:
                    fatalError("Exception: \(tableSectionCellList[index.section].cellList[index.row]) is not expected")
            }
        }
    }
    
    // MARK: - property
    var location = "Location"
    var isShared = false
    var cllocation: CLLocation?
    var hasLocation = false
    var detail = ""
    var amount: Double?
    var emails = [String]()
    var paids = [Bool]()
    var imageSet: [ImageSet]?
    var date: Date?
    let imageSetCount = 2
    var hasgeolocation = false
    var modalEditing = true
    var newImageIndex: Int?
    var showDatePicker = false
    weak var datecell : ExpenseDetailDateTableViewCell?
    weak var imagecell : ExpenseDetailImagePickerTableViewCell?
    var expense: XYZExpense?
    var isCollapsed: Bool {
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            return split.isCollapsed
        } else {
            
            return true
        }
    }
    
    var isPushinto = false
    var isPopover = false
    var expenseDelegate: ExpenseDetailDelegate?
    var tableSectionCellList = [TableSectionCell]()
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: - function
    func showLocationView() {
        
        guard let expenseDetailLocationViewController = self.storyboard?.instantiateViewController(withIdentifier: "ExpenseDetailLocationViewController") as? ExpenseDetailLocationViewController
            else {
            fatalError("Exception: ExpenseDetailImageViewController is expected")
        }
        
        expenseDetailLocationViewController.delegate = self
        
        if let _ = cllocation {
            
            expenseDetailLocationViewController.setCoordinate((cllocation?.coordinate)!)
        }
        
        let nav = UINavigationController(rootViewController: expenseDetailLocationViewController)
        
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true, completion: nil)
    }
    
    func setPopover(delegate: ExpenseDetailDelegate) {
        
        isPopover = true
        expenseDelegate = delegate
    }
    
    private func getMasterTableViewController() -> ExpenseTableViewController {
        
        var masterViewController: ExpenseTableViewController?
        
        var split = self.parent?.parent as? UISplitViewController
        if nil == split {
            
            split = self.parent?.parent?.parent as? UISplitViewController
        }
        
        guard let tabBarController = split?.viewControllers.first as? UITabBarController else {
            fatalError("Exception: UITabBarController is expected")
        }
        
        guard let navController = tabBarController.selectedViewController as? UINavigationController else {
            fatalError("Exception: UINavigationController is expected")
        }
        
        masterViewController = (navController.viewControllers.first as? ExpenseTableViewController)!
        
        return masterViewController!
    }
    
    // MARK: - IBAction
    
    @IBAction func cancel(_ sender: Any) {
        
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        if isPushinto {
            
            navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            dismiss(animated: true, completion: nil)
        } else {
            
            let masterViewController  = getMasterTableViewController()
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            expenseSelected(newExpense: expense)
        }
    }
    
    @IBAction func save(_ sender: Any) {
        
        if isPushinto {
            
            saveData()
            expenseDelegate?.saveExpense(expense: expense!)
            navigationController?.popViewController(animated: true)
        } else if isPopover {
            
            if nil == expense {
                
                expense = XYZExpense(id: nil, detail: detail, amount: amount!, date: date!, context: managedContext())
        
                saveData()
                expenseDelegate?.saveNewExpense(expense: expense!)
            } else {
               
                saveData()
                expenseDelegate?.saveExpense(expense: expense!)
            }
            
            dismiss(animated: true, completion: nil)
        } else {
           
            saveData()
            navigationItem.leftBarButtonItem?.isEnabled = false
            modalEditing = false
            loadDataInTableSectionCell()
            tableView.reloadData()
            
            let masterViewController = getMasterTableViewController()
            
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
            navigationItem.setRightBarButton(editButton, animated: true)
            navigationItem.leftBarButtonItem = nil
            
            masterViewController.navigationItem.leftBarButtonItem?.isEnabled = true
            masterViewController.navigationItem.rightBarButtonItem?.isEnabled = true
            
            expenseDelegate?.saveExpense(expense: expense!)
        }
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

        let deleteSection = TableSectionCell(identifier: "delete",
                                             title: "",
                                             cellList: ["delete"],
                                             data: nil)
        tableSectionCellList.insert(deleteSection, at: tableSectionCellList.count - 1)

        loadDataInTableSectionCell()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.isEditing = true
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        navigationItem.largeTitleDisplayMode = .never
        
        if let split = self.parent?.parent as? UISplitViewController {
            
            if !split.isCollapsed {
                
                navigationItem.rightBarButtonItem = nil
                navigationItem.leftBarButtonItem = nil
               
                modalEditing = false
            }
        }
        
        if isPopover {
            
            let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save(_:)))
            navigationItem.setRightBarButton(saveButton, animated: true)
        }
        
        loadData()
        
        if isShared {
        
            navigationItem.title = "Shared"
        } else if let _ = expense {
            
            navigationItem.title = "Expense"
        }
        
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            
            return 35
        } else {
            
            return 17.5
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return tableSectionCellList[section].title
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return tableSectionCellList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableSectionCellList[section].cellList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell

        switch  tableSectionCellList[indexPath.section].cellList[indexPath.row] {
            
            case "text":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailTextCell", for: indexPath) as? ExpenseDetailTextTableViewCell else {
                    fatalError("Exception: expenseDetailTextCell is failed to be created")
                }
                
                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.leadingAnchor.constraint(equalTo: textcell.leadingAnchor, constant: 45.0).isActive = true
                textcell.isEditable = !isShared
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "description"
                textcell.input.text = detail
                
                cell = textcell
            
            case "amount":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailTextCell", for: indexPath) as? ExpenseDetailTextTableViewCell else {
                    fatalError("Exception: expenseDetailTextCell is failed to be created")
                }
              
                amount = amount ?? 0.0
                
                textcell.isEditable = modalEditing
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.enableMonetaryEditing(true)
                textcell.input.placeholder = formattingCurrencyValue(input: 0.0, nil)
                textcell.input.text = formattingCurrencyValue(input: amount ?? 0.0, nil)
                
                cell = textcell
            
            case "date":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailDateTextCell", for: indexPath) as? ExpenseDetailDateTableViewCell else {
                    fatalError("Exception: expenseDetailDateTextCell is failed to be created")
                }
                
                if nil == date  {
                    date = Date()
                }
                
                datecell.dateInput.text = formattingDate(date: date ?? Date(), .medium)
                datecell.delegate = self
                
                datecell.enableEditing = modalEditing
            
                self.datecell = datecell
                cell = datecell
            
            case "datepicker":
                guard let datepickercell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailDatePickerCell", for: indexPath) as? ExpenseDetailDatePickerTableViewCell else {
                    fatalError("Exception: expenseDetailDatePickerCell is failed to be created")
                }
                
                datepickercell.setDate(date ?? Date())
                datepickercell.delegate = self
                cell = datepickercell
            
            case "email":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailTextCell", for: indexPath) as? ExpenseDetailTextTableViewCell else {
                    fatalError("Exception: expenseDetailTextCell is failed to be created")
                }

                textcell.input.text = emails[indexPath.row] //emails[indexPath.row - emailListStart]
                
                textcell.delegate = self
                textcell.input.isEnabled = true
                textcell.input.clearButtonMode = .never
                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.leadingAnchor.constraint(equalTo: textcell.leadingAnchor, constant: 45.0).isActive = true
                
                if nil == textcell.optionSwitch {
                    
                    textcell.addUISwitch()
                    textcell.optionSwitch.isOn = paids[indexPath.row]
                }
                
                cell = textcell
            
            case "newemail":
                guard let textcell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailTextCell", for: indexPath) as? ExpenseDetailTextTableViewCell else {
                    fatalError("Exception: expenseDetailTextCell is failed to be created")
                }
                
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.input.placeholder = "add email"
                textcell.input.text = ""

                if modalEditing {
                    
                    textcell.isHidden = false
                } else {
                    
                    textcell.isHidden = true
                }

                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.leadingAnchor.constraint(equalTo: textcell.leadingAnchor, constant: 45.0).isActive = true
            
                if let _ = textcell.optionSwitch {
                    
                    textcell.stack.removeArrangedSubview(textcell.optionSwitch)
                    textcell.optionSwitch.removeFromSuperview()
                }

                cell = textcell
            
            case "image":
                guard let imagepickercell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailImagePickerCell", for: indexPath) as? ExpenseDetailImagePickerTableViewCell else {
                    fatalError("Exception: expenseDetailImagePickerCell is failed to be created")
                }
                
                if imageSet == nil {
                    
                    imageSet = Array(repeating: ImageSet(image: UIImage(named:"defaultPhoto")!, selected: false ), count: imagepickercell.imageViewList.count)
                }
                
                for index in 0..<(imageSet?.count)! {
                    imagepickercell.setImage(image: imageSet![index].image!, at: index)
                }
                
                imagepickercell.imageView?.contentMode = .scaleAspectFit
                imagepickercell.imageView?.clipsToBounds = true
                imagepickercell.isEditable = modalEditing
                
                imagepickercell.delegate = self
                imagecell = imagepickercell
                cell = imagepickercell
            
            case "location":
                guard let locationcell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailLocationTextCell", for: indexPath) as? ExpenseDetailLocationTableViewCell else {
                    fatalError("Exception: expenseDetailLocationTextCell is failed to be created")
                }
                
                locationcell.location.isOn = hasLocation
                locationcell.delegate = self
                
                cell = locationcell
            
            case "locationPicker":
                guard let locationpicker = tableView.dequeueReusableCell(withIdentifier: "expenseDetailLocationPickerTextCell", for: indexPath) as? ExpenseDetailLocationPickerTableViewCell else {
                    fatalError("Exception: expenseDetailLocationPickerTextCell is failed to be created")
                }
                
                locationpicker.selectionStyle = .none
                locationpicker.location.text = location
                locationpicker.delegate = self
                
                cell = locationpicker
            
            case "delete":
                guard let deletecell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailCommandTextCell", for: indexPath) as? ExpenseDetailCommandTableViewCell else {
                    fatalError("Exception: expenseDetailCommandTextCell is failed to be created")
                }
                
                deletecell.delegate = self
                deletecell.setCommand(command: "Delete Expense")
                
                cell = deletecell
            
            default:
                fatalError("Exception: \(indexPath.row) is not handled")
        }
        // Configure the cell...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        
        var result = UITableViewCellEditingStyle.delete
        
        if indexPath.row >= emails.count {
            
            result = .insert
        }
        
        return result
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return modalEditing
               && tableSectionCellList[indexPath.section].identifier == "email" //indexPath.row >= emailListStart
        
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            emails.remove(at: indexPath.row)
            paids.remove(at: indexPath.row)
            tableSectionCellList[indexPath.section].cellList.remove(at: indexPath.row)
            tableView.reloadData()
        } else if editingStyle == .insert {
            
            guard let textcell = tableView.cellForRow(at: indexPath) as? ExpenseDetailTextTableViewCell else {
                fatalError("Exception: ExpenseDetailTextTableViewCell is expected")
            }
            
            textcell.input.becomeFirstResponder()
        }    
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        showLocationView()
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if tableSectionCellList[indexPath.section].cellList[indexPath.row] == "locationPicker" {
            
            return indexPath
        } else {
            
            return nil
        }
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

    // MARK: - Navigation

    @IBAction func unwindToExpenseDetailTableView(sender: UIStoryboardSegue) {
        
        fatalError("TODO")
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
            
            case "ShowExpenseDetailImage"?:
                guard let detailView = segue.destination as? ExpenseDetailImageViewController else {
                    
                    fatalError("Exception: destination is not ExpenseDetailImageViewController")
                }
        
                if !isCollapsed {
                    
                    detailView.imagePickerModalPresentationStyle = UIModalPresentationStyle.popover
                }
                
                detailView.delegate = self
                detailView.image = imageSet?[newImageIndex!].image
            
            case nil:
                if let button = sender as? UIBarButtonItem, button === saveButton {
                    
                    if nil == expense {
                        
                        expense = XYZExpense(id: nil, detail: detail, amount: amount!, date: date!, context: managedContext())
                    }
      
                    saveData()
                }
                
                break
            
            default:
                fatalError("Exception: segue identifier \(String(describing: segue.identifier)) is not expected")
        }
    }

}
