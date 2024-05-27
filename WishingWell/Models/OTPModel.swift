//
//  OTPModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

public enum OTPType: String {
    case USER = "USER"      //驗證用戶帳號
    case PHONE = "PHONE"    //驗證手機門號
    case EMAIL = "EMAIL"    //驗證電子郵件
}

struct GenerateOTPRq: Codable {
    var userInfo: String                            //用戶名稱、電子郵件、手機門號
    var otpType: String
    var userId: Int?
    
    enum InfoKey {
        static let userInfo = "userInfo"
        static let otpType = "otpType"
        static let userId = "userId"
    }
}

struct GenerateOTPRs: Codable {
    var token: String
    var expiryTime: Int?                             //OTP有效時間(秒)
}
