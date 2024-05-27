//
//  UserHeaderReusableView.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/19.
//

import UIKit

enum UserHeaderReusableType {
    case wishing
    case buying
}

class UserHeaderReusableView: UICollectionReusableView {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    @IBOutlet weak var introTextView: UITextView!
    
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var chatBtn: UIButton!
    @IBOutlet weak var emailBtn: UIButton!
    
    var currentFileId: Int?
    var activeUser: User?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(userImageAction))
        userImageView.addGestureRecognizer(imageTap)
        
        statusLbl.text = ""
        introTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    func configure(user: User, type: UserHeaderReusableType?) {
        self.activeUser = user
        handleImage(user)
        accountLbl.text = user.account
        introTextView.text = user.intro
        
        //Email
        emailBtn.isHidden = user.email.isEmpty
        
        switch type {
        case .wishing:
            statusLbl.text = "Wishing".localized()
            statusLbl.textColor = .systemGreen
            
        case .buying:
            statusLbl.text = "Buying".localized()
            statusLbl.textColor = .systemRed
            
        default:
            statusLbl.text = ""
        }
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
    
    //MARK: Action
    @objc private func userImageAction() {
        guard let image = self.userImageView.image else { return }
        UIApplication.topViewController()?.showPhotoViewerView(images: [image])
    }
    
    @IBAction func chatAction(_ sender: Any) {
        print("chatAction...")
    }
    
    @IBAction func emailAction(_ sender: Any) {
        guard let email = self.activeUser?.email else { return }
        OpenManager.shared.sendEmail(email: email, subject: nil, message: nil)
    }
}
