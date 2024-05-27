//
//  ConversationService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class ConversationService {
    static let shared: ConversationService = ConversationService()
    
    private init() {
        print("ConversationService init..")
    }
    
    /// Get conversations
    /// Parameters: `Header User Token`
    /// - `userId`:  對方 user
    func getConversation(userId: Int, completionHandler: @escaping (Conversation?) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "conversation", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<Conversation>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    completionHandler(nil)
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(result)
                }
                
            }catch {
                print("conversation JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/cvc/conversation/\(userId)"
        
        AF.request(path, method: .get, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<Conversation>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(result)
                    
                }catch {
                    print("getConversation JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("getConversation Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get conversations
    /// Parameters: `Header User Token`
    func getConversations(completionHandler: @escaping ([Conversation]) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "conversations", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Conversation]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("conversations JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/cvc/conversations"

        AF.request(path, method: .get, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Conversation]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(results)

                }catch {
                    print("getConversations JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getConversations Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    
    /// Delete UserConversation
    /// Parameters
    /// - `userId`: Header Token
    /// - `conversationId`
    func deleteUserConversation(conversationId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/cvc/userConversation"
        let params: Parameters = [Conversation.InfoKey.conversationId: conversationId]
        
        AF.request(path, method: .delete, parameters: params, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler()

                }catch {
                    print("deleteUserConversation JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("deleteUserConversation Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
