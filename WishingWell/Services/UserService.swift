//
//  UserService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON
import DefaultsKit

class UserService {
    static let shared: UserService = UserService()
    
    private init() {
        print("UserService init..")
    }
    
    let defaults = Defaults()
    var currentUser: User?
    
    //MARK: Login
    /// Login
    /// Parameters
    /// - `authType`:  登入方式 "ACCOUNT", "FACEBOOK", "GOOGLE", "APPLE"
    /// - `account`: 帳號
    /// - `password`: 密碼
    /// - `authUserId`: 第三方登入ID
    /// - `isNotExist`: 第三方登入不存在需註冊
    func login(authType: AuthType, account: String?, password: String?, authUserId: String?, completionHandler: @escaping (_ isNotExist: Bool) -> ()) {
#if DEV
        DispatchQueue.main.async {
            AppManager.shared.accessToken = "token123"
            self.getCurrentUser()
            completionHandler(false)
        }
#else
        let path = APIManager().getBaseURL() + "/uc/login"
        let params: Parameters = ["authType": authType.rawValue,
                                  "account": account ?? "",
                                  "password": AESManager.shared.encrypt(str: password ?? "") ?? "", //機敏資料->加密
                                  "authUserId": authUserId ?? ""]
        
        AF.request(path, method: .post, parameters: params).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<LoginRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        if store.status == BaseStatus.ERROR0001.rawValue {
                            completionHandler(true)
                        
                        }else {
                            NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        }
                        return
                    }
                    //Set Token
                    AppManager.shared.accessToken = result.accessToken
                    AppManager.shared.refreshToken = result.refreshToken
                    
                    self.getCurrentUser()
                    completionHandler(false)
                    
                }catch {
                    print("login JSON Decoded Error: \(error.localizedDescription)")
                }
            
            case .failure(let error):
                print("login Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Sign up
    /// Parameters
    /// - `authType`: 註冊方式 "ACCOUNT", "FACEBOOK", "GOOGLE", "APPLE"
    /// - `account`: 帳號
    /// - `email`: 電子郵件
    /// - `password`: 密碼
    /// - `authUserId`: 第三方登入ID
    func signUp(authType: AuthType, account: String, email: String?, password: String?, authUserId: String?, completionHandler: @escaping (_ userId: Int) -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler(99)
        }
#else
        let path = APIManager().getBaseURL() + "/uc/signUp"
        let params: Parameters = [User.InfoKey.authType: authType.rawValue,
                                  User.InfoKey.account: account,
                                  User.InfoKey.email: email ?? "",
                                  User.InfoKey.password: AESManager.shared.encrypt(str: password ?? "") ?? "",   //機敏資料->加密
                                  User.InfoKey.authUserId: authUserId ?? ""]
        
        AF.request(path, method: .post, parameters: params).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<UserIdRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result.userId)

                }catch {
                    print("signUp JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("signUp Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Logout: no need to notify the server
    /// Parameters
    func logout(completionHandler: @escaping () -> ()) {
        AppManager.shared.accessToken = nil
        AppManager.shared.refreshToken = nil
        UserService.shared.currentUser = nil
        
        //Clear push notices
        PushNoticeService.shared.clearNotices()
    
        completionHandler()
    }
    
    /// Forget password
    /// Parameters
    /// - `token`: otp token
    /// - `password`: 密碼
    func forgetPwd(token: String, password: String, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/uc/forgetPwd"
        let params: Parameters = [User.InfoKey.password: AESManager.shared.encrypt(str: password) ?? ""]   //機敏資料->加密
        let headers: HTTPHeaders = [.authorization(bearerToken: token)]
        
        AF.request(path, method: .post, parameters: params, headers: headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler()
                    
                }catch {
                    print("forgetPassword JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("forgetPassword Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Change password
    /// Parameters
    /// - `oldPwd`: 舊密碼
    /// - `newPwd`: 新密碼
    func changePwd(oldPwd: String, newPwd: String, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/uc/changePwd"
        let params: Parameters = ["oldPwd": AESManager.shared.encrypt(str: oldPwd) ?? "",   //機敏資料->加密
                                  "newPwd": AESManager.shared.encrypt(str: newPwd) ?? ""]   //機敏資料->加密
        
        AF.request(path, method: .post, parameters: params, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler()
                    
                }catch {
                    print("changePassword JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("changePassword Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Refresh token
    /// Parameters
    func refreshToken() {
#if DEV
        print("--------------------------------------------------")
        print("no need to refresh token")
        print("--------------------------------------------------")
#else
        let path = APIManager().getBaseURL() + "/uc/refreshToken"
        let params: Parameters = ["refreshToken": AppManager.shared.refreshToken ?? ""]
        
        AF.request(path, method: .get, parameters: params, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<LoginRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        return
                    }
                    //Set Token
                    AppManager.shared.accessToken = result.accessToken
                    AppManager.shared.refreshToken = result.refreshToken
                    
                    self.getCurrentUser()
                    
                }catch {
                    print("refreshToken JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("refreshToken Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    //MARK: User
    /// Get current user
    /// Parameters
    func getCurrentUser() {
#if DEV
        if let path = Bundle.main.path(forResource: "current_user", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<User>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    return
                }
                
                self.currentUser = result
                AppManager.shared.currentUserId = result.userId
                
                //取得用戶訊息
                PushNoticeService.shared.getPushNotice(pushType: .PERSONAL)
                PushNoticeService.shared.getPushNotice(pushType: .ORDER)
                PushNoticeService.shared.getPushNotice(pushType: .ACTIVITY)
                
                NotificationCenter.default.post(name: .currentUserCompleted, object: nil)
                
            }catch {
                print("current_user JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/uc/user"
        
        AF.request(path, method: .get, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<User>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    
                    self.currentUser = result
                    AppManager.shared.currentUserId = result.userId
                    
                    //取得用戶訊息
                    PushNoticeService.shared.getPushNotice(pushType: .PERSONAL)
                    PushNoticeService.shared.getPushNotice(pushType: .ORDER)
                    PushNoticeService.shared.getPushNotice(pushType: .ACTIVITY)
                    
                    NotificationCenter.default.post(name: .currentUserCompleted, object: nil)
                    
                }catch {
                    print("getCurrentUser JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("getCurrentUser Error: \(response.response?.statusCode ?? 0) - \(error)")
                if let code = response.response?.statusCode,
                   code == 400 || code == 401 || code == 403 {
                    self.refreshToken()
                }
            }
        }
#endif
    }
    
    /// Update current user
    /// Parameters
    /// - `user`: current user object
    func updateCurrentUser(user: User, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/uc/user"
        let params: Parameters = [User.InfoKey.email: user.email,
                                  User.InfoKey.phone: user.phone,
                                  User.InfoKey.intro: user.intro,
                                  User.InfoKey.userType: user.userType]
        
        AF.request(path, method: .put, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    
                    self.getCurrentUser()
                    completionHandler()
                    
                }catch {
                    print("updateCurrentUser JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("updateCurrentUser Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Delete current user
    /// Parameters
    func deleteCurrentUser(completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            self.logout {
                completionHandler()
            }
        }
#else
        let path = APIManager().getBaseURL() + "/uc/user"
        
        AF.request(path, method: .delete, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    
                    self.logout {
                        completionHandler()
                    }

                }catch {
                    print("deleteCurrentUser JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("deleteCurrentUser Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get user
    /// Parameters
    /// - `userId`:  user PK
    func getUser(userId: Int, completionHandler: @escaping (User?) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "other_user", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<User>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    completionHandler(nil)
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(result)
                }
                
            }catch {
                print("other_user JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/uc/user/\(userId)"
        
        AF.request(path, method: .get).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<User>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(result)
                    
                }catch {
                    print("getUser JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("getUser Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /*
    /// Search users
    /// Parameters
    /// - `search`:  search object
    func searchUsers(search: Search, completionHandler: @escaping ([User]) -> ()) {
        print("--------------------------------------------------")
        print("Search Data: \(search)")
        print("--------------------------------------------------")
#if DEV
        if let path = Bundle.main.path(forResource: "search_users", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[User]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("search_users JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/uc/users"
        let params: Parameters = [Search.InfoKey.text: search.text,
                                  Search.InfoKey.page: search.page,
                                  Search.InfoKey.size: search.size,
                                  Search.InfoKey.direction: search.direction,
                                  Search.InfoKey.properties: search.properties]
        
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[User]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)
                    
                }catch {
                    print("searchUsers JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("searchUsers Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    */
}
