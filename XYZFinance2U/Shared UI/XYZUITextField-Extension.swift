//
//  UITextField-Extension.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 1/6/18.
//  Copyright © 2018 - 2020 Chee Bin Hoh. All rights reserved.
//

import UIKit

extension UITextField {
    
    func addDoneToolbar(onDone: (target: Any, action: Selector)?) {
        
        let (target, action) = onDone ?? (target: self, action:#selector(doneButtonTapped))
        
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done".localized(), style: .done, target: target, action: action)
        ]
        
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
    }
    
    @objc
    func doneButtonTapped() {
        
        self.resignFirstResponder()
    }
}
