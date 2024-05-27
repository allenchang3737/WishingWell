//
//  CommentService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class CommentService {
    static let shared: CommentService = CommentService()
    
    private init() {
        print("CommentService init..")
    }
    
    /// Create comment
    /// Parameters
    /// - `comment`: comment object
    func createComment(comment: Comment, completionHandler: @escaping (_ commentId: Int) -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler(99)
        }
#else
        let path = APIManager().getBaseURL() + "/cc/comment"
        let params: Parameters = [Comment.InfoKey.text: comment.text,
                                  Comment.InfoKey.star: comment.star,
                                  Comment.InfoKey.senderUserId: comment.senderUserId,
                                  Comment.InfoKey.receiverUserId: comment.receiverUserId]
        
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<CommentIdRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result.commentId)

                }catch {
                    print("createComment JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("createComment Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Update comment
    /// Parameters
    /// - `comment`: comment object
    func updateComment(comment: Comment, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/cc/comment"
        let params: Parameters = [Comment.InfoKey.commentId: comment.commentId,
                                  Comment.InfoKey.text: comment.text,
                                  Comment.InfoKey.star: comment.star]
        
        AF.request(path, method: .put, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
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
                    print("updateComment JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("updateComment Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Delete comment
    /// Parameters
    /// - `commentId`: comment PK
    func deleteComment(commentId: Int, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/cc/comment"
        let params: Parameters = [Comment.InfoKey.commentId: commentId]
        
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
                    print("deleteComment JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("deleteComment Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Get comments
    /// Parameters
    /// - `userId`: comment receiver user id
    func getComments(userId: Int, completionHandler: @escaping ([Comment]) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "user_comments", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Comment]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("user_comments JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/cc/comments/\(userId)"
        
        AF.request(path, method: .get).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultsRs<[Comment]>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let results = store.results else {
                        print("error: \(store.message)")
                        return
                    }
                    completionHandler(results)

                }catch {
                    print("getComments JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("getComments Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /*
    /// Search comments
    /// Parameters
    /// - `search`:  search object
    func searchComments(search: Search, completionHandler: @escaping ([Comment]) -> ()) {
        print("--------------------------------------------------")
        print("Search Data: \(search)")
        print("--------------------------------------------------")
#if DEV
        if let path = Bundle.main.path(forResource: "search_comments", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultsRs<[Comment]>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let results = store.results else {
                    print("error: \(store.message)")
                    return
                }
                
                DispatchQueue.main.async {
                    completionHandler(results)
                }
                
            }catch {
                print("search_comments JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        //TODO: API
#endif
    }
    */
}
