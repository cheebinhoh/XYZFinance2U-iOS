//
//  IncomeDetailViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import os.log
import CoreData

class IncomeDetailViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    // MARK: - property
    
    var account: XYZAccount?
    var isPresentingInAddIncomeMode = false
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var bank: UITextField!
    @IBOutlet weak var accountNr: UITextField!
    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var date: UIDatePicker!
    @IBOutlet weak var dateInput: UILabel!
    
    // MARK: - IBAction
    
    @IBAction func dateInputTouchUp(_ sender: UITapGestureRecognizer) {
        
        date.isHidden = !date.isHidden
    }
    
    @IBAction func pickDate(_ sender: UIDatePicker) {
        
        dateInput.text = formattingDate(date: sender.date, .medium)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
            
        amount.keyboardType = .decimalPad
        bank.delegate = self
        accountNr.delegate = self
        amount.delegate = self;
        
        if let account = account {
            
            navigationItem.title = "Edit"
            
            amount.text = formattingCurrencyValue(input: "\((account.value(forKey: XYZAccount.amount) as? Double)!)", nil)
            bank.text = account.value(forKey: XYZAccount.bank) as? String
            accountNr.text = account.value(forKey: XYZAccount.accountNr) as? String
            date.date = ( account.value(forKey: XYZAccount.lastUpdate) as? Date )!
            dateInput.text = formattingDate(date: date.date, .medium)
        } else {
            
            isPresentingInAddIncomeMode = true;
            amount.text = formattingCurrencyValue(input: 0.0, nil)
            dateInput.text = formattingDate(date: date.date, .medium)
        }
        
        date.isHidden = true
        amount.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        navigationItem.largeTitleDisplayMode = .never
        // Do any additional setup after loading the view.
    }
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        
        var text = textField.text ?? "0.00"
        
        text = formattingDoubleValue(input: text)
        text = formattingAndProcessDoubleValue(input: text)
        text = formattingCurrencyValue(input: text, nil)
        textField.text = text
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        
        if let owningNavigationController = navigationController {
            
            owningNavigationController.popViewController(animated: true)
        } else {
            
            fatalError("The MealViewController is not inside a navigation controller.")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        guard let button = sender as? UIBarButtonItem, button === saveButton else {
            
            os_log("The save button was not pressed, cancelling", log: OSLog.default, type: .debug)
            return
        }
        
        let bankText = bank.text ?? ""
        let accountNrText = accountNr.text ?? ""
        let amountText = formattingDoubleValue(input: amount.text ?? "0")
        let amountValue = Double(amountText) ?? 0.0
        let lastupdate = date.date
        
        if account == nil {
            
            account = XYZAccount(sequenceNr: 0, bank: bankText, accountNr: accountNrText, amount: amountValue, date: lastupdate, context:managedContext() )
        } else {
            
            account?.setValue(bankText, forKey: XYZAccount.bank)
            account?.setValue(accountNrText, forKey: XYZAccount.accountNr)
            account?.setValue(amountValue, forKey: XYZAccount.amount)
            account?.setValue(lastupdate, forKey: XYZAccount.lastUpdate)
        }
    }
}

