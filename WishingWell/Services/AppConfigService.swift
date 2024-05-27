//
//  AppConfigService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class AppConfigService {
    static let shared: AppConfigService = AppConfigService()
    
    private init() {
        print("AppConfigService init..")
    }
    
    var config: AppConfig?
    
    func getAppConfig() {
#if DEV
        if let path = Bundle.main.path(forResource: "app_config", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<AppConfig>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    return
                }
                self.config = result
                
            }catch {
                print("app_config JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/sys/appConfig"
        
        AF.request(path, method: .get).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                print("--------------------------------------------------")
                print("getAppConfig: \(String(data: data, encoding: .utf8))")
                print("--------------------------------------------------")
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<AppConfig>.self, from: json)
                    
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        return
                    }
                    self.config = result
                    
                }catch {
                    print("getAppConfig JSON Decoded Error: \(error.localizedDescription)")
                }
                    
            case let .failure(error):
                print("getAppConfig Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
