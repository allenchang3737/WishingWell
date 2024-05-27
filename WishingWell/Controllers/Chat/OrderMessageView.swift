//
//  OrderMessageView.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2024/3/13.
//  Copyright © 2024 LunYuChang. All rights reserved.
//

import UIKit

class OrderMessageView: UIView {
    @IBOutlet var contentview: UIView!
    
    @IBOutlet weak var productStackView: UIStackView!
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    @IBOutlet weak var noteLbl: UILabel!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLbl: UILabel!
    
    @IBOutlet weak var noteTextView: UITextView!
    
    @IBOutlet weak var lookBtn: UIButton!
    @IBOutlet weak var acceptBtn: UIButton!
    
    var currentFileId: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    private func initializeView() {
        backgroundColor = UIColor.clear

        //Load Nib
        self.contentview = loadNib()
        self.contentview.frame = bounds
        addSubview(contentview)
        
        noteTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func configure(item: OrderItem) {
        //Product
        if let fileId = item.productFileId {
            handleImage(fileId)
        }else {
            imageview.image = nil
        }
        
        titleLbl.text = item.productTitle
        
        //Order Title
        noteLbl.text = "Order".localized()
        
        //Order Status
        statusLbl.text = item.orderStatus.convertOrderStatus()
        statusLbl.textColor = .label
        let status = OrderStatus(rawValue: item.orderStatus)
        switch status {
        case .DISCUSSING:
            statusImageView.image = UIImage(systemName: "ellipsis.message.fill")?.withTintColor(.systemGray4, renderingMode: .alwaysOriginal)
            
        case .PROCESSING:
            statusLbl.textColor = .systemGreen
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            
        case .CANCELED:
            statusImageView.image = UIImage(systemName: "xmark.circle.fill")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
            
        case .COMPLETED:
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
            
        case nil:
            statusImageView.image = nil
        }
        
        //Order Note
        noteTextView.text = item.orderContent
    }
    
    private func handleImage(_ fileId: Int) {
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
}
