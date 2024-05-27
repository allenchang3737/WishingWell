//
//  ProductService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class ProductService {
    static let shared: ProductService = ProductService()
    
    private init() {
        print("ProductService init..")
    }
    
    /// Create product
    /// Parameters
    /// - `product`:  product object
    func createProduct(product: Product, completionHandler: @escaping (_ productId: Int) -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler(1)
        }
#else
        let path = APIManager().getBaseURL() + "/pc/product"
        let params: Parameters = [Product.InfoKey.userId: product.userId,
                                  Product.InfoKey.title: product.title,
                                  Product.InfoKey.intro: product.intro,
                                  Product.InfoKey.countryCode: product.countryCode,
                                  Product.InfoKey.latitude: product.latitude,
                                  Product.InfoKey.longitude: product.longitude,
                                  Product.InfoKey.startDate: product.startDate,
                                  Product.InfoKey.endDate: product.endDate,
                                  Product.InfoKey.webUrl: product.webUrl,
                                  Product.InfoKey.price: product.price,
                                  Product.InfoKey.productType: product.productType]
        
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<ProductIdRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result.productId)

                }catch {
                    print("createProduct JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("createProduct Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Update product
    /// Parameters
    /// - `product`:  product object
    func updateProduct(product: Product, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/pc/product"
        let params: Parameters = [Product.InfoKey.productId: product.productId,
                                  Product.InfoKey.title: product.title,
                                  Product.InfoKey.intro: product.intro,
                                  Product.InfoKey.countryCode: product.countryCode,
                                  Product.InfoKey.latitude: product.latitude,
                                  Product.InfoKey.longitude: product.longitude,
                                  Product.InfoKey.startDate: product.startDate,
                                  Product.InfoKey.endDate: product.endDate,
                                  Product.InfoKey.webUrl: product.webUrl,
                                  Product.InfoKey.price: product.price]
        
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
                    print("updateProduct JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("updateProduct Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Suspend product
    /// Parameters
    /// - `productId`:  product PK
    func suspendProduct(productId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/pc/suspend/product/\(productId)"
        
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
                    print("suspendProduct JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("suspendProduct Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Delete product: 刪除 DB 檢查是否有對應Order
    /// Parameters
    /// - `productId`:  product PK
    func deleteProduct(productId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/pc/product"
        let params: Parameters = [Product.InfoKey.productId: productId]
        
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
                    print("deleteProduct JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("deleteProduct Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get product: 回傳更詳細的資料
    /// Parameters
    /// - `productId`:  product PK
    /// 要回User
    func getProduct(productId: Int, completionHandler: @escaping (Product?) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "product", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<Product>.self, from: data)
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
                print("product JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/pc/product/\(productId)"
        
        AF.request(path, method: .get).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<Product>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(result)

                }catch {
                    print("getProduct JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getProduct Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get products
    /// Parameters
    /// - `userId`: product user id
    func getProducts(userId: Int, completionHandler: @escaping ([Product]) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "user_products", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("user_products JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/pc/products"
        let params: Parameters = [Product.InfoKey.userId: userId]
        
        AF.request(path, method: .get, parameters: params).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)

                }catch {
                    print("getProducts JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getProducts Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Search products
    /// Parameters
    /// - `search`:  search object
    func searchProducts(search: Search, completionHandler: @escaping ([Product]) -> ()) {
        print("--------------------------------------------------")
        print("Search Data: \(search)")
        print("--------------------------------------------------")
#if DEV
        if let path = Bundle.main.path(forResource: "search_products", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                var filter = results.filter({ $0.productType == search.type })
                filter.append(contentsOf: filter)
                filter.append(contentsOf: filter)
                DispatchQueue.main.async {
                    completionHandler(filter)
                }
                
            }catch {
                print("search_products JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/pc/search/products"
        let params: Parameters = [Search.InfoKey.text: search.text,
                                  Search.InfoKey.type: search.type,
                                  Search.InfoKey.countryCode: search.countryCode,
                                  Search.InfoKey.minLatitude: search.minLatitude,
                                  Search.InfoKey.maxLatitude: search.maxLatitude,
                                  Search.InfoKey.minLongitude: search.minLongitude,
                                  Search.InfoKey.maxLongitude: search.maxLongitude,
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
                    let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)
                    
                }catch {
                    print("searchProducts JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("searchProducts Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /*
    /// Search map products
    /// Parameters
    /// - `search`:  search object
    /// - `minLatitude`: 最小經度
    /// - `maxLatitude`: 最大經度
    /// - `minLongitude`: 最小緯度
    /// - `maxLongitude`: 最大緯度
    func searchMapProducts(search: Search, completionHandler: @escaping ([Product]) -> ()) {
        print("--------------------------------------------------")
        print("Search Data: \(search)")
        print("--------------------------------------------------")
#if DEV
        if let path = Bundle.main.path(forResource: "search_products", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("search_products JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/pc/search/products/map"
        let params: Parameters = [Search.InfoKey.type: search.type,
                                  Search.InfoKey.minLatitude: search.minLatitude,
                                  Search.InfoKey.maxLatitude: search.maxLatitude,
                                  Search.InfoKey.minLongitude: search.minLongitude,
                                  Search.InfoKey.maxLongitude: search.maxLongitude]
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Product]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)
                    
                }catch {
                    print("searchMapProducts JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("searchMapProducts Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    */
}
