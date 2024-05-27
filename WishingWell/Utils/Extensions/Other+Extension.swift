//
//  Other+Extension.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import Foundation
import UIKit

extension UIActivityIndicatorView {
    func custom(_ viewContainer: UIView, startAnimate: Bool) {
        let mainContainer: UIView = UIView(frame: viewContainer.frame)
        mainContainer.center = viewContainer.center
        mainContainer.backgroundColor = .black
        mainContainer.alpha = 0.5
        mainContainer.tag = 999
        
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        activityIndicatorView.center = mainContainer.center
        activityIndicatorView.style = .medium
        
        if startAnimate {
            mainContainer.addSubview(activityIndicatorView)
            viewContainer.addSubview(mainContainer)
            activityIndicatorView.startAnimating()
            
        }else {
            activityIndicatorView.stopAnimating()
            for subview in viewContainer.subviews {
                if subview.tag == 999 {
                    subview.removeFromSuperview()
                }
            }
        }
    }
}

extension UIApplication {
    static func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
            
        }else if let tab = base as? UITabBarController,
                 let selected = tab.selectedViewController {
            return topViewController(base: selected)
            
        }else if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

extension Double {
    func priceFormatting() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        
        let formatted = formatter.string(from: NSNumber(value: self))
        return formatted ?? ""
    }
}

extension UIColor {
    public static func convertProductStatus(_ status: Int) -> UIColor {
        let status = ProductStatus(rawValue: status)
        switch status {
        case .NOTDEPLOYED, .EXPIRED, .TERMINATED:
            return .systemGray
            
        case .DEPLOYED, .PROCESSING:
            return .systemGreen
            
        case .SUSPENDED:
            return .systemOrange
            
        default:
            return .clear
        }
    }
    
    public static func convertOrderStatus(_ status: Int) -> UIColor {
        let status = OrderStatus(rawValue: status)
        switch status {
        case .DISCUSSING, .COMPLETED:
            return .label
        
        case .PROCESSING:
            return .systemGreen
        
        case .CANCELED:
            return .systemGray
            
        default:
            return .clear
        }
    }
}

extension UIToolbar {
    func toolbarPicker(target: Any?, 
                       selector: Selector,
                       targetClear: Any? = nil,
                       selectorClear: Selector? = nil) {
        self.barStyle = UIBarStyle.default
        self.isTranslucent = true
        self.sizeToFit()
        
        let doneBtn = UIBarButtonItem(title: "Finish".localized(), style: .plain, target: target, action: selector)
        doneBtn.tintColor = .label
        let spaceBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        if let targetClear = targetClear,
           let selectorClear = selectorClear {
            let clearBtn = UIBarButtonItem(title: "Clear".localized(), style: .plain, target: targetClear, action: selectorClear)
            clearBtn.tintColor = .label
            self.setItems([clearBtn, spaceBtn, doneBtn], animated: false)
       
        }else {
            self.setItems([spaceBtn, doneBtn], animated: false)
        }
        
        self.isUserInteractionEnabled = true
    }
}

extension UITextField {
    private static var _type: [String : Int] = [:]
    var type: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UITextField._type[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UITextField._type[key] = newValue
        }
    }
    
    private static var _section: [String : Int] = [:]
    var section: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UITextField._section[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UITextField._section[key] = newValue
        }
    }
    
    private static var _row: [String : Int] = [:]
    var row: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UITextField._row[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UITextField._row[key] = newValue
        }
    }
}

extension UIButton {
    private static var _type: [String : Int] = [:]
    var type: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIButton._type[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIButton._type[key] = newValue
        }
    }
    
    private static var _section: [String : Int] = [:]
    var section: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIButton._section[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIButton._section[key] = newValue
        }
    }
    
    private static var _row: [String : Int] = [:]
    var row: Int {
        get {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return UIButton._row[key] ?? 0
        }
        set(newValue) {
            let key = String(format: "%p", unsafeBitCast(self, to: Int.self))
            UIButton._row[key] = newValue
        }
    }
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}
