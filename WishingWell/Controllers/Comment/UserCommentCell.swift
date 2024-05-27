//
//  UserCommentCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/30.
//

import UIKit

class UserCommentCell: UICollectionViewCell {
    @IBOutlet weak var cellWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var starLbl: UILabel!
    
    @IBOutlet weak var textview: UITextView!
    
    var cellWidth: CGFloat = 414
    var cellHeight: CGFloat = 125
    
    var currentFileId: Int?
    var currentUser: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textview.textContainer.maximumNumberOfLines = 2
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }

    func configure(comment: Comment, width: CGFloat) {
        self.currentUser = comment.senderUser
        self.cellWidth = width
        //bug: AutoLayout 必須限制寬度不然會跑版
        cellWidthConstraint.constant = self.cellWidth
        
        //Sender user
        if let user = comment.senderUser {
            handleImage(user)
            accountLbl.text = user.account
            
        }else {
            userImageView.image = nil
            accountLbl.text = "Unknown".localized()
        }
        
        //Date
        dateLbl.text = comment.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm)
        
        //Star
        starLbl.text = "\(comment.star)"
        
        //Text
        textview.text = comment.text
    }
    
    private func handleImage(_ user: User) {
        self.userImageView.image = nil
        guard let fileId = user.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId else { return }
        self.currentFileId = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileId else {
                self.userImageView.image = nil
                return
            }
            self.userImageView.image = image
        }
    }
    
    //MARK: Layout
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return contentView.systemLayoutSizeFitting(CGSize(width: cellWidth, height: cellHeight))
    }
}
