//
//  OrderUserCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/28.
//

import UIKit

class OrderUserCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    @IBOutlet weak var starLbl: UILabel!
    @IBOutlet weak var commentBtn: UIButton!
    
    @IBOutlet weak var maskview: UIView!
    @IBOutlet weak var maskStackView: UIStackView!
    @IBOutlet weak var maskLbl: UILabel!
    @IBOutlet weak var finishBtn: UIButton!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        commentBtn.setTitle("Write comment".localized(), for: .normal)
        finishBtn.setTitle("COMPLETED".localized(), for: .normal)
    }
    
    func configure(user: User, star: Double?) {
        handleImage(user)
        accountLbl.text = user.account
        
        starLbl.text = "\(star ?? 0.0)"
    }
    
    func configureMasK(status: OrderStatus, isOwner: Bool) {
        if status == .COMPLETED {
            maskview.isHidden = true
            maskStackView.isHidden = true
            
        }else {
            maskview.isHidden = false
            maskStackView.isHidden = false
        }
        
        maskLbl.text = isOwner ? "Order lock message for owner".localized() : "Order lock message for user".localized()
        finishBtn.isHidden = !isOwner
    }
    
    private func handleImage(_ user: User) {
        self.imageview.image = nil
        guard let fileId = user.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId else { return }
        self.currentFileId = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileId else {
                self.imageview.image = nil
                return
            }
            self.imageview.image = image
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
