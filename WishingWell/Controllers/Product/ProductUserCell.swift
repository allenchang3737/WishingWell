//
//  ProductUserCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/22.
//

import UIKit

class ProductUserCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    func configure(user: User?) {
        if let user = user {
            accountLbl.text = user.account
            handleImage(user)
            
            //User Type
            statusLbl.text = user.userType.convertUserType()
       
        }else {
            accountLbl.text = "Unknown".localized()
            statusLbl.text = "Unknown".localized()
        }
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
