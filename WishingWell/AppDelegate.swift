//
//  AppDelegate.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/13.
//

import UIKit
import UserNotifications
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Set realm
        AppManager.shared.setDefaultRealm()
        
        //Set Firebase
        FirebaseApp.configure()
        
        //Set Push service
        registerUserNotification()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    /// iOS10 以下的版本接收推播訊息的 delegate
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("---------------------------------------------------------------")
        print("didReceiveRemoteNotification: \(userInfo)")
        print("---------------------------------------------------------------")
    }
    
    /// 取得 DeviceToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.hexDescription
        print("---------------------------------------------------------------")
        print("Device Token: \(token)")
        print("---------------------------------------------------------------")
    }
}

//MARK: UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    //App 在前景時，推播送出時即會觸發的 delegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("---------------------------------------------------------------")
        print("willPresent: \(userInfo)")
        print("---------------------------------------------------------------")
        checkPushNotice(userInfo: userInfo)
        
        //可設定要收到什麼樣式的推播訊息，至少要打開alert，不然會收不到推播訊息
        completionHandler([.badge, .sound, .alert])
    }
    
    //App 在關掉的狀態下或 App 在背景或前景的狀態下，點擊推播訊息時所會觸發的 delegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        
        let userInfo = response.notification.request.content.userInfo
        print("---------------------------------------------------------------")
        print("didReceive: \(userInfo)")
        print("---------------------------------------------------------------")
        checkPushNotice(userInfo: userInfo, onClick: true)
        
        completionHandler()
    }
}

//MARK: MessagingDelegate
extension AppDelegate: MessagingDelegate {
    //iOS10 含以上的版本用來接收 firebase token 的 delegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        
        //用來從 firebase 後台推送單一裝置所必須的 firebase token
        print("Firebase token: \(fcmToken ?? "")")
        AppManager.shared.pushToken = fcmToken
        
        //檢查裝置資訊
        if DeviceService.shared.isChangedDevice() {
            DeviceService.shared.createDevice()
        }
    }
}

extension AppDelegate {
    func registerUserNotification() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        let manager = PermissionsManager()
        manager.requestPermission(.notification) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("notification granted: 允許...")
                    
                }else {
                    print("notification granted: 不允許...")
                }
            }
        }
    }
    
    func checkPushNotice(userInfo: [AnyHashable : Any], onClick: Bool = false) {
        guard let data = userInfo[AnyHashable("pushNotice")] as? String,
              let pushNotice = try? PushNotice(decoding: data) else {
            print("pushNotice decoding fail...")
            return
        }
        print("--------------------------------------------------")
        print("pushNotice: \(pushNotice)")
        print("--------------------------------------------------")
    
        if onClick {
            PushNoticeService.shared.checkPushActionToMove(push: pushNotice)
        }
    }
}
