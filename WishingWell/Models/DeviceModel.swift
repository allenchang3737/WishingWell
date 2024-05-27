//
//  DeviceModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import UIKit

struct Device: Codable, Equatable {
    var deviceId: Int = 0
    var createDate: String = ""
    var userId: Int?                                                                //FK: User ID
    var vendor: String = "Apple"                                                    //手機廠牌
    var osType: String = "IOS"                                                      //IOS, ANDROID
    var osVersion: String = UIDevice.current.systemVersion                          //手機系統版本
    var model: String = UIDevice.modelName                                          //手機型號
    var deviceUid: String? = UIDevice.current.identifierForVendor?.uuidString
    var pushToken: String?                                                          //推播 token
    var appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    enum InfoKey {
        static let userId = "userId"
        static let vendor = "vendor"
        static let osType = "osType"
        static let osVersion = "osVersion"
        static let model = "model"
        static let deviceUid = "deviceUid"
        static let pushToken = "pushToken"
        static let appVersion = "appVersion"
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.vendor == rhs.vendor &&
               lhs.osType == rhs.osType &&
               lhs.osVersion == rhs.osVersion &&
               lhs.model == rhs.model &&
               lhs.deviceUid == rhs.deviceUid &&
               lhs.pushToken == rhs.pushToken &&
               lhs.userId == rhs.userId &&
               lhs.appVersion == rhs.appVersion
    }
}

//MARK: Response
struct DeviceIdRs: Codable {
    var deviceId: Int
}
