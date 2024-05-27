//
//  BecomeBuyerCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/30.
//

import UIKit

class BecomeBuyerCell: UITableViewCell {
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var checkLine: UIView!
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var detailLbl: UILabel!
    @IBOutlet weak var verifyBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    override func prepareForReuse() {
        verifyBtn.removeTarget(nil, action: nil, for: .allEvents)
    }
    
    func configureEmail(user: User) {
        titleLbl.text = "Verify email".localized()
        verifyBtn.isHidden = false
        if user.emailVerified {
            checkImageView.tintColor = .systemGreen
            checkLine.backgroundColor = .systemGreen
            
            titleLbl.textColor = .systemGreen
            detailLbl.text = "Verified successfully".localized() + user.email
            detailLbl.textColor = .systemGreen
            verifyBtn.setTitle("Verified".localized(), for: .normal)
            verifyBtn.backgroundColor = .systemGreen
            verifyBtn.alpha = 0.8
            
        }else {
            checkImageView.tintColor = .lightGray
            checkLine.backgroundColor = .lightGray
            
            titleLbl.textColor = .lightGray
            detailLbl.text = "Not verified yet".localized()
            detailLbl.textColor = .lightGray
            verifyBtn.setTitle("Verify".localized(), for: .normal)
            verifyBtn.backgroundColor = .label
            verifyBtn.alpha = 1
        }
    }
        
    func configurePhone(user: User) {
        titleLbl.text = "Verify phone".localized()
        verifyBtn.isHidden = false
        if user.phoneVerified {
            checkImageView.tintColor = .systemGreen
            checkLine.backgroundColor = .systemGreen
            
            titleLbl.textColor = .systemGreen
            detailLbl.text = "Verified successfully".localized() + (user.phone ?? "")
            detailLbl.textColor = .systemGreen
            verifyBtn.setTitle("Verified".localized(), for: .normal)
            verifyBtn.backgroundColor = .systemGreen
            verifyBtn.alpha = 0.8
            
        }else {
            checkImageView.tintColor = .lightGray
            checkLine.backgroundColor = .lightGray
            
            titleLbl.textColor = .lightGray
            detailLbl.text = "Not verified yet".localized()
            detailLbl.textColor = .lightGray
            verifyBtn.setTitle("Verify".localized(), for: .normal)
            verifyBtn.backgroundColor = .label
            verifyBtn.alpha = 1
        }
    }

    func configureType(user: User, selectedType: UserType?) {
        titleLbl.text = "Choose your plan".localized()
        verifyBtn.isHidden = true
        guard let type = UserType(rawValue: user.userType) else { return }
        switch type {
        case .WISHER:
            checkImageView.tintColor = .lightGray
            checkLine.backgroundColor = .lightGray
            
            titleLbl.textColor = .lightGray
            detailLbl.text = "Not selected yet".localized()
            detailLbl.textColor = .lightGray
            
        case .BUYER:
            checkImageView.tintColor = .systemGreen
            checkLine.backgroundColor = .systemGreen
            
            titleLbl.textColor = .systemGreen
            detailLbl.text = "Selected plan".localized() + "【\("Standard".localized())】"
            detailLbl.textColor = .systemGreen
            
        case .BUYER_PRIME:
            checkImageView.tintColor = .systemGreen
            checkLine.backgroundColor = .systemGreen
            
            titleLbl.textColor = .systemGreen
            detailLbl.text = "Selected plan".localized() + "【\("Prime".localized())】"
            detailLbl.textColor = .systemGreen
        }
        
        //Selected
        if let selected = selectedType {
            checkImageView.tintColor = .lightGray
            checkLine.backgroundColor = .lightGray
            
            titleLbl.textColor = .lightGray
            if selected == .BUYER {
                detailLbl.text = "Selected plan".localized() + "【\("Standard".localized())】"
            }else {
                detailLbl.text = "Selected plan".localized() + "【\("Prime".localized())】"
            }
            detailLbl.textColor = .lightGray
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
