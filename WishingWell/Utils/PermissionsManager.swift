//
//  PermissionsManager.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/11/21.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import Foundation
import AVFoundation
import UserNotifications
import Photos
import MapKit
import AppTrackingTransparency

enum PermissionRequestType {
    case camera
    case photoLibrary
    case notification
    case location
    case tracking
}

public protocol PermissionInterface {
    func isAuthorized() -> Bool
    func request(with complectionHandler: @escaping (_ granted: Bool) -> ()?)
}

class PermissionsManager {
    func isAuthorizedPermission(_ permission: PermissionRequestType) -> Bool {
        guard let manager = self.getManagerForPermission(permission) else { return false }
        return manager.isAuthorized()
    }
    
    func requestPermission(_ permission: PermissionRequestType, with complectionHandler: @escaping (_ granted: Bool) -> ()) {
        guard let manager = self.getManagerForPermission(permission) else { return }
        manager.request { granted in
            complectionHandler(granted)
        }
    }
    
    private func getManagerForPermission(_ permission: PermissionRequestType) -> PermissionInterface? {
        switch permission {
        case .camera:
            return CameraPermission()
            
        case .photoLibrary:
            return PhotoLibraryPermission()
            
        case .notification:
            return NotificationPermission()
            
        case .location:
            return LocationPermission()
            
        case .tracking:
            if #available(iOS 14, *) {
                return TrackingPermission()
            
            }else {
                return nil
            }
        }
    }
}

//MARK: Camera Permission
class CameraPermission: PermissionInterface {
    func isAuthorized() -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            return true
        
        }else {
            return false
        }
    }
    
    func request(with complectionHandler: @escaping (Bool) -> ()?) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                complectionHandler(granted)
            }
        }
    }
}

//MARK: Notification Permission
class NotificationPermission: PermissionInterface {
    func isAuthorized() -> Bool {
        return UIApplication.shared.isRegisteredForRemoteNotifications
    }
    
    func request(with complectionHandler: @escaping (Bool) -> ()?) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                DispatchQueue.main.async {
                    complectionHandler(granted)
                }
            }
        }else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
}

//MARK: PhotoLibrary Permission
class PhotoLibraryPermission: PermissionInterface {
    func isAuthorized() -> Bool {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            return true
        
        }else {
            return false
        }
    }
    
    func request(with complectionHandler: @escaping (Bool) -> ()?) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                complectionHandler(true)
            
            }else {
                complectionHandler(false)
            }
        }
    }
}

//MARK: Location Permission
class LocationPermission: PermissionInterface {
    func isAuthorized() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
            
        default:
            return false
        }
    }
    
    func request(with complectionHandler: @escaping (Bool) -> ()?) {
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        //要加入notDetermined(未決定)
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined:
            complectionHandler(true)
            
        default:
            complectionHandler(false)
        }
    }
}

//MARK: Tracking Permission
@available(iOS 14, *)
class TrackingPermission: PermissionInterface {
    func isAuthorized() -> Bool {
        if ATTrackingManager.trackingAuthorizationStatus == .authorized {
            return true
        
        }else {
            return false
        }
    }
    
    func request(with complectionHandler: @escaping (Bool) -> ()?) {
        ATTrackingManager.requestTrackingAuthorization { status in
            if status == .authorized {
                complectionHandler(true)
            
            }else {
                complectionHandler(false)
            }
        }
    }
}
