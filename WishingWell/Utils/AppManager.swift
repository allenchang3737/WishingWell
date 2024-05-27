//
//  AppManager.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/15.
//

import Foundation
import DefaultsKit
import StoreKit
import RealmSwift

class AppManager {
    static let shared = AppManager()
    
    private init() {
        print("AppManager init...")
    }
    
    let defaults = Defaults()
    var pushToken: String?
    
    //Search
    var wishSearch = Search(type: ProductType.WISH.rawValue)
    var buySearch = Search(type: ProductType.BUY.rawValue)
    
    var currentUserId: Int? {
        get {
            return defaults.get(for: MyKey.DefaultsKey.currentUserId)
        }
        set {
            if let id = newValue {
                defaults.set(id, for: MyKey.DefaultsKey.currentUserId)
                
            }else {
                defaults.clear(MyKey.DefaultsKey.refreshToken)
            }
        }
    }
    
    ///Access Token
    var accessToken: String? {
        get {
            return defaults.get(for: MyKey.DefaultsKey.accessToken)
        }
        set {
            if let token = newValue {
                setAccessToken(token)
            
            }else {
                clearAccessToken()
            }
        }
    }
    
    ///Refresh Token
    var refreshToken: String? {
        get {
            return defaults.get(for: MyKey.DefaultsKey.refreshToken)
        }
        set {
            if let token = newValue {
                defaults.set(token, for: MyKey.DefaultsKey.refreshToken)
                
            }else {
                defaults.clear(MyKey.DefaultsKey.refreshToken)
            }
        }
    }
    
    ///Token 效期
    var tokenTimer: Timer?
    private var tokenTimeOut = TimeInterval(60 * 60)    //60分鐘失效
    private var tokenExpiryTime: TimeInterval? {
        get {
            guard let start = defaults.get(for: MyKey.DefaultsKey.tokenStart) else { return nil }
            let timeInterval = abs(start.timeIntervalSinceNow)
            let expiryTime = self.tokenTimeOut - timeInterval
            return expiryTime < 0 ? 0 : expiryTime
        }
    }
    
    private func setAccessToken(_ token: String) {
        print("--------------------------------------------------")
        print("setAccessToken: \(token)")
        print("--------------------------------------------------")
        defaults.set(token, for: MyKey.DefaultsKey.accessToken)
        defaults.set(Date(), for: MyKey.DefaultsKey.tokenStart)
        startTokenTimer()
    }
    
    private func clearAccessToken() {
        defaults.clear(MyKey.DefaultsKey.accessToken)
        defaults.clear(MyKey.DefaultsKey.tokenStart)
        tokenTimer?.invalidate()
    }
    
    func startTokenTimer() {
        //Clear Timer
        self.tokenTimer?.invalidate()
        
        guard var expiryTime = self.tokenExpiryTime else { return }
        self.tokenTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//            print("Token Expiry Time: \(expiryTime)")
            if expiryTime > 0 {
                expiryTime -= 1
            
            }else {
                self.tokenTimer?.invalidate()
                UserService.shared.refreshToken()
            }
        }
    }
}

//MARK: NavigationBar Appearance
extension AppManager {
    func setAppearance() {
        if #available(iOS 13.0, *) {
            UINavigationBar.appearance().tintColor = .label
            UINavigationBarAppearance().shadowColor = .clear    //Clear NaviationBar under line
            
        }else {
            UINavigationBar.appearance().tintColor = .label
            
            //Clear NaviationBar under line
            UINavigationBar.appearance().shadowImage = UIImage()
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        }
    }
}

//MARK: StoreKit
extension AppManager {
    func increaseNumberOfRuns() {
        let runs = (defaults.get(for: MyKey.DefaultsKey.numberOfRuns) ?? 0) + 1
        defaults.set(runs, for: MyKey.DefaultsKey.numberOfRuns)
    }
    
    func showStoreKit() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let runs = defaults.get(for: MyKey.DefaultsKey.numberOfRuns) else { return }
        let storeKitVersion = defaults.get(for: MyKey.DefaultsKey.storeKitVersion) ?? ""
        
        if currentVersion != storeKitVersion,
           runs % 10 == 0 {
            if #available(iOS 14.0, *) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                    defaults.set(currentVersion, for: MyKey.DefaultsKey.storeKitVersion)
                }
                
            }else if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
                defaults.set(currentVersion, for: MyKey.DefaultsKey.storeKitVersion)
            }
        
        }else {
            print("---------------------------------------------")
            print("Skip to show StoreKit")
            print("Current Version: \(currentVersion)")
            print("StoreKit Version: \(storeKitVersion)")
            print("Number Of Runs: \(runs)")
            print("---------------------------------------------")
        }
    }
}

//MARK: Realm
extension AppManager {
    public func setDefaultRealm() {
        // -----------------------------------------------------------------
        // Version History
        // -----------------------------------------------------------------
        // 0: Original
        // -----------------------------------------------------------------
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 6,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
}
