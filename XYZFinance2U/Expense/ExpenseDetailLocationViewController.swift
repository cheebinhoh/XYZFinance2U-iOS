//
//  ExpenseDetailLocationViewController.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 12/25/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import MapKit
import CoreLocation

protocol ExpenseDetailLocationViewDelegate: class {
    
    func newlocation(coordinte: CLLocationCoordinate2D?)
}

class ExpenseDetailLocationViewController: UIViewController,
    CLLocationManagerDelegate,
    MKMapViewDelegate {
    
    // MARK: - property
    
    var delegate: ExpenseDetailLocationViewDelegate?
    var coordinate: CLLocationCoordinate2D?
    let clmanager = CLLocationManager()
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var map: MKMapView!
    
    // MARK: - function
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        map.delegate = self
        clmanager.delegate = self
        clmanager.desiredAccuracy = kCLLocationAccuracyBest
        clmanager.requestWhenInUseAuthorization()

        if let _ = coordinate {
            
            displayCoordinate(coordinate!, "Selected location".localized())
        }
        
        addCurrentLocationButton()
        addBackButton()
    }
    
    func setCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        self.coordinate = coordinate
        
        if let _ = map {
            
            displayCoordinate(coordinate, "Selected location".localized())
        }
    }
    
    func displayCoordinate(_ coordinate: CLLocationCoordinate2D, _ title: String) {
        
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        self.map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.map.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKPointAnnotation {
            
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            
            pinAnnotationView.pinTintColor = .purple
            pinAnnotationView.isDraggable = true
            pinAnnotationView.canShowCallout = true
            pinAnnotationView.animatesDrop = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(touchUpAnnotation(_:)))

            pinAnnotationView.addGestureRecognizer(tap)
            
            return pinAnnotationView
        }
        
        return nil
    }
    
    // MARK: - IBAction
    
    @IBAction func currentLocationAction(_ sender: UIButton) {
        
        map.isHidden = false
        clmanager.startUpdatingLocation()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }

    @objc
    @IBAction func touchUpAnnotation(_ sender: UITapGestureRecognizer) {
        
        guard let annotationView = sender.view as? MKPinAnnotationView else {
            
            fatalError("Exception: MKPinAnnotationView is expected")
        }
        
        let annotation = annotationView.annotation as? MKPointAnnotation
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if annotation?.title == "Selected location".localized() {
            
            let unselectOption = UIAlertAction(title: "Unselect it".localized(), style: .default, handler: { (action) in
                
                annotation?.title = "Location".localized()
                
                self.delegate?.newlocation(coordinte: nil)
            })
            
            optionMenu.addAction(unselectOption)
        } else {
            
            let useOption = UIAlertAction(title: "Select it".localized(), style: .default, handler: { (action) in
                
                annotation?.title = "Selected location".localized()
            
                self.delegate?.newlocation(coordinte: (annotationView.annotation?.coordinate)!)
            })
    
            optionMenu.addAction(useOption)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        optionMenu.addAction(cancelAction)
        
        present(optionMenu, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView,
                 annotationView view: MKAnnotationView,
                 didChange newState: MKAnnotationViewDragState,
                 fromOldState oldState: MKAnnotationViewDragState) {
        
        let annotation = view.annotation as? MKPointAnnotation
     
        if annotation?.title == "Selected location".localized() {
            
            self.delegate?.newlocation(coordinte: (view.annotation?.coordinate)!)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations[0]
        
        displayCoordinate(location.coordinate, "Location".localized())
        
        self.clmanager.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addCurrentLocationButton() {
        
        let image = UIImage(named: "location")
        let baritem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.currentLocationAction(_:)))
        navigationItem.setRightBarButton(baritem, animated: true)
    }
    
    private func addBackButton() {
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton.png"), for: .normal)
        backButton.setTitle(" \("Back".localized())", for: .normal)
        backButton.setTitleColor(backButton.tintColor, for: .normal) // You can change the TitleColor
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    /*
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("-------- process search result")
        
        clmanager.stopUpdatingLocation()

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchBar.text!) { (placemark, error) in
            for pm in placemark!
            {
                let p = MKPointAnnotation()
            
                p.title = pm.name
                p.coordinate = (pm.location?.coordinate)!
                self.map.addAnnotation(p)
                
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let currentLocation = CLLocationCoordinate2D(latitude: (pm.location?.coordinate.latitude)!, longitude: (pm.location?.coordinate.longitude)!)
                
                let region = MKCoordinateRegion(center: currentLocation, span: span)
                
                self.map.setRegion(region, animated: true)
            }
        }
        
        searchBar.resignFirstResponder()
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
