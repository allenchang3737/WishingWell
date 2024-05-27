//
//  MessageService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class MessageService {
    static let shared: MessageService = MessageService()
    
    private init() {
        print("MessageService init..")
    }
    
    /// Get messages
    /// Parameters
    /// - `conversationId`: select from message conversationId
    func getMessages(conversationId: Int, completionHandler: @escaping ([Message]) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "messages", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Message]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("messages JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/mc/messages/\(conversationId)"
        
        AF.request(path, method: .get, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Message]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        print("error: \(store.message)")
                        return
                    }
                    completionHandler(results)
                    
                }catch {
                    print("getMessages JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("getMessages Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /*
    /// Delete message
    /// Parameters
    /// - `messageId`:  message PK
    func deleteMessage(messageId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        //TODO: API
#endif
    }
    */
}
