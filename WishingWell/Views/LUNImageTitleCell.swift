//
//  LUNImageTitleCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/22.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

struct ImageTitleData {
    var image: UIImage?
    var title: String?
}

class LUNImageTitleCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var primeLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    func configure(data: ImageTitleData) {
        imageview.image = data.image
        titleLbl.text = data.title
        primeLbl.isHidden = true
    }
    
    func checkUserType(type: UserType) {
        switch type {
        case .WISHER:
            imageview.image = UIImage(systemName: "checkmark.shield")
            primeLbl.isHidden = true
            
        case .BUYER:
            imageview.image = UIImage(systemName: "checkmark.shield.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            primeLbl.isHidden = true
            
        case .BUYER_PRIME:
            imageview.image = UIImage(systemName: "checkmark.shield.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            primeLbl.isHidden = false
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
