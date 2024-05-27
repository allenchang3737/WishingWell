//
//  APIManager.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire

/// 測試 `port`: 8081
/// 營運 `port`: 80
public enum ServerType: String {
    //Staging
    case stag = "http://192.168.0.100:8081"
    
    //Production
    case prod = "http://3.210.5.174"
}

struct APIManager {
#if STAG
    let serverType: ServerType = .stag
#else
    let serverType: ServerType = .prod
#endif
    
    func getBaseURL() -> String {
        switch self.serverType {
        case .stag:
            return ServerType.stag.rawValue
            
        case .prod:
            return ServerType.prod.rawValue
        }
    }
    
    var headers: HTTPHeaders? {
        get {
            guard let token = AppManager.shared.accessToken else { return nil }
            let headers: HTTPHeaders = [.authorization(bearerToken: token)]
            return headers
        }
    }
    
    var googleClientID: String {
        get {
#if STAG
            return "1075155694574-rsi3hdprgjm2eeppn0l0dl41emic3c1n.apps.googleusercontent.com"
#else
            return "64033028375-uejdnoh1p452jpa0gkpbdgihgqgvkhfg.apps.googleusercontent.com"
#endif
        }
    }
}
