//
//  MenuUserCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/22.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class MenuUserCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        editBtn.setTitle("Read and edit user".localized(), for: .normal)
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(userImageAction))
        imageview.addGestureRecognizer(imageTap)
    }
    
    func configure(user: User) {
        nameLbl.text = user.account
        handleImage(user)
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
    
    //MARK: Action
    @objc private func userImageAction() {
        guard let image = self.imageview.image else { return }
        UIApplication.topViewController()?.showPhotoViewerView(images: [image])
    }
}
