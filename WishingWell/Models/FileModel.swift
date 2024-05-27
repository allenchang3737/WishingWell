//
//  FileModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation

enum FileType: Int {
    case USER = 100
    case PRODUCT = 200
    case PUSHNOTICE = 300
    case MESSAGE = 400
    case COMMENT = 500
}

struct File: Codable {
    var fileId: Int = 0
    var createDate: String = ""
    var customId: Int                   //FK: Other Object ID
    var type: Int                       //檔案類型
    var fileName: String                //檔案名稱
    var contentType: String = ""        //jpg, word, pdf...
    var orderNo: Int?                   //排序
    
    init(customId: Int, type: FileType) {
        self.customId = customId
        self.type = type.rawValue
        self.fileName = UUID().uuidString
    }
    
    enum InfoKey {
        static let fileId = "fileId"
        static let customId = "customId"
        static let type = "type"
        static let fileName = "fileName"
        static let contentType = "contentType"
        static let orderNo = "orderNo"
    }
}

//MARK: Response
struct UploadImageRs: Codable {
    var imageUrl: String
}
