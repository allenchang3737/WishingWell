//
//  ReportService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/20.
//

import Foundation
import Alamofire
import SwiftyJSON

class ReportService {
    static let shared: ReportService = ReportService()
    
    private init() {
        print("ReportService init..")
    }
    
    /// Create report
    /// Parameters
    /// - `report`: report object
    func createReport(report: Report, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/cc/report"
        let params: Parameters = [Report.InfoKey.type: report.type,
                                  Report.InfoKey.text: report.text,
                                  Report.InfoKey.senderUserId: report.senderUserId,
                                  Report.InfoKey.receiverUserId: report.receiverUserId]
        
        AF.request(path, method: .post, parameters: params, encoding: JSONEncoding.default, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        print("error: \(store.message)")
                        return
                    }
                    completionHandler()

                }catch {
                    print("createReport JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("createReport Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
