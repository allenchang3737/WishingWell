//
//  OTPService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON

class OTPService {
    static let shared: OTPService = OTPService()
    
    private init() {
        print("OTPService init..")
    }
    
    func generateOTP(rq: GenerateOTPRq, completionHandler: @escaping (GenerateOTPRs) -> ()) {
#if DEV
        if let path = Bundle.main.path(forResource: "generate_otp_rs", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()
                let store = try decoder.decode(BaseResultRs<GenerateOTPRs>.self, from: data)
                guard store.status == BaseStatus.SUCCESS.rawValue,
                      let result = store.result else {
                    print("error: \(store.message)")
                    return
                }
                DispatchQueue.main.async {
                    completionHandler(result)
                }
                
            }catch {
                print("generate_otp_rs JSON Decoded Error: \(error.localizedDescription)")
            }
        }
#else
        let path = APIManager().getBaseURL() + "/otp/generate"
        let params: Parameters = [GenerateOTPRq.InfoKey.userInfo: rq.userInfo,
                                  GenerateOTPRq.InfoKey.otpType: rq.otpType,
                                  GenerateOTPRq.InfoKey.userId: rq.userId]
        
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<GenerateOTPRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result)

                }catch {
                    print("generateOTP JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("generateOTP Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }

    func resendOTP(token: String, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/otp/resend"
        let headers: HTTPHeaders = [.authorization(bearerToken: token)]
        
        AF.request(path, method: .get, headers: headers).response { response in
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
                    print("resendOTP JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("resendOTP Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    func verifyOTP(otpCode: String, token: String, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/otp/verify"
        let params: Parameters = ["otpCode": otpCode]
        let headers: HTTPHeaders = [.authorization(bearerToken: token)]
        
        AF.request(path, method: .post, parameters: params, headers: headers).response { response in
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
                    print("verifyOTP JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("verifyOTP Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
