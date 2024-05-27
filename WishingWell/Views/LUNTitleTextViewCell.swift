//
//  LUNTitleTextViewCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/8/6.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

struct TitleTextViewData {
    var title: String
    var text: String
    var axis: NSLayoutConstraint.Axis = .vertical
}

class LUNTitleTextViewCell: UITableViewCell {
    @IBOutlet weak var stackview: UIStackView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var textview: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    }
    
    override func prepareForReuse() {
        textview.textColor = .label
        textview.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }
    
    func configure(data: TitleTextViewData) {
        titleLbl.text = data.title
        textview.text = data.text
        
        stackview.axis = data.axis
        if data.axis == .vertical {
            textview.textAlignment = .left
        }else {
            textview.textAlignment = .right
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
