//
//  UserModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

enum UserType: Int {
    case WISHER = 0
    case BUYER = 1              //標準：免費
    case BUYER_PRIME = 2        //高級：月費
}

enum AuthType: String {
    case ACCOUNT = "ACCOUNT"
    case FACEBOOK = "FACEBOOK"
    case GOOGLE = "GOOGLE"
    case APPLE = "APPLE"
}

struct User: Codable {
    var userId: Int = 0
    var createDate: String = ""
    var account: String
    var password: String?
    var email: String
    var phone: String?
    var intro: String?
    var userType: Int = 0
    var emailVerified: Bool = false
    var phoneVerified: Bool = false
    var authType: String                    //註冊登入類型
    var authUserId: String?                 //第三方登入ID
    
    //Response
    var files: [File]?
    
    enum InfoKey {
        static let userId = "userId"
        static let account = "account"
        static let password = "password"
        static let email = "email"
        static let phone = "phone"
        static let intro = "intro"
        static let userType = "userType"
        static let authType = "authType"
        static let authUserId = "authUserId"
    }
}

//MARK: Response
struct LoginRs: Codable {
    var accessToken: String
    var refreshToken: String
}

struct UserIdRs: Codable {
    var userId: Int
}
