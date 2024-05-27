//
//  ChatModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/4/10.
//

import Foundation
import SwiftyJSON

enum ChatType: String {
    case CONVERSATION = "CONVERSATION"          //聊天清單頁
    case MESSAGE = "MESSAGE"                    //聊天頁
}

struct Chat: Codable {
    var conversation: Conversation?
    var message: Message?
    
    init(conversation: Conversation?, message: Message?) {
        self.conversation = conversation
        self.conversation?.latestMessage = nil  //清除：上傳不必要的參數
        
        self.message = message
    }
    
    init(decoding content: String) throws {
        let data = Data(content.utf8)
        let json = try JSON(data).rawData()
        let decoder = JSONDecoder()
        self = try decoder.decode(Chat.self, from: json)
    }
    
    func toString() -> String? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("------------------------------------------------------------")
            print("Chat jsonString: \(jsonString ?? "")")
            print("------------------------------------------------------------")
            return jsonString
            
        }catch {
            print("toString Error: \(error.localizedDescription)")
            return nil
        }
    }
}
