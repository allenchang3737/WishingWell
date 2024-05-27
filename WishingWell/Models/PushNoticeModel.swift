//
//  PushNoticeModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import RealmSwift
import SwiftyJSON

public enum PushType: Int {
    case PERSONAL = 1
    case ORDER = 2
    case ACTIVITY = 3
}

public enum PushAction: String {
    case PRODUCT = "PRODUCT"
    case ORDER = "ORDER"
    case COMMENT = "COMMENT"
}

struct PushNotice: Codable {
    var pushId: Int
    var createDate: String
    var pushType: Int
    var pushTitle: String
    var pushContent: String
    var pushUserId: Int?
    var imgUrl: String?
    var action: String?
    var dataId: Int?
    var isRead: Bool = false
    
    init(decoding content: String) throws {
        let data = Data(content.utf8)
        let json = try JSON(data).rawData()
        let decoder = JSONDecoder()
        self = try decoder.decode(PushNotice.self, from: json)
    }
    
    enum InfoKey {
        static let pushId = "pushId"
        static let pushType = "pushType"
        static let isRead = "isRead"
    }
}

class PushNoticeOb: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var createDate: String = ""
    @objc dynamic var pushType: Int = 0
    @objc dynamic var pushTitle: String = ""
    @objc dynamic var pushContent: String = ""
    @objc dynamic var pushUserId: Int = 0
    @objc dynamic var imgUrl: String = ""
    @objc dynamic var action: String = ""
    @objc dynamic var dataId: Int = 0
    @objc dynamic var isRead: Bool = false
    
    // Define primary key
    override static func primaryKey() -> String? {
        return "id"
    }
}

//推播 payload
/*
{
    "aps": {
        "content-available": 1,
        "alert": {
            "title": "Hi, this is test.",
            "subtitle": "Test",
            "body": "Test 123 Test 123 Test 123"
        },
        "sound": "default"
    },
    "pushNotice": {
        "pushId": 1,
        "createDate": "2024-04-04 15:03:28",
        "pushType": 1,
        "pushTitle": "testD 許願了！快來幫助他完成願望。",
        "pushContent": "泰國必買名產：泰式手標紅茶",
        "pushUserId": 1,
        "action": "PRODUCT",
        "dataId": 1,
        "imgUrl": "https://upload.wikimedia.org/wikipedia/commons/1/1b/Apple_logo_grey.svg",
        "isRead": false
    }
}
{
    "aps": {
        "content-available": 1,
        "alert": {
            "title": "Hi, this is test.",
            "subtitle": "Test",
            "body": "Test 123 Test 123 Test 123"
        },
        "sound": "default"
    },
    "pushNotice": "{\"pushId\":1,\"createDate\":\"2024-04-0415:03:28\",\"pushType\":1,\"pushTitle\":\"testD許願了！快來幫助他完成願望。\",\"pushContent\":\"泰國必買名產：泰式手標紅茶\",\"pushUserId\":1,\"action\":\"PRODUCT\",\"dataId\”:1,\”imgUrl\":\"https://upload.wikimedia.org/wikipedia/commons/1/1b/Apple_logo_grey.svg\",\"isRead\":false}"
}
*/
