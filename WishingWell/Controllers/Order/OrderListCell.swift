//
//  OrderListCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/26.
//

import UIKit

class OrderListCell: UITableViewCell {
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    @IBOutlet weak var maskview: UIView!
    @IBOutlet weak var statusLbl: UILabel!
    
    var currentFileId: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    func configure(product: Product) {
        titleLbl.text = product.title
        dateLbl.text = product.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm)
        if let price = product.price,
           price != 0 {
            priceLbl.text = "$ \(price.priceFormatting())"
        }else {
            priceLbl.text = nil
        }
        handleImage(product)
        
        //Product Status
        let status = ProductStatus(rawValue: product.status)
        switch status {
        case .NOTDEPLOYED, .EXPIRED, .SUSPENDED, .TERMINATED:
            maskview.isHidden = false
            statusLbl.isHidden = false
            statusLbl.text = product.status.convertProductStatus()
            statusLbl.textColor = UIColor.convertProductStatus(product.status)
            
        default:
            maskview.isHidden = true
            statusLbl.isHidden = true
        }
    }

    func configure(order: Order) {
        titleLbl.text = order.orderNote
        dateLbl.text = order.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm)
        priceLbl.text = "$ \(order.amount.priceFormatting())"
        handleImage(order.product)
        
        //Order Status
        statusLbl.text = order.status.convertOrderStatus()
        statusLbl.textColor = UIColor.convertOrderStatus(order.status)
        let status = OrderStatus(rawValue: order.status)
        switch status {
        case .DISCUSSING:
            maskview.isHidden = true
            statusLbl.isHidden = true
            
        default:
            maskview.isHidden = false
            statusLbl.isHidden = false
        }
    }
    
    private func handleImage(_ product: Product?) {
        self.imageview.image = nil
        guard let fileId = product?.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId else { return }
        self.currentFileId = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileId else {
                self.imageview.image = nil
                return
            }
            self.imageview.image = image
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
