//
//  UserThemeReusableView.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/19.
//

import UIKit

enum UserThemeReusableType {
    case wish
    case buy
    case comment
}

class UserThemeReusableView: UICollectionReusableView {
    @IBOutlet weak var wishStackView: UIStackView!
    @IBOutlet weak var wishCountLbl: UILabel!
    @IBOutlet weak var wishTitleLbl: UILabel!
    @IBOutlet weak var wishSelectedView: UIView!
    
    @IBOutlet weak var buyStackView: UIStackView!
    @IBOutlet weak var buyCountLbl: UILabel!
    @IBOutlet weak var buyTitleLbl: UILabel!
    @IBOutlet weak var buySelectedView: UIView!
    
    @IBOutlet weak var commentStackView: UIStackView!
    @IBOutlet weak var commentCountLbl: UILabel!
    @IBOutlet weak var commentTitleLbl: UILabel!
    @IBOutlet weak var commentSelectedView: UIView!
    
    var selectedType: UserThemeReusableType = .wish {
        didSet {
            checkSelectedType()
        }
    }
    
    var completionHandler: ((_ selected: UserThemeReusableType) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        wishTitleLbl.text = "Wish".localized()
        let wishTap = UITapGestureRecognizer(target: self, action: #selector(wishAction))
        wishStackView.addGestureRecognizer(wishTap)
        
        buyTitleLbl.text = "Buy".localized()
        let buyTap = UITapGestureRecognizer(target: self, action: #selector(buyAction))
        buyStackView.addGestureRecognizer(buyTap)
        
        commentTitleLbl.text = "Comment".localized()
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(commentAction))
        commentStackView.addGestureRecognizer(commentTap)
    }
    
    func configure(wish: Int, buy: Int, comment: Int) {
        wishCountLbl.text = "\(wish)"
        buyCountLbl.text = "\(buy)"
        commentCountLbl.text = "\(comment)"
    }
    
    private func checkSelectedType() {
        wishCountLbl.textColor = .lightGray
        wishTitleLbl.textColor = .lightGray
        wishSelectedView.backgroundColor = .clear
        
        buyCountLbl.textColor = .lightGray
        buyTitleLbl.textColor = .lightGray
        buySelectedView.backgroundColor = .clear
        
        commentCountLbl.textColor = .lightGray
        commentTitleLbl.textColor = .lightGray
        commentSelectedView.backgroundColor = .clear
        
        switch self.selectedType {
        case .wish:
            wishCountLbl.textColor = .label
            wishTitleLbl.textColor = .label
            wishSelectedView.backgroundColor = .label
            
        case .buy:
            buyCountLbl.textColor = .label
            buyTitleLbl.textColor = .label
            buySelectedView.backgroundColor = .label
            
        case .comment:
            commentCountLbl.textColor = .label
            commentTitleLbl.textColor = .label
            commentSelectedView.backgroundColor = .label
        }
    }
    
    //MARK: Action
    @objc private func wishAction() {
        self.selectedType = .wish
        completionHandler?(self.selectedType)
    }
    
    @objc private func buyAction() {
        self.selectedType = .buy
        completionHandler?(self.selectedType)
    }
    
    @objc private func commentAction() {
        self.selectedType = .comment
        completionHandler?(self.selectedType)
    }
}
