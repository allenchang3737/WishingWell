//
//  ShareMapViewController.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2024/1/22.
//  Copyright © 2024 LunYuChang. All rights reserved.
//

import UIKit
import MapKit

class ShareMapViewController: UIViewController {
    @IBOutlet weak var mapview: MKMapView!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var photoImageview: UIImageView!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    //Configuration
    var viewType: ViewType = .Watch
    var product: Product?
        
    //Data
    let locationManager = CLLocationManager()
    let meters: CLLocationDistance = 3000
    var centerCoordinate: CLLocationCoordinate2D?
    
    var completionHandler: ((_ address: String?,
                             _ latitude: Double,
                             _ longitude: Double) -> ())?
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(self.mapview)
        setupLayout()
    }
    
    func setupLayout() {
        //Map View
        mapview.delegate = self
        //TODO: mapview register AnnotationView
        
        //Set Location Manager
        locationManager.delegate = self
        // 距離篩選器 用來設置移動多遠距離才觸發委任方法更新位置
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        // 取得自身定位位置的精確度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let manager = PermissionsManager()
        manager.requestPermission(.location) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.locationManager.startUpdatingLocation()
                    self.getCurrentLocation()
                    
                }else {
                    
                    self.setProductLocation()
                }
            }
        }
        
        //Address TextField
        addressTextField.delegate = self
        addressTextField.placeholder = "Address".localized() + "(Optional)".localized()
        
        //Photo image view
        handleImage()
        
        //Button View
        switch self.viewType {
        case .Create, .Update:
            buttonview.button.setTitle("Confirm".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
            
        case .Watch:
            buttonview.button.setTitle("Navigation".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(navigateAction), for: .touchUpInside)
            //Location Pin 不可變動
            mapview.isUserInteractionEnabled = false
            addressTextField.isHidden = true
        }
    }
    
    private func handleImage() {
        photoImageview.isHidden = true
        pinImageView.image = UIImage(named: "location_full_128")
        
        guard let fileId = self.product?.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId else { return }
        FileService.shared.getImage(fileId: fileId) { image in
            self.photoImageview.image = image
            self.photoImageview.isHidden = false
            self.pinImageView.image = UIImage(named: "location_128")
        }
    }
    
    func getCurrentLocation() {
        guard let location = self.locationManager.location else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: self.meters, longitudinalMeters: self.meters)
        
        mapview.setRegion(region, animated: true)
        mapview.regionThatFits(region)
        
        setProductLocation()
    }
    
    func setProductLocation() {
        guard let latitude = self.product?.latitude,
              let longitude = self.product?.longitude,
              latitude != 0,
              longitude != 0 else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: self.meters, longitudinalMeters: self.meters)
        
        mapview.setRegion(region, animated: true)
        mapview.regionThatFits(region)
    }
    
    private func getLocationCoordinate(address: String) {
        let coder = CLGeocoder()
        let locale = Locale(identifier: "zh_Hant_TW") //設定地區(台灣)：text顯示英文修正
        coder.geocodeAddressString(address, in: nil, preferredLocale: locale) { placemarks, error in
            if let error = error {
                print("getLocationCoordinate error: \(error.localizedDescription)")
                self.addressTextField.text = nil
            
            }else {
                guard let placemark = placemarks?.first,
                      let coordinate = placemark.location?.coordinate else { return }
                self.addressTextField.text = address
                self.product?.latitude = Double(coordinate.latitude)
                self.product?.longitude = Double(coordinate.longitude)
                self.setProductLocation()
            }
        }
    }
    
    func validateCoordinate() -> Bool {
        //Coordinate
        if let _ = self.centerCoordinate?.latitude,
           let _ = self.centerCoordinate?.longitude {
            print("Coordinate success")
            
        }else {
            showAlert(title: nil, message: "Coordinate fail".localized())
            return false
        }
        return true
    }
    
    //MARK: Action
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func confirmAction() {
        if validateCoordinate() {
            guard let latitude = self.centerCoordinate?.latitude,
                  let longitude = self.centerCoordinate?.longitude else { return }
            self.completionHandler?(addressTextField.text, latitude, longitude)
            self.dismiss(animated: true)
        }
    }
    
    @objc func navigateAction() {
        guard let latitude = self.product?.latitude,
              let longitude = self.product?.longitude else { return }
        OpenManager.shared.openGoogleMap(latitude: latitude, longitude: longitude, mode: .driving)
    }
}

//MARK: UITextFieldDelegate
extension ShareMapViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        getLocationCoordinate(address: textField.text ?? "")
    }
}

//MARK: MKMapViewDelegate
extension ShareMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("didSelect view...")
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        print("didSelect annotation...")
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centerCoordinate = mapView.centerCoordinate
        let visibleMapRect = mapView.visibleMapRect
        // Get the coordinates of the top-left and bottom-right corners of the visible map rect
        let topLeftCoordinate = MKMapPoint(x: visibleMapRect.minX, y: visibleMapRect.minY).coordinate
        let bottomRightCoordinate = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.maxY).coordinate
        print("Center Coordinate: \(centerCoordinate)")
        print("Top Left Coordinate: \(topLeftCoordinate.latitude), \(topLeftCoordinate.longitude)")
        print("Bottom Right Coordinate: \(bottomRightCoordinate.latitude), \(bottomRightCoordinate.longitude)")
        
        self.centerCoordinate = centerCoordinate
    }
}

//MARK: CLLocationManagerDelegate
extension ShareMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("didUpdateLocations: [\(coordinate.latitude), \(coordinate.longitude)]")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            print("LocationManagerDidChangeAuthorization: \(manager.authorizationStatus)")
        } else {
            // Fallback on earlier versions
        }
        let manager = PermissionsManager()
        if manager.isAuthorizedPermission(.location) {
            getCurrentLocation()
        }
    }
}
