//
//  ExpenseDetailImagePickerTableViewCell.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/12/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol XYZExpenseDetailImagePickerTableViewCellDelegate: class {
    
    func pickImage(_ sender:ExpenseDetailImagePickerTableViewCell, _ imageView: UIImageView, _ index: Int)
    func viewImage(_ sender:ExpenseDetailImagePickerTableViewCell, _ imageView: UIImageView, _ index: Int)
}

class ExpenseDetailImagePickerTableViewCell: UITableViewCell,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    // MARK: - property
    
    weak var delegate: XYZExpenseDetailImagePickerTableViewCellDelegate?
    var imageViewList = [UIImageView]()
    var isEditable = false
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var newImage1: UIImageView!
    @IBOutlet weak var newImage2: UIImageView!
    
    // MARK: - function
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        imageViewList.append(newImage1)
        imageViewList.append(newImage2)
        
        for imageView in imageViewList {
            
            let tapDouble = UITapGestureRecognizer(target: self, action: #selector(newImageDoubleTouchUp(_:)))
            
            tapDouble.numberOfTapsRequired = 2
            imageView.addGestureRecognizer(tapDouble)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(newImageTouchUp(_:)))
            
            tap.require(toFail: tapDouble)
            imageView.addGestureRecognizer(tap)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setImage(image: UIImage, at index: Int) {
        
        imageViewList[index].image = image
    }
    
    // MARK: - IBAction
    
    @objc
    @IBAction func newImageDoubleTouchUp(_ sender: UITapGestureRecognizer) {
        
        guard let imageView = sender.view as? UIImageView else {
            
            fatalError("Exception: UIImageView is expected for UITapGestureRecognizer")
        }
        
        delegate?.viewImage(self, imageView, imageViewList.firstIndex(of: imageView)! )
    }
    
    @objc
    @IBAction func newImageTouchUp(_ sender: UITapGestureRecognizer) {
        
        if isEditable {
            
            guard let imageView = sender.view as? UIImageView else {
                
                fatalError("Exception: UIImageView is expected for UITapGestureRecognizer")
            }
            
            delegate?.pickImage(self, imageView, imageViewList.firstIndex(of: imageView)! )
        }
    }
}
