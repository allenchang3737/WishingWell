//
//  PushNoticeCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/22.
//

import UIKit

class PushNoticeCell: UITableViewCell {
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var pushImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    @IBOutlet weak var textview: UITextView!
    
    @IBOutlet weak var moveBtn: UIButton!
    @IBOutlet weak var buttonView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        moveBtn.setTitle("Move".localized(), for: .normal)
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    func configure(template: PushNoticeTemplate) {
        let notice = template.pushNoticeOb
        let collapsed = template.collapsed
        
        //Time, Title, Image
        timeLbl.text = notice.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm)
        titleLbl.text = notice.pushTitle
        if !notice.imgUrl.isEmpty {
            pushImageView.isHidden = false
            FileService.shared.getImage(url: notice.imgUrl) { image in
                DispatchQueue.main.async {
                    self.pushImageView.image = image
                }
            }
        
        }else {
            pushImageView.isHidden = true
        }
        
        //Arrow
        arrowImageView.image = collapsed ? UIImage(systemName: "chevron.up") : UIImage(systemName: "chevron.down")
        
        //Text
        textview.text = notice.pushContent
        textview.isHidden = !collapsed
        
        //Button
        if collapsed,
           !notice.action.isEmpty {
            buttonView.isHidden = false
            
        }else {
            buttonView.isHidden = true
        }
        
        //isRead
        if notice.isRead {
            timeLbl.textColor = .lightGray
            titleLbl.textColor = .lightGray
            textview.textColor = .lightGray
        
        }else {
            timeLbl.textColor = .label
            titleLbl.textColor = .label
            textview.textColor = .label
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
