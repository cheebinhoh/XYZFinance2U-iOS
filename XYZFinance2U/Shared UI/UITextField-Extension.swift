//
//  UITextField-Extension.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/6/18.
//  Copyright © 2018 CB Hoh. All rights reserved.
//

import UIKit

extension UITextField {
    
    func addDoneToolbar(onDone: (target: Any, action: Selector)?) {
        
        let onDone = onDone ?? (target: self, action:#selector(doneButtonTapped))
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
    }
    
    @objc
    func doneButtonTapped() {
        
        self.resignFirstResponder()
    }
}
