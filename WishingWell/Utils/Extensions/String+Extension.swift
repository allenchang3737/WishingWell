//
//  String+Extension.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import Foundation
import UIKit

extension String {
    func evaluate(with condition: String) -> Bool {
        guard let range = range(of: condition, options: .regularExpression, range: nil, locale: nil) else {
            return false
        }
        return range.lowerBound == startIndex && range.upperBound == endIndex
    }
    
    func convertString(origin: DateFormatType, result: DateFormatType) -> String? {
        let formatter = DateFormatter()
//        if origin == .Server {
//            formatter.locale = Locale(identifier: "zh_Hant_TW")             //設定地區(台灣)
//            formatter.timeZone = TimeZone(identifier: "Asia/Taipei")        //設定時區(台灣)
//        }
//        formatter.calendar = Calendar(identifier: .gregorian)             //設定24小時制
        formatter.dateFormat = origin.rawValue
        guard let date = formatter.date(from: self) else { return nil }
        
        let formatter2 = DateFormatter()
//        if result == .Server {
//            formatter2.locale = Locale(identifier: "zh_Hant_TW")            //設定地區(台灣)
//            formatter2.timeZone = TimeZone(identifier: "Asia/Taipei")       //設定時區(台灣)
//        }
//        formatter2.calendar = Calendar(identifier: .gregorian)            //設定24小時制
        formatter2.dateFormat = result.rawValue
        return formatter2.string(from: date)
    }
    
    func convertDate(format: DateFormatType) -> Date? {
        let formatter = DateFormatter()
//        if format == .Server {
//            formatter.locale = Locale(identifier: "zh_Hant_TW")             //設定地區(台灣)
//            formatter.timeZone = TimeZone(identifier: "Asia/Taipei")        //設定時區(台灣)
//        }
//        formatter.calendar = Calendar(identifier: .gregorian)           //設定24小時制
        formatter.dateFormat = format.rawValue
        return formatter.date(from: self)
    }
    
    func containsIgnoringCase(find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    func extractURLs() -> [String] {
        do {
            // Regular expression to match URLs
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            
            // Find all matches in the string
            let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            // Extract URLs from matches
            let urls = matches.compactMap { $0.url?.absoluteString }
            return urls
            
        }catch {
            print("extractURLs error: \(error)")
            return []
        }
    }
    
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
            
        }catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
