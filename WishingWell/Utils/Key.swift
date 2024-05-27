//
//  Key.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/15.
//

import Foundation
import DefaultsKit

struct MyKey {
    struct DefaultsKey {
        static let currentUserId = Key<Int>("currentUserId")
        static let accessToken = Key<String>("accessToken")
        static let refreshToken = Key<String>("refreshToken")
        static let tokenStart = Key<Date>("tokenStart")
        static let device = Key<Device>("device")
        static let personalLastDate = Key<String>("personalLastDate")
        static let orderLastDate = Key<String>("orderLastDate")
        static let activityLastDate = Key<String>("activityLastDate")
        static let numberOfRuns = Key<Int>("numberOfRuns")
        static let storeKitVersion = Key<String>("storeKitVersion")
    }
    
    struct UserInfo {
        static let pushType = "pushType"
        static let title = "title"
        static let message = "message"
        static let latestMessage = "latestMessage"
    }
}

extension Notification.Name {
    static let showAlertNotification = Notification.Name("showAlertNotification")
    static let keyboard = Notification.Name("keyboard")
    static let currentUserCompleted = Notification.Name("currentUserCompleted")
    static let updateProductCompleted = Notification.Name("updateProductCompleted")
    static let updateNoticeBadgeCompleted = Notification.Name("updateNoticeBadgeCompleted")
    static let updateOrderCompleted = Notification.Name("updateOrderCompleted")
    static let updateLatestMessage = Notification.Name("updateLatestMessage")
}
