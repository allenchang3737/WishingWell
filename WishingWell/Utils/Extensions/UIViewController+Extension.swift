//
//  UIViewController+Extension.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import Foundation
import UIKit
import Alamofire

extension UIViewController {
    //MARK: Check Login
    func checkLogin() -> Bool {
        if AppManager.shared.accessToken == nil {
            return false
            
        }else {
            if UserService.shared.currentUser == nil {
                UserService.shared.getCurrentUser()
            }
            return true
        }
    }
    
    //MARK: Check Network
    func checkRechability() -> Bool {
        guard let manager = NetworkReachabilityManager(host: "www.apple.com") else { return false }
        if manager.isReachable {
            return true
            
        }else {
            return false
        }
    }
    
    //MARK: UIViewController
    func showLoginView(completionHandler: @escaping (_ success: Bool) -> ()) {
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        loginVC.completionHandler = { success in
            completionHandler(success)
        }
        loginVC.modalPresentationStyle = .overFullScreen
        self.present(loginVC, animated: true)
    }
    
    func showPhotoViewerView(images: [UIImage]) {
        let photoViewerVC = PhotoViewerViewController(nibName: "PhotoViewerViewController", bundle: nil)
        photoViewerVC.images = images
        self.navigationController?.pushViewController(photoViewerVC, animated: true)
    }
    
    func showCustomUserView(_ user: User) {
        let customUserVC = CustomUserViewController(nibName: "CustomUserViewController", bundle: nil)
        customUserVC.userId = user.userId
        self.navigationController?.pushViewController(customUserVC, animated: true)
    }
    
    func showReportView(_ receiverUserId: Int) {
        let reportVC = ReportViewController(nibName: "ReportViewController", bundle: nil)
        reportVC.receiverUserId = receiverUserId
        reportVC.modalPresentationStyle = .overCurrentContext
        self.present(reportVC, animated: true, completion: nil)
    }
    
    func showLUNWebView(url: URL) {
        let lunWebVC = LUNWebViewController(nibName: "LUNWebViewController", bundle: nil)
        lunWebVC.url = url
        lunWebVC.modalPresentationStyle = .overCurrentContext
        self.present(lunWebVC, animated: true, completion: nil)
    }
    
    func showPushNoticeView() {
        guard let notice = PushNoticeService.shared.onclickNotice,
              let type = PushType(rawValue: notice.pushType) else { return }
        
        if !self.checkLogin() {
            self.showLoginView { success in
                if success {
                    let pushNoticeVC = PushNoticeViewController(nibName: "PushNoticeViewController", bundle: nil)
                    pushNoticeVC.activeType = type
                    self.navigationController?.pushViewController(pushNoticeVC, animated: true)
                }
            }
            
        }else {
            let pushNoticeVC = PushNoticeViewController(nibName: "PushNoticeViewController", bundle: nil)
            pushNoticeVC.activeType = type
            self.navigationController?.pushViewController(pushNoticeVC, animated: true)
        }
    }
    
    func showConversationsView() {
        let conversationsVC = ConversationsViewController(nibName: "ConversationsViewController", bundle: nil)
        self.navigationController?.pushViewController(conversationsVC, animated: true)
    }
    
    func showProductDetailView(type: ViewType, product: Product, productUser: User?) {
        let productDetailVC = ProductDetailViewController(nibName: "ProductDetailViewController", bundle: nil)
        productDetailVC.viewType = type
        productDetailVC.product = product
        productDetailVC.productUser = productUser
        self.navigationController?.pushViewController(productDetailVC, animated: true)
    }
    
    func showOrderDetailView(type: ViewType, order: Order) {
        let orderDetailVC = OrderDetailViewController(nibName: "OrderDetailViewController", bundle: nil)
        orderDetailVC.viewType = type
        orderDetailVC.order = order
        self.navigationController?.pushViewController(orderDetailVC, animated: true)
    }
    
    func getPadding() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        var padding: CGFloat = 0
        if screenWidth == 320 {
            padding = 35
        
        }else if screenWidth == 375 {
            padding = 85
            
        }else {     //screenWidth = 414
            padding = 90
        }
        return padding
    }
    
    //MARK: TabBar
    func showTabBar() {
        if self.tabBarController != nil {
            self.tabBarController?.tabBar.isHidden = false
        }
    }
    
    func hideTabBar() {
        if self.tabBarController != nil {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    //MARK: NavigationBar
    func showNavigationBar(isLarge: Bool = false) {
        if navigationController != nil {
            navigationController?.navigationBar.isHidden = false
            navigationController?.navigationBar.prefersLargeTitles = isLarge
        }
    }
    
    func hideNavigationBar(isLarge: Bool = false) {
        if navigationController != nil {
            navigationController?.navigationBar.isHidden = true
            navigationController?.navigationBar.prefersLargeTitles = isLarge
        }
    }
    
    //MARK: Hide Keyboard
    func hideKeyboardWhenTappedAround(_ view: UIView) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: Text Validation
    func isEmptyValid(_ text: String?) -> Bool {
        guard let text = text else { return true }
        if text.count == 0 {
            return true
        
        }else{
            return false
        }
    }
    
    func isEmailValid(_ text: String?) -> Bool {
        guard let text = text else { return false }
        let regex = "[A-Z0-9a-z._]+@([\\w\\d]+[\\.\\w\\d]*)"
        return text.evaluate(with: regex)
    }
    
    func isPasswordValid(_ text: String?) -> Bool {
        guard let text = text else { return false }
        let regex = "^[A-Z0-9a-z]{6,}$"
        return text.evaluate(with: regex)
    }
    
    func isAccountValid(_ text: String?) -> Bool {
        guard let text = text else { return false }
        let regex = "^[A-Z0-9a-z_.]+"
        return text.evaluate(with: regex)
    }
    
    func isPhoneValid(_ text: String?) -> Bool {
        guard let text = text else { return false }
        let regex = "^09[0-9]{8}$"
        return text.evaluate(with: regex)
    }
    
    func isUrlValid(_ urlString: String?) -> Bool {
        guard let url = URL(string: urlString ?? "") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    //MARK: Alert
    func showAlert(title: String?, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Confirm".localized(), style: .default, handler: nil)
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: String?, message: String, completionHandler: @escaping () -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Confirm".localized(), style: .default) { action in
            completionHandler()
        }
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlert(title: String?, message: String, showCancel: Bool, confirmTitle: String? = nil, completionHandler: @escaping () -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        //Cancel
        if showCancel {
            let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
            alert.addAction(cancel)
        }
        //Confirm
        var text = "Confirm".localized()
        if let title = confirmTitle {
            text = title
        }
        let confirm = UIAlertAction(title: text, style: .default) { action in
            completionHandler()
        }
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showOpenSetting(title: String?, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        let confirm = UIAlertAction(title: "Move".localized(), style: .default) { action in
            //open app settings
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { success in
                    print("Settings opened: \(success)")
                })
            }
        }
        
        alert.addAction(confirm)
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Activity Indicator
    func showActivityIndicator() {
        DispatchQueue.main.async {
            guard self.view.viewWithTag(997) == nil else {
                print("Exists Activity Indicator View...")
                return
            }
//            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let activityIndicatorView = UIActivityIndicatorView()
            activityIndicatorView.custom(self.view, startAnimate: true)
            activityIndicatorView.tag = 997
            self.view.addSubview(activityIndicatorView)
            print("Show Activity Indicator View...")
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
//            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let activityIndicatorView = self.view.viewWithTag(997) as? UIActivityIndicatorView {
                activityIndicatorView.custom(self.view, startAnimate: false)
                activityIndicatorView.removeFromSuperview()
            }
        }
    }
    
    func getDeviceIsLandscape() -> Bool {
        if #available(iOS 16.0, *) {
            return UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation
                .isLandscape ?? false
            
        }else {
            return UIDevice.current.orientation.isLandscape
        }
    }
}
