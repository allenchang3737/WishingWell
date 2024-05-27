//
//  BecomeTypeCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/30.
//

import UIKit

class BecomeTypeCell: UITableViewCell {
    @IBOutlet weak var backgroundview: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var noteLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }

    func configureStandard(currentType: UserType, selectedType: UserType?) {
        titleLbl.text = "Standard".localized()
        subtitleLbl.text = "Free".localized()
        noteLbl.text = "Standard rules".localized().htmlToString
        
        if currentType == .BUYER {
            backgroundview.borderColor = .systemGreen
            backgroundview.borderWidth = 1
        }else {
            backgroundview.borderColor = .lightGray
            backgroundview.borderWidth = 0.25
        }
        
        if let selected = selectedType {
            if selected == .BUYER {
                backgroundview.borderColor = .systemGreen
                backgroundview.borderWidth = 1
                
            }else {
                backgroundview.borderColor = .lightGray
                backgroundview.borderWidth = 0.25
            }
        }
    }
    
    func configurePrime(currentType: UserType, selectedType: UserType?) {
        guard let fee = AppConfigService.shared.config?.subscribedFee else { return }
        titleLbl.text = "Prime".localized()
        subtitleLbl.text = "Per month".localized() + " $\(fee.priceFormatting())"
        noteLbl.text = "Prime rules".localized().htmlToString
        
        if currentType == .BUYER_PRIME {
            backgroundview.borderColor = .systemGreen
            backgroundview.borderWidth = 1
        }else {
            backgroundview.borderColor = .lightGray
            backgroundview.borderWidth = 0.25
        }
        
        if let selected = selectedType {
            if selected == .BUYER_PRIME {
                backgroundview.borderColor = .systemGreen
                backgroundview.borderWidth = 1
                
            }else {
                backgroundview.borderColor = .lightGray
                backgroundview.borderWidth = 0.25
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
