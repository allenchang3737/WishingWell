//
//  PushNoticeService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON
import DefaultsKit
import RealmSwift

class PushNoticeService {
    static let shared: PushNoticeService = PushNoticeService()
    
    private init() {
        print("PushNoticeService init..")
    }
    
    let defaults = Defaults()
    var onclickNotice: PushNotice?  //onclick 推播
    
    var personalBadge: Int {
        get {
            return findUnreadCount(.PERSONAL)
        }
    }
    var orderBadge: Int {
        get {
            return findUnreadCount(.ORDER)
        }
    }
    var activityBadge: Int {
        get {
            return findUnreadCount(.ACTIVITY)
        }
    }
    
    func parseNotice(data: String) -> PushNotice? {
        do {
            let notice = try PushNotice(decoding: data)
            //Save to Realm
            if let type = PushType(rawValue: notice.pushType) {
                self.saveNotice([notice], type)
            }
            return notice
            
        }catch {
            print("parsePushNotice Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func findUnreadCount(_ type: PushType) -> Int {
        let realm = try! Realm()
        let count = realm.objects(PushNoticeOb.self).filter("isRead == %@ AND pushType == %@", false, type.rawValue).count
        
        return count
    }
    
    func findAllUnreadCount() -> Int {
        let realm = try! Realm()
        let count = realm.objects(PushNoticeOb.self).filter("isRead == %@", false).count
        
        return count
    }
    
    func getNotice(_ type: PushType) -> [PushNoticeOb] {
        let realm = try! Realm()
        let objs = realm.objects(PushNoticeOb.self).filter("pushType == %@", type.rawValue).sorted(byKeyPath: "createDate", ascending: false)
        let notices = Array(objs)
        
        return notices
    }
    
    private func setLastDate(_ notice: [PushNotice], _ type: PushType) {
        guard let last = notice.sorted(by: { $0.createDate > $1.createDate }).first else { return }
        let date = last.createDate
        
        switch type {
        case .PERSONAL:
            self.defaults.set(date, for: MyKey.DefaultsKey.personalLastDate)
        
        case .ORDER:
            self.defaults.set(date, for: MyKey.DefaultsKey.orderLastDate)
        
        case .ACTIVITY:
            self.defaults.set(date, for: MyKey.DefaultsKey.activityLastDate)
        }
    }
    
    private func getLastDate(_ type: PushType) -> String {
        switch type {
        case .PERSONAL:
            //個人訊息從"初始時間"開始
            var date = "2024-04-06T15:46:55+0800"
            if let lastDate = self.defaults.get(for: MyKey.DefaultsKey.personalLastDate) {
                date = lastDate
            }
            return date
            
        case .ORDER:
            //訂單通知從"初始時間"開始
            var date = "2024-04-06T15:46:55+0800"
            if let lastDate = self.defaults.get(for: MyKey.DefaultsKey.orderLastDate) {
                date = lastDate
            }
            return date
            
        case .ACTIVITY:
            //活動通知從"現在時間"開始
            var date = Date().convertString(format: .Server)
            if let lastDate = self.defaults.get(for: MyKey.DefaultsKey.activityLastDate) {
                date = lastDate
            }
            return date
        }
    }
    
    private func saveNotice(_ notice: [PushNotice], _ type: PushType) {
        let realm = try! Realm()
        realm.beginWrite()
        
        for pn in notice {
            //Update
            if let ob = realm.objects(PushNoticeOb.self).filter("id = '\(pn.pushId)'").first {
                ob.createDate = pn.createDate
                ob.pushType = pn.pushType
                ob.pushTitle = pn.pushTitle
                ob.pushContent = pn.pushContent
                ob.pushUserId = pn.pushUserId ?? 0
                ob.imgUrl = pn.imgUrl ?? ""
                ob.action = pn.action ?? ""
                ob.dataId = pn.dataId ?? 0
                ob.isRead = pn.isRead
                realm.add(ob, update: .modified)
            
            //Add
            }else {
                let ob = PushNoticeOb()
                ob.id = "\(pn.pushId)"
                ob.createDate = pn.createDate
                ob.pushType = pn.pushType
                ob.pushTitle = pn.pushTitle
                ob.pushContent = pn.pushContent
                ob.pushUserId = pn.pushUserId ?? 0
                ob.imgUrl = pn.imgUrl ?? ""
                ob.action = pn.action ?? ""
                ob.dataId = pn.dataId ?? 0
                ob.isRead = pn.isRead
                realm.add(ob)
            }
        }
        try! realm.commitWrite()
        
        self.setLastDate(notice, type)
        NotificationCenter.default.post(name: .updateNoticeBadgeCompleted,
                                        object: nil,
                                        userInfo: [MyKey.UserInfo.pushType: type])
    }
    
    func updateNoticeIsRead(_ ob: PushNoticeOb, _ isRead: Bool) {
        guard let type = PushType(rawValue: ob.pushType) else { return }
        let oldIsRead = ob.isRead
        
        let realm = try! Realm()
        try! realm.write {
            ob.isRead = isRead
        }
        
        //未讀 -> 已讀: update server
        //公告訊息不需要
        if oldIsRead == false,
           isRead == true,
           type != .ACTIVITY {
            self.updatePushNotice(ob)
        }
        
        NotificationCenter.default.post(name: .updateNoticeBadgeCompleted,
                                        object: nil,
                                        userInfo: [MyKey.UserInfo.pushType: type])
    }
    
    func deleteNotice(_ ob: PushNoticeOb) {
        guard let type = PushType(rawValue: ob.pushType) else { return }
        
        let realm = try! Realm()
        try! realm.write {
            realm.delete(ob)
        }
        
        NotificationCenter.default.post(name: .updateNoticeBadgeCompleted,
                                        object: nil,
                                        userInfo: [MyKey.UserInfo.pushType: type])
    }
    
    func clearNotices() {
        let realm = try! Realm()
        let notices = realm.objects(PushNoticeOb.self)
        do {
            try realm.write {
                realm.delete(notices)
            }
            self.defaults.clear(MyKey.DefaultsKey.personalLastDate)
            self.defaults.clear(MyKey.DefaultsKey.orderLastDate)
            NotificationCenter.default.post(name: .updateNoticeBadgeCompleted,
                                            object: nil,
                                            userInfo: nil)
        }catch {
            print("clearNotices Fail: \(error.localizedDescription)")
        }
    }
    
    //MARK: Server
    /// Get recent push notice
    /// Parameters
    /// - `pushType`: PERSONAL = 1, ORDER = 2, ACTIVITY = 3
    func getPushNotice(pushType: PushType) {
#if DEV
        if let path = Bundle.main.path(forResource: "push_notice", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[PushNotice]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                let notice = results.filter({ $0.pushType == pushType.rawValue })
                self.saveNotice(notice, pushType)
                
            }catch {
                print("push_notice JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let lastDate = self.getLastDate(pushType)
       
        let path = APIManager().getBaseURL() + "/pnc/pushNotice"
        let params: Parameters = [PushNotice.InfoKey.pushType: pushType.rawValue,
                                  "lastDate": lastDate]
        AF.request(path, method: .get, parameters: params, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[PushNotice]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        print("error: \(store.message)")
                        return
                    }
                    self.saveNotice(results, pushType)

                }catch {
                    print("getPushNotice JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getPushNotice Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Update push notices
    /// Parameters
    /// - `ob`: push notice realm Ob
    private func updatePushNotice(_ ob: PushNoticeOb) {
#if DEV
        print("updatePushNotice")
#else
        let path = APIManager().getBaseURL() + "/pnc/pushNotice"
        let params: Parameters = [PushNotice.InfoKey.pushId: Int(ob.id),
                                  PushNotice.InfoKey.isRead: ob.isRead]
        
        AF.request(path, method: .put, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        print("error: \(store.message)")
                        return
                    }

                }catch {
                    print("updatePushNotice JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("updatePushNotice Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}

extension PushNoticeService {
    func checkPushActionToMove(push: PushNotice) {
        guard let type = PushAction(rawValue: push.action ?? ""),
              let dataId = push.dataId else { return }
        switch type {
        case .PRODUCT:
            guard let topVC = UIApplication.topViewController() else { return }
            if !topVC.checkLogin() {
                topVC.showLoginView { success in
                    self.getProduct(productId: dataId)
                }
                
            }else {
                getProduct(productId: dataId)
            }
            
        case .ORDER:
            guard let topVC = UIApplication.topViewController() else { return }
            if !topVC.checkLogin() {
                topVC.showLoginView { success in
                    self.getOrder(orderId: dataId)
                }
                
            }else {
                getOrder(orderId: dataId)
            }
            
        case .COMMENT:
            print("Move to comment...")
        }
    }
    
    func getProduct(productId: Int) {
        guard let topVC = UIApplication.topViewController() else { return }
        topVC.showActivityIndicator()
        ProductService.shared.getProduct(productId: productId) { data in
            topVC.hideActivityIndicator()
            if let product = data {
                topVC.showProductDetailView(type: .Watch, product: product, productUser: product.user)
                
            }else {
                topVC.showAlert(title: nil, message: "Unable".localized())
            }
        }
    }
    
    func getOrder(orderId: Int) {
        guard let topVC = UIApplication.topViewController() else { return }
        topVC.showActivityIndicator()
        OrderService.shared.getOrder(orderId: orderId) { data in
            topVC.hideActivityIndicator()
            if let order = data {
                topVC.showOrderDetailView(type: .Update, order: order)
                
            }else {
                topVC.showAlert(title: nil, message: "Unable".localized())
            }
        }
    }
}
