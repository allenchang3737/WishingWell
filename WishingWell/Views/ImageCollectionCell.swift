//
//  ImageCollectionCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/31.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class ImageCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imageview: UIImageView!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(fileId: Int) {
        self.imageview.image = nil
        self.currentFileId = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileId else {
                self.imageview.image = nil
                return
            }
            self.imageview.image = image
        }
    }
    
    func configure(url: String) {
        self.imageview.image = nil
        FileService.shared.getImage(url: url) { image in
            self.imageview.image = image
        }
    }
    
    func configure(image: UIImage?) {
        self.imageview.image = image
    }
}
