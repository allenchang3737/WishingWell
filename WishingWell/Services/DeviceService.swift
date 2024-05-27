//
//  DeviceService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON
import DefaultsKit

class DeviceService {
    static let shared: DeviceService = DeviceService()
    
    private init() {
        print("DeviceService init..")
    }
    
    let defaults = Defaults()
    
    /// Create Device
    /// Parameters
    /// - `deviceUid`:  不存在新增，存在更新
    func createDevice() {
#if DEV
        let device = Device(userId: AppManager.shared.currentUserId,
                            pushToken: AppManager.shared.pushToken)
        self.defaults.set(device, for: MyKey.DefaultsKey.device)
#else
        var device = Device(userId: AppManager.shared.currentUserId,
                            pushToken: AppManager.shared.pushToken)
        
        let path = APIManager().getBaseURL() + "/sys/createDevice"
        let params: Parameters = [Device.InfoKey.userId: device.userId ?? "",
                                  Device.InfoKey.vendor: device.vendor,
                                  Device.InfoKey.osType: device.osType,
                                  Device.InfoKey.osVersion: device.osVersion,
                                  Device.InfoKey.model: device.model,
                                  Device.InfoKey.deviceUid: device.deviceUid ?? "",
                                  Device.InfoKey.pushToken: device.pushToken ?? "",
                                  Device.InfoKey.appVersion: device.appVersion ?? ""]
        
        AF.request(path, method: .post, parameters: params ,encoding: JSONEncoding.default).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<DeviceIdRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        print("error: \(store.message)")
                        return
                    }
                    
                    //Save Device
                    device.deviceId = result.deviceId
                    self.defaults.set(device, for: MyKey.DefaultsKey.device)
                    
                }catch {
                    print("createDevice JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("createDevice Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    func isChangedDevice() -> Bool {
        guard let oldDevice = defaults.get(for: MyKey.DefaultsKey.device) else { return true }
        
        let newDevice = Device(userId: AppManager.shared.currentUserId,
                               pushToken: AppManager.shared.pushToken)
        print("--------------------------------------------------")
        print("oldDevice: \(oldDevice)")
        print("newDevice: \(newDevice)")
        print("--------------------------------------------------")
        if newDevice == oldDevice {
            print("--------------------------------------------------")
            print("isChangedDevice: \(false)")
            print("--------------------------------------------------")
            return false
        
        }else {
            print("--------------------------------------------------")
            print("isChangedDevice: \(true)")
            print("--------------------------------------------------")
            return true
        }
    }
}
