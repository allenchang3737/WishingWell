//
//  ConversationModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

struct Conversation: Codable {
    var conversationId: Int = 0
    var createDate: String = ""
    var name: String?
    
    //Response
    var users: [User]?
    var latestMessage: Message?
    
    enum InfoKey {
        static let conversationId = "conversationId"
    }
}

//關聯表
struct UserConversation: Codable {
    var conversationId: Int = 0
    var userId: Int = 0
    var createDate: String = ""
}
