//
//  BaseModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/13.
//

import Foundation

enum BaseStatus: String {
    case SUCCESS = "SUCCESS"
    case ERROR = "ERROR"
    case ERROR0001 = "ERROR0001"        //第三方登入不存在需註冊
}

struct BaseRs: Codable {
    var status: String
    var message: String
}

struct BaseResultRs<T : Codable>: Codable {
    var status: String
    var message: String
    var result: T?
}

struct BaseResultsRs<T : Codable> : Codable {
    var status: String
    var message: String
    var results: T?
}
