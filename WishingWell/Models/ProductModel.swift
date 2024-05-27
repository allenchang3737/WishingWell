//
//  ProductModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

enum ProductType: Int {
    case WISH = 1               //許願
    case BUY = 2                //代購
}

enum ProductStatus: Int {
    //日期區間
    case NOTDEPLOYED = 0        //未發佈
    case DEPLOYED = 1           //開放中
    case EXPIRED = 2            //已截止
    
    //接單後
    case PROCESSING = 90        //進行中
    case SUSPENDED = 98         //暫停
    case TERMINATED = 99        //已結束
}

struct Product: Codable {
    var productId: Int = 0
    var createDate: String = ""
    var userId: Int = 0
    var title: String = ""
    var intro: String = ""
    var countryCode: String?
    var latitude: Double?
    var longitude: Double?
    var startDate: String?
    var endDate: String?
    var webUrl: String?
    var price: Double?
    var status: Int = 0
    var productType: Int = 0
    
    //Response
    var files: [File]?
    var user: User?
    
    enum InfoKey {
        static let productId = "productId"
        static let userId = "userId"
        static let title = "title"
        static let intro = "intro"
        static let countryCode = "countryCode"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let startDate = "startDate"
        static let endDate = "endDate"
        static let webUrl = "webUrl"
        static let price = "price"
        static let productType = "productType"
    }
}

//MARK: Response
struct ProductIdRs: Codable {
    var productId: Int
}
