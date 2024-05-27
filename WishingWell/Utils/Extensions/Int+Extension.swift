//
//  Int+Extension.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/20.
//

import Foundation

extension Int {
    func convertProductStatus() -> String? {
        let status = ProductStatus(rawValue: self)
        switch status {
        case .NOTDEPLOYED:
            return "NOTDEPLOYED".localized()
            
        case .DEPLOYED:
            return "DEPLOYED".localized()
            
        case .EXPIRED:
            return "EXPIRED".localized()
            
        case .PROCESSING:
            return "PROCESSING".localized()
            
        case .SUSPENDED:
            return "SUSPENDED".localized()
            
        case .TERMINATED:
            return "TERMINATED".localized()
            
        default:
            return nil
        }
    }
    
    func convertReportType() -> String? {
        let type = ReportType(rawValue: self)
        switch type {
        case .HateSpeech:
            return "Hate Speech".localized()
        
        case .ViolenceOrThreats:
            return "Violence Or Threats".localized()
       
        case .ExplicitContent:
            return "Explicit Content".localized()
       
        case .FalseInformation:
            return "False Information".localized()
        
        case .CopyrightInfringement:
            return "Copyright Infringement".localized()
        
        case .PrivacyViolation:
            return "Privacy Violation".localized()
        
        case .InvolvingScam:
            return "Involving Scam".localized()
        
        case .OtherIllegalOrInappropriateContent:
            return "Other Illegal Or Inappropriate Content".localized()
        
        default:
            return nil
        }
    }
    
    func convertUserType() -> String? {
        guard let type = UserType(rawValue: self) else { return nil }
        switch type {
        case .WISHER:
            return ""
            
        case .BUYER, .BUYER_PRIME:
            return "Buyer".localized()
        }
    }
    
    func convertDealType() -> String? {
        let type = DealType(rawValue: self)
        switch type {
        case .FACETOFACE:
            return "面交"
            
        case .PLATFORM_7ELEVEN:
            return "7-11 - 賣貨便"
            
        case .PLATFORM_FAMILYMART:
            return "全家 - 好賣+"
        
        case .PLATFORM_HILIFE:
            return "萊爾富 - 萊賣貨"
       
        default:
            return nil
        }
    }
    
    func convertOrderStatus() -> String? {
        let status = OrderStatus(rawValue: self)
        switch status {
        case .DISCUSSING:
            return "DISCUSSING".localized()
            
        case .PROCESSING:
            return "PROCESSING_ORDER".localized()
            
        case .CANCELED:
            return "CANCELED".localized()
            
        case .COMPLETED:
            return "COMPLETED".localized()
            
        default:
            return nil
        }
    }
}
