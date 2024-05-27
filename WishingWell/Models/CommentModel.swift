//
//  CommentModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

struct Comment: Codable {
    var commentId: Int = 0
    var createDate: String = ""
    var text: String?
    var star: Double = 0.0
    var senderUserId: Int = 0
    var receiverUserId: Int = 0
    
    //Response
    var senderUser: User?                     //Sender user
    
    enum InfoKey {
        static let commentId = "commentId"
        static let text = "text"
        static let star = "star"
        static let senderUserId = "senderUserId"
        static let receiverUserId = "receiverUserId"
    }
}

//MARK: Response
struct CommentIdRs: Codable {
    var commentId: Int
}
