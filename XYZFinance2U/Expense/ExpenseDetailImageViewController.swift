//
//  ExpenseDetailImageViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/13/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit

protocol ExpenseDetailImageViewTableViewCellDelegate: class {
    
    func viewImage(_ sender:ExpenseDetailImageViewController )
}

class ExpenseDetailImageViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIScrollViewDelegate {
    
    // MARK: - property
    
    var delegate: ExpenseDetailImageViewTableViewCellDelegate?
    var image: UIImage?
    var imagePickerModalPresentationStyle: UIModalPresentationStyle?
    var isEditable = true
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        if nil == image {
            
            imageView?.image = UIImage(named:"defaultPhoto")!
        } else {
            
            imageView?.image = image
        }
        
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 20.0
        
        addBackButton()
        addSlideRightToUnwind()
        addSingleAndDoubleTapToZoomAndSelectOtherImage()
        
        if !isEditable {
            
            navigationItem.setRightBarButton(nil, animated: true)
        }
        // Do any additional setup after loading the view.
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return self.imageView
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addSingleAndDoubleTapToZoomAndSelectOtherImage() {
        
        let tapDouble = UITapGestureRecognizer(target: self, action: #selector(zoomIn(_:)))
        tapDouble.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(tapDouble)

        if isEditable {
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage(_:)))
            tap.require(toFail: tapDouble)
            imageView.addGestureRecognizer(tap)
        }
    }
    
    private func addSlideRightToUnwind() {
        
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight(_:)))
        gesture.direction = .right
        
        self.view.addGestureRecognizer(gesture)
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
    
    @objc
    @IBAction func swipeRight(_ sender: UITapGestureRecognizer) {
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        
        delegate?.viewImage(self)
        dismiss(animated: true, completion: nil)
        //let _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func zoomIn(_ sender: UITapGestureRecognizer) {
        
        if (self.scrollView!.zoomScale == self.scrollView!.minimumZoomScale) {
            
            let center = sender.location(in: self.scrollView!)
            let size = self.imageView!.image!.size
            let zoomRect =  CGRect(x: center.x, y: center.y, width: size.width / 2, height: size.height / 2 )
            self.scrollView!.zoom(to: zoomRect, animated: true)
        } else {

            self.scrollView!.setZoomScale(self.scrollView!.minimumZoomScale, animated: true)
        }
    }

    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraOption = UIAlertAction(title: NSLocalizedString("Take photo", comment:""), style: .default, handler: { (action) in
            
            imagePickerController.sourceType = .camera
            imagePickerController.modalPresentationStyle = UIModalPresentationStyle.popover
            self.present( imagePickerController, animated: true, completion: nil)
        })
        
        optionMenu.addAction(cameraOption)
        
        let photoOption = UIAlertAction(title: NSLocalizedString("Choose photo", comment:""), style: .default, handler: { (action) in
            
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.modalPresentationStyle = UIModalPresentationStyle.popover
            self.present( imagePickerController, animated: true, completion: nil)
        })

        optionMenu.addAction(photoOption)
        
        if let _ = image {
            
            let saveOption = UIAlertAction(title: NSLocalizedString("Save photo", comment:""), style: .default, handler: { (action) in
                
                UIImageWriteToSavedPhotosAlbum(self.image!, nil, nil, nil)
            })
            
            optionMenu.addAction(saveOption)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment:""), style: .cancel, handler: nil)

        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func deleteImage(_ sender: UIBarButtonItem) {
        
        image = nil
        imageView?.image = UIImage(named:"defaultPhoto")!
    }
    
    // MARK: - Image picker delegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else  {
            
            fatalError("Exceptin: expect a dictionary containing an image, but was provided the following: \(info)")
        }

        self.imageView.image = image
        self.image = image
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
     */
}
