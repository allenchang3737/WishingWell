//
//  VersionModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/13.
//

import Foundation

struct CheckVersionRq: Codable {
    var osType: String = "IOS"
    var version: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    enum InfoKey {
        static let osType = "osType"
        static let version = "version"
    }
}

struct CheckVersionRs: Codable {
    let hasNewVersion: Bool
    let enforce: Bool?
    let downloadUrl: String?
}
