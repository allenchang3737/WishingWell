//
//  ReportModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/20.
//

import Foundation

enum ReportType: Int {
    case HateSpeech = 1                                 //仇恨言論
    case ViolenceOrThreats = 2                          //暴力或威脅
    case ExplicitContent = 3                            //色情內容
    case FalseInformation = 4                           //虛假資訊
    case CopyrightInfringement = 5                      //版權侵犯
    case PrivacyViolation = 6                           //隱私侵犯
    case InvolvingScam = 7                              //涉及詐騙
    case OtherIllegalOrInappropriateContent = 8         //其他違法或不當內容
}

struct Report: Codable {
    var reportId: Int = 0
    var createDate: String = ""
    var type: Int?
    var text: String?
    var senderUserId: Int?
    var receiverUserId: Int?
    
    enum InfoKey {
        static let type = "type"
        static let text = "text"
        static let senderUserId = "senderUserId"
        static let receiverUserId = "receiverUserId"
    }
}
