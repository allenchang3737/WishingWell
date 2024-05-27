//
//  ChatHeaderView.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/27.
//

import UIKit

class ChatHeaderView: UIView {
    @IBOutlet var contentview: UIView!
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
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
    }
    
    func configure(product: Product) {
        titleLbl.text = product.title
        if let price = product.price,
           price != 0 {
            priceLbl.text = "$ \(price.priceFormatting())"
        }else {
            priceLbl.text = nil
        }
        handleImage(product)
    }

    private func handleImage(_ product: Product) {
        self.imageview.image = nil
        guard let fileId = product.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId else { return }
        FileService.shared.getImage(fileId: fileId) { image in
            self.imageview.image = image
        }
    }
}
