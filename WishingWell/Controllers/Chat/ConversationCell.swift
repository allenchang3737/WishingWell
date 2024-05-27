//
//  ConversationCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/25.
//

import UIKit

class ConversationCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var dotView: UIView!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }

    func configure(conv: Conversation) {
        let user = conv.users?.first
        handleImage(user)
        nameLbl.text = user?.account
        
        var text = ""
        guard let msg = conv.latestMessage else { return }
        switch msg.type {
        case "photo":
            text = "Send a photo".localized()
            
        case "video":
            text = "Send a video".localized()
            
        case "location":
            text = "Send a location".localized()
            
        case "custom":
            if msg.orderId != nil {
                text = "Send a order".localized()
            }
            
        default:
            text = msg.content
        }
        messageLbl.text = text
        dotView.isHidden = msg.isRead
    }
    
    private func handleImage(_ user: User?) {
        self.userImageView.image = nil
        guard let fileId = user?.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId else { return }
        self.currentFileId = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileId else {
                self.userImageView.image = nil
                return
            }
            self.userImageView.image = image
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
