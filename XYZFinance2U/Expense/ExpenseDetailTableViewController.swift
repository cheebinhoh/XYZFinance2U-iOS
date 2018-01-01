//
//  ExpenseDetailTableViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/10/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//

import UIKit
import CoreLocation

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
        var seleted = false
    }
    
    // MARK: - protocol implementation
    func newlocation(coordinte: CLLocationCoordinate2D?) {
        
        locationCoordinate = coordinte
        hasgeolocation = nil != coordinte
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
        
        modalEditing = false
        expense = newExpense
        reloadData()
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
        navigationItem.setRightBarButton(editButton, animated: true)
        navigationItem.leftBarButtonItem = nil
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
        
        var emailList = [String]()
        if let _ = expense {
            
            let personList = expense?.getPersons()
            emailList = Array(repeating: "email", count: (personList?.count)!)
        }
        
        var needEmail = modalEditing
        if !needEmail {
            
            if nil != expense {
                
                let persons = expense?.getPersons()
                needEmail = !(persons?.isEmpty)!
            }
        }
        
        if needEmail {
            
            if modalEditing {
                
                emailList.append("newemail")
            }
            
            let emailSection = TableSectionCell(identifier: "email",
                                                title: "",
                                                cellList: emailList,
                                                data: nil)
            tableSectionCellList.append(emailSection)
        }
        
        if modalEditing && nil != expense {
            
            let deleteSection = TableSectionCell(identifier: "delete",
                                                 title: "",
                                                 cellList: ["delete"],
                                                 data: nil)
            tableSectionCellList.append(deleteSection)
        }
        
        let footerSection = TableSectionCell(identifier: "footer",
                                             title: "",
                                             cellList: [String](),
                                             data: nil)
        tableSectionCellList.append(footerSection)
    }
    
    func reloadData() {
        
        loadData()
        
        tableView.reloadData()
    }
    
    func saveData() {
        
        expense?.setValue(detail, forKey: XYZExpense.detail)
        expense?.setValue(amount, forKey: XYZExpense.amount)
        expense?.setValue(date, forKey: XYZExpense.date)
        expense?.setValue(hasgeolocation, forKey: XYZExpense.hasgeolocation)
        
        if hasgeolocation, let _ = locationCoordinate {
            
            expense?.setValue(locationCoordinate?.longitude, forKey: XYZExpense.longitude)
            expense?.setValue(locationCoordinate?.latitude, forKey: XYZExpense.latitude)
        } else {
            
            expense?.setValue(1000.0, forKey: XYZExpense.longitude)
            expense?.setValue(1000.0, forKey: XYZExpense.latitude)
        }
        
        for (index, image) in imageSet!.enumerated() {
            
            if image.seleted {
                
                var data: NSData?
                
                if let jpegdata = UIImageJPEGRepresentation(image.image!, 0) as NSData? {
                    
                    data = jpegdata
                } else if let pngdata = UIImagePNGRepresentation(image.image!) as NSData? {
                    
                    data = pngdata
                }
                
                expense?.addReceipt(sequenceNr: index, image: data!)
            }
        }
        
        expense?.removeAllPersons()
        
        for (index, email) in emails.enumerated() {
            
            expense?.addPerson(sequenceNr: index, name: email, email: email)
        }
    }
    
    func loadData() {
        
        detail = ""
        amount = 0.0
        date = Date()
        emails = [String]()
        imageSet = Array(repeating: ImageSet(image: UIImage(named:"defaultPhoto")!, seleted: false ), count: imageSetCount)
        locationCoordinate = nil
        hasgeolocation = false
        
        if nil != expense {
            
            detail = (expense?.value(forKey: XYZExpense.detail) as! String)
            date = (expense?.value(forKey: XYZExpense.date) as? Date) ?? Date()
            amount = (expense?.value(forKey: XYZExpense.amount) as? Double) ?? 0.0
            hasgeolocation = (expense?.value(forKey: XYZExpense.hasgeolocation) as? Bool)!
            
            if hasgeolocation {
                
                if let lat = (expense?.value(forKey: XYZExpense.latitude) as? Double) {
                    
                    let long = (expense?.value(forKey: XYZExpense.longitude) as? Double) ?? 1000.0
                
                    locationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    hasLocation = true
                }
            }
            
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
            }
            
            let personList = expense?.getPersons()
            
            for person in personList!.sorted(by: { (person1, person2) -> Bool in
                let seq1 = person1.value(forKey: XYZExpensePerson.sequenceNr) as? Int
                let seq2 = person2.value(forKey: XYZExpensePerson.sequenceNr) as? Int
                
                return seq1! < seq2!
            }) {
                
                let email = person.value(forKey: XYZExpensePerson.email) as? String
                emails.append( email! )
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
        
        expenseDetailImageNavigationController.delegate = self
        expenseDetailImageNavigationController.image = imageSet?[newImageIndex!].image
        
        let nav = UINavigationController(rootViewController: expenseDetailImageNavigationController)
        nav.modalPresentationStyle = .popover
        self.present(nav, animated: true, completion: nil)
    }
    
    func viewImage(_ sender: ExpenseDetailImageViewController) {
        
        if let image = sender.image {
            
            imageSet![newImageIndex!].image =  image
            imageSet![newImageIndex!].seleted = true
        } else {
            
            imageSet![newImageIndex!].image =  UIImage(named:"defaultPhoto")!
            imageSet![newImageIndex!].seleted = false
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
        imageSet![newImageIndex!].seleted = true
        
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
        
        datecell?.dateInput.text = formattingDate(date: sender.date ?? Date() )
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
                fatalError("Exception: index path is expected")
            }
            
            switch tableSectionCellList[index.section].cellList[index.row] {
                
                case "text":
                    detail = sender.input.text!
                
                case "amount":
                    amount = formattingDoubleValueAsDouble(input: sender.input.text!)
                
                case "email":
                    emails[index.row] = sender.input.text!
                
                default:
                    fatalError("Exception: \(tableSectionCellList[index.section].cellList[index.row]) is not expected")
            }
        }
    }
    
    // MARK: - property
    var location = "Location"
    var locationCoordinate: CLLocationCoordinate2D?
    var hasLocation = false
    var detail = ""
    var amount: Double?
    var emails = [String]()
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
        
        if let _ = locationCoordinate {
            
            expenseDetailLocationViewController.setCoordinate(locationCoordinate!)
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
                
                expense = XYZExpense(type: "", detail: detail, amount: amount!, date: date!, latitude: 0.0, longitude: 0.0, context: managedContext())
            
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
        
        if let _ = expense {
            
            navigationItem.title = ""
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
        
        if let _ = tableSectionCellList[section].title {
            
            return ( tableSectionCellList.count - 1 ) == section ? 200 : 35
        } else {
            
            return 0
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
                
                textcell.input.isEnabled = modalEditing
                textcell.delegate = self
                textcell.enableMonetaryEditing(true)
                textcell.input.placeholder = formattingCurrencyValue(input: 0.0)
                textcell.input.text = formattingCurrencyValue(input: amount ?? 0.0)
                
                cell = textcell
            
            case "date":
                guard let datecell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailDateTextCell", for: indexPath) as? ExpenseDetailDateTableViewCell else {
                    fatalError("Exception: expenseDetailDateTextCell is failed to be created")
                }
                
                if nil == date  {
                    date = Date()
                }
                
                datecell.dateInput.text = formattingDate(date: date ?? Date())
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
                
                textcell.input.translatesAutoresizingMaskIntoConstraints = false
                textcell.input.leadingAnchor.constraint(equalTo: textcell.leadingAnchor, constant: 45.0).isActive = true
                
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
            
                cell = textcell
            
            case "image":
                guard let imagepickercell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailImagePickerCell", for: indexPath) as? ExpenseDetailImagePickerTableViewCell else {
                    fatalError("Exception: expenseDetailImagePickerCell is failed to be created")
                }
                
                if imageSet == nil {
                    
                    imageSet = Array(repeating: ImageSet(image: UIImage(named:"defaultPhoto")!, seleted: false ), count: imagepickercell.imageViewList.count)
                }
                
                for index in 0..<(imageSet?.count)! {
                    imagepickercell.setImage(image: imageSet![index].image!, at: index)
                }
                
                imagepickercell.imageView?.contentMode = .scaleAspectFit
                imagepickercell.imageView?.clipsToBounds = true
                imagepickercell.enableEditing = modalEditing
                
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
                // ExpenseDetailLocationPickerTableViewCell
            
            case "delete":
                guard let deletecell = tableView.dequeueReusableCell(withIdentifier: "expenseDetailCommandTextCell", for: indexPath) as? ExpenseDetailCommandTableViewCell else {
                    fatalError("Exception: expenseDetailCommandTextCell is failed to be created")
                }
                
                deletecell.delegate = self
                deletecell.setCommand(command: "Delete expense")
                
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
                        expense = XYZExpense(type: "", detail: detail, amount: amount!, date: date!, latitude: 0.0, longitude: 0.0, context: managedContext())
                    }
      
                    saveData()
                }
                
                break
            
            default:
                fatalError("Exception: segue identifier \(String(describing: segue.identifier)) is not expected")
        }
    }

}
