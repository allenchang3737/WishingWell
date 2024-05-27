//
//  OrderService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class OrderService {
    static let shared: OrderService = OrderService()
    
    private init() {
        print("OrderService init..")
    }
    
    /// Create order
    /// Parameters
    /// - `order`: order object
    /// header user Id
    func createOrder(order: Order, completionHandler: @escaping (_ orderId: Int) -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler(99)
        }
#else
        let path = APIManager().getBaseURL() + "/oc/order"
        let params: Parameters = [Order.InfoKey.productId: order.productId,
                                  Order.InfoKey.orderUserId: order.orderUserId,
                                  Order.InfoKey.orderNote: order.orderNote,
                                  Order.InfoKey.amount: order.amount,
                                  Order.InfoKey.dealDate: order.dealDate,
                                  Order.InfoKey.dealType: order.dealType,
                                  Order.InfoKey.userId: order.userId,
                                  Order.InfoKey.userName: order.userName,
                                  Order.InfoKey.userPhone: order.userPhone,
                                  Order.InfoKey.userEmail: order.userEmail]
                                
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<OrderIdRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result.orderId)

                }catch {
                    print("createOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("createOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Update order
    /// Parameters
    /// - `order`:  order object
    /// 更新資料無法修改訂單狀態,訂購人ID
    func updateOrder(order: Order, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/oc/order"
        let params: Parameters = [Order.InfoKey.orderId: order.orderId,
                                  Order.InfoKey.orderNote: order.orderNote,
                                  Order.InfoKey.amount: order.amount,
                                  Order.InfoKey.dealDate: order.dealDate,
                                  Order.InfoKey.dealType: order.dealType,
                                  Order.InfoKey.userName: order.userName,
                                  Order.InfoKey.userPhone: order.userPhone,
                                  Order.InfoKey.userEmail: order.userEmail]
                                
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
                    completionHandler()

                }catch {
                    print("updateOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("updateOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Accept order
    /// Parameters
    /// - `order`:  order object
    /// 更新訂單狀態,訂購人ID,訂購人資料
    func acceptOrder(order: Order, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/oc/accept/\(order.orderId)"
        let params: Parameters = [Order.InfoKey.userId: order.userId,
                                  Order.InfoKey.userName: order.userName,
                                  Order.InfoKey.userPhone: order.userPhone,
                                  Order.InfoKey.userEmail: order.userEmail]
                                
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
                    completionHandler()

                }catch {
                    print("acceptOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("acceptOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Cancel order: 取消訂單流程
    /// Parameters
    /// - `orderId`:  order PK
    func cancelOrder(orderId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/oc/cancel/\(orderId)"
        
        AF.request(path, method: .put, headers: APIManager().headers).response { response in
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
                    print("cancelOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("cancelOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Delete order: 刪除 DB 檢查是否有對應的Message
    /// Parameters
    /// - `orderId`:  order PK
    func deleteOrder(orderId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/oc/order"
        let params: Parameters = [Order.InfoKey.orderId: orderId]
        
        AF.request(path, method: .delete, parameters: params, headers: APIManager().headers).response { response in
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
                    print("deleteOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("deleteOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Finish order: 推播用戶提醒評論
    /// Parameters
    /// - `orderId`:  order PK
    func finishOrder(orderId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/oc/finish/\(orderId)"
        
        AF.request(path, method: .put, headers: APIManager().headers).response { response in
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
                    print("cancelOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("cancelOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get order
    /// Parameters: `Header User Token`
    func getOrders(completionHandler: @escaping ([Order]) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "orders", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Order]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("orders JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/oc/orders"

        AF.request(path, method: .get, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Order]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)

                }catch {
                    print("getOrders JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getOrders Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get order: 回傳更詳細的資料
    /// Parameters
    /// - `orderId`:  order PK
    func getOrder(orderId: Int, completionHandler: @escaping (Order?) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "order", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<Order>.self, from: data)
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
                print("order JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/oc/order"
        let params: Parameters = [Order.InfoKey.orderId: orderId]
        
        AF.request(path, method: .get, parameters: params, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<Order>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(result)

                }catch {
                    print("getOrder JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getOrder Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
