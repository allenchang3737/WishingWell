//
//  AppConfigModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/13.
//

import Foundation

struct AppConfig: Codable {
    var appConfigId: Int
    var subscribedFee: Double
    var tncUrl: String
    var aboutUrl: String
    var questionUrl: String
    var serviceEmail: String
    var servicePhone: String
}
