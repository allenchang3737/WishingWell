//
//  OpenManager.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/12/10.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

enum DirectionsMode: String {
    case driving = "driving"
    case transit = "transit"
    case bicycling = "bicycling"
    case walking = "walking"
}

class OpenManager: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = OpenManager()
    
    private override init() {
        print("OpenManager init...")
    }
    
    //saddr：起點,可以是"緯度,經度"或是地址
    //daddr：終點,可以是"緯度,經度"或是地址
    //directionsmode：運輸方法,可以為：driving、transit、bicycling或 walking
    func openGoogleMap(latitude: Double, longitude: Double, mode: DirectionsMode) {
        guard let url = URL(string: "comgooglemaps://?saddr=&daddr=\(latitude),\(longitude)&directionsmode=\(mode.rawValue)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
        }else {
            //若手機沒安裝 Google Map App 則導到 App Store(id443904275 為 Google Map App 的 ID)
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id585027354") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func openPhone(phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        
        }else {
            print("openPhone fail...")
        }
    }
    
    func openURL(url: String) {
        guard let url = URL(string: url) else { return }
        if UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
           
            }else {
                UIApplication.shared.openURL(url)
            }
        
        }else {
            print("openURL fail...")
        }
    }
    
    func sendEmail(email: String, subject: String?, message: String?) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["\(email)"])
            if let subject = subject {
                mail.setSubject(subject)
            }
            if let message = message {
                mail.setMessageBody(message, isHTML: true)
            }
            UIApplication.topViewController()?.present(mail, animated: true)
            
        }else {
            guard let topVC = UIApplication.topViewController(),
                  let url = URL(string: "https://support.apple.com/zh-tw/HT201320") else { return }
            topVC.showAlert(title: "Open email setting".localized(),
                                                         message: "Go to explain".localized(),
                                                         showCancel: true) {
                topVC.showLUNWebView(url: url)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func shareItems(activityItems: [Any], sender: UIView) {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, 
                                                   completed: Bool,
                                                   returnedItems: [Any]?, error: Error?) in
            if let error = error {
                print("shareItems error: \(error.localizedDescription)")
            }else {
                print("shareItems completed: \(completed)")
            }
        }
        
        //For iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        UIApplication.topViewController()?.present(activityVC, animated: true, completion: nil)
    }
}

