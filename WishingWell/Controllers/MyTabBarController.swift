//
//  MyTabBarController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import UIKit
import Localize_Swift
import EasyTipView

class MyTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        registerNotifications()
        setupLayout()
        prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("MyTabBarController viewWillAppear...")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("MyTabBarController viewDidAppear...")
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(showAlert(notification:)),
                                               name: .showAlertNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateNoticeBadge),
                                               name: .updateNoticeBadgeCompleted,
                                               object: nil)
    }
    
    func setupLayout() {
        tabBar.tintColor = .label
        tabBar.items?[0].title = "Buy".localized()
        tabBar.items?[1].title = "Wish".localized()
        tabBar.items?[2].title = "My".localized()
    }

    func prepare() {
        //Check Version
        VersionService.shared.checkVersion { response in
            if response.hasNewVersion {
                self.showUpdateApp(isEnforce: response.enforce ?? false,
                                   downloadUrl: response.downloadUrl ?? "")
            }
        }
        
        //AppConfig
        AppConfigService.shared.getAppConfig()
        
        //TokenTimer
        AppManager.shared.startTokenTimer()
        
        //檢查用戶登入
        checkCurrentUser()
        updateNoticeBadge()
        
        setEasyTipView()
    }
    
    private func checkCurrentUser() {
        guard AppManager.shared.accessToken != nil,
              UserService.shared.currentUser == nil else { return }
            
        UserService.shared.getCurrentUser()
    }
    
    @objc private func updateNoticeBadge() {
        let count = PushNoticeService.shared.findAllUnreadCount()
        if count != 0 {
            self.tabBar.items?[2].badgeValue = "\(count)"
            
        }else {
            self.tabBar.items?[2].badgeValue = nil
        }
        
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    @objc private func showAlert(notification: Notification) {
        let title = notification.userInfo?[MyKey.UserInfo.title] as? String
        let message = notification.userInfo?[MyKey.UserInfo.message] as? String
        
        UIApplication.topViewController()?.hideActivityIndicator()
        UIApplication.topViewController()?.showAlert(title: title, message: message ?? "")
    }
    
    func showUpdateApp(isEnforce: Bool, downloadUrl: String) {
        let alert = UIAlertController(title: "Update version".localized(),
                                      message: "The application have been update version".localized(),
                                      preferredStyle: .alert)
        if !isEnforce {
            let cancel = UIAlertAction(title: "I got it".localized(), style: .cancel, handler: nil)
            alert.addAction(cancel)
        }
        let confirm = UIAlertAction(title: "Go to app store".localized(), style: .default) { action in
            OpenManager.shared.openURL(url: downloadUrl)
        }
        alert.addAction(confirm)
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func setEasyTipView() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont.preferredFont(forTextStyle: .footnote)
        preferences.drawing.foregroundColor = .lightText
        preferences.drawing.backgroundColor = .systemGray
        preferences.drawing.arrowPosition = .top
        preferences.drawing.textAlignment = .left
        
        EasyTipView.globalPreferences = preferences
    }
}
