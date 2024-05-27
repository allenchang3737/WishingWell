//
//  OrderModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

enum DealType: Int {
    case FACETOFACE = 1                 //面交
    case PLATFORM_7ELEVEN = 2           //7-11 賣貨便
    case PLATFORM_FAMILYMART = 3        //全家 好賣+
    case PLATFORM_HILIFE = 4            //萊爾富 萊賣貨
}

enum OrderStatus: Int {
    //訂單確認
    case DISCUSSING = 0                 //訂單討論
    
    //代購
    case PROCESSING = 90                //進行中
    case CANCELED = 98                  //已取消
    case COMPLETED = 99                 //已完成
}

struct Order: Codable {
    var orderId: Int = 0
    var createDate: String = ""
    var productId: Int = 0              //productId -> Product -> userId -> 賣家的訂單
    var orderUserId: Int = 0            //建立訂單的user
    var orderNote: String = ""
    var amount: Double = 0.0
    var dealDate: String = ""
    var dealType: Int?
    var userId: Int?                    //訂購訂單的user
    var userName: String?
    var userPhone: String?
    var userEmail: String?
    var status: Int = 0
    
    //Response
    var product: Product?
    var orderUser: User?
    var user: User?
    
    enum InfoKey {
        static let orderId = "orderId"
        static let productId = "productId"
        static let orderUserId = "orderUserId"
        static let orderNote = "orderNote"
        static let amount = "amount"
        static let dealDate = "dealDate"
        static let dealType = "dealType"
        static let userId = "userId"
        static let userName = "userName"
        static let userPhone = "userPhone"
        static let userEmail = "userEmail"
        static let status = "status"
    }
    
    func getOrderContent() -> String {
        var result = ""
        //orderNote
        result += "Order note".localized() + ":\n"
        result += self.orderNote + "\n"
        
        //amount
        result += "Order amount".localized() + ": "
        result += "$ \(self.amount.priceFormatting())" + "\n"
        
        //dealDate
        result += "Order deal date".localized() + ": "
        result += (self.dealDate.convertString(origin: .Server, result: .yyyyMMdd) ?? "") + "\n"
        
        //dealType
        if let type = self.dealType {
            result += "Order deal type".localized() + ": "
            result += (type.convertDealType() ?? "") + "\n"
        }
        
        //換行
        result += "\n"
        
        //userName
        if let name = self.userName {
            result += "Order user name".localized() + ":\n"
            result += name + "\n"
        }
        
        //userPhone
        if let phone = self.userPhone {
            result += "Order user phone".localized() + ":\n"
            result += phone + "\n"
        }
        
        //userEmail
        if let email = self.userEmail {
            result += "Order user email".localized() + ":\n"
            result += email
        }
        
        return result
    }
}

//MARK: Response
struct OrderIdRs: Codable {
    var orderId: Int
}
