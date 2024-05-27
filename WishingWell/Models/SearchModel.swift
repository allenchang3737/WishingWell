//
//  SearchModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

enum Direction: String {
    case ASC = "ASC"
    case DESC = "DESC"
}

struct Search {
    var text: String?               //搜尋 Text
    var id: Int?                    //搜尋 ID
    var type: Int?                  //Product Type
    var countryCode: String?        //國家代碼
    
    //Price params
    var priceMin: Double?
    var priceMax: Double?
    //Map params
    var minLatitude: Double?
    var maxLatitude: Double?
    var minLongitude: Double?
    var maxLongitude: Double?
    
    //Page params
    var page: Int = 0                                           //預設 0
    var size: Int = 30                                          //預設 30
    var direction: String = Direction.DESC.rawValue             //預設 DESC(大到小)
    var properties: [String] = ["createDate"]                   //預設 createDate排序
    
    enum InfoKey {
        static let text = "text"
        static let id = "id"
        static let type = "type"
        static let countryCode = "countryCode"
        
        static let priceMin = "priceMin"
        static let priceMax = "priceMax"
        
        static let minLatitude = "minLatitude"
        static let maxLatitude = "maxLatitude"
        static let minLongitude = "minLongitude"
        static let maxLongitude = "maxLongitude"
        
        static let page = "page"
        static let size = "size"
        static let direction = "direction"
        static let properties = "properties"
    }
}
