//
//  VersionService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class VersionService {
    static let shared: VersionService = VersionService()
    
    private init() {
        print("VersionService init..")
    }
    
    func checkVersion(completionHandler: @escaping (CheckVersionRs) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "check_version_rs", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<CheckVersionRs>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(result)
                }
                
            }catch {
                print("checkAppVersion JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let rq = CheckVersionRq()
        let path = APIManager().getBaseURL() + "/sys/checkVersion"
        let params: Parameters = [CheckVersionRq.InfoKey.osType: rq.osType,
                                  CheckVersionRq.InfoKey.version: rq.version ?? ""]
        
        AF.request(path, method: .get, parameters: params).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<CheckVersionRs>.self, from: json)

                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        return
                    }
                    completionHandler(result)

                }catch {
                    print("checkVersion JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("checkVersion Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
