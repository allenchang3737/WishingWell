//
//  Date+Extension.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/15.
//

import Foundation

enum DateFormatType: String {
    case Server = "yyyy-MM-dd'T'HH:mm:ssZ"
    case CMMdd = "MM月dd日"
    case CMdd = "M月dd日"
    case CyyyyMM = "yyyy年MM月"
    case CyyyyMMdd = "yyyy年MM月dd日"
    case CyyyyMMddHHmm = "yyyy年MM月dd日 HH:mm"
    case CyyMMdd = "yy年MM月dd日"
    case CMMddHHmm = "MM月dd日 HH:mm"
    case CMddHHmm = "M月dd HH:mm"
    case yyyyMMdd = "yyyy/MM/dd"
    case yyyyMMddHHmm = "yyyy/MM/dd HH:mm"
    case yyyyMMddHHmmss = "yyyy/MM/dd HH:mm:ss"
    case MMdd = "MM/dd"
    case Mdd = "M/dd"
    case MddHHmm = "M/dd HH:mm"
    case MMddHHmm = "MM/dd HH:mm"
    case HHmm = "HH:mm"
    case HHmmss = "HH:mm:ss"
}

extension Date {
    func rangeOfPeriod(period: Calendar.Component) -> (Date, Date) {
        var startDate = Date()
        var interval : TimeInterval = 0
        let _ = Calendar.current.dateInterval(of: period, start: &startDate, interval: &interval, for: self)
        let endDate = startDate.addingTimeInterval(interval - 1)
        
        return (startDate, endDate)
    }
    
    func calcStartAndEndOfDay() -> (Date, Date) {
        return rangeOfPeriod(period: .day)
    }
    
    func getStart() -> Date {
        let (start, _) = calcStartAndEndOfDay()
        return start
    }
    
    func getEnd() -> Date {
        let (_, end) = calcStartAndEndOfDay()
        return end
    }
    
    func isBigger(to: Date) -> Bool {
        return Calendar.current.compare(self, to: to, toGranularity: .day) == .orderedDescending ? true : false
    }
    
    func isSmaller(to: Date) -> Bool {
        return Calendar.current.compare(self, to: to, toGranularity: .day) == .orderedAscending ? true : false
    }
    
    func isEqual(to: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: to)
    }
    
    func convertString(format: DateFormatType) -> String {
        let formatter = DateFormatter()
//        if format == .Server {
//            formatter.locale = Locale(identifier: "zh_Hant_TW")             //設定地區(台灣)
//            formatter.timeZone = TimeZone(identifier: "Asia/Taipei")        //設定時區(台灣)
//        }
//        formatter.calendar = Calendar(identifier: .gregorian)           //設定24小時制
        formatter.dateFormat = format.rawValue
        return formatter.string(from: self)
    }
}
