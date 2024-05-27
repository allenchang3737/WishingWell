//
//  ProductCollectionCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/19.
//

import UIKit

class ProductCollectionCell: UICollectionViewCell {
    @IBOutlet weak var cellWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    @IBOutlet weak var maskview: UIView!
    @IBOutlet weak var statusLbl: UILabel!
    
    @IBOutlet weak var countryView: LUNCountryView!
    
    var cellWidth: CGFloat = 200
    var cellHeight: CGFloat = 320
    
    var currentFileIdUser: Int?
    var currentFileIdProd: Int?
    var currentProduct: Product?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(userAction))
        userStackView.addGestureRecognizer(tap)
    }
    
    func configure(product: Product,
                   width: CGFloat,
                   height: CGFloat,
                   isShowUser: Bool = true) {
        self.currentProduct = product
        if isShowUser {
            self.cellHeight = height
            userStackView.isHidden = false
            
        }else {
            self.cellHeight = height - 32
            userStackView.isHidden = true
        }
        self.cellWidth = width
        //bug: AutoLayout 必須限制寬度不然會跑版
        cellWidthConstraint.constant = self.cellWidth
        
        //Product User
        if let user = product.user {
            handleImage(user)
            accountLbl.text = user.account
            
        }else {
            userImageView.image = nil
            accountLbl.text = "Unknown".localized()
        }
        
        //Product
        handleImage(product)
        titleLbl.text = product.title
        
        //Product Date
        let start = product.startDate?.convertString(origin: .Server, result: .Mdd)
        let end = product.endDate?.convertString(origin: .Server, result: .Mdd)
        let type = ProductType(rawValue: product.productType)
        switch type {
        case .WISH:
            if start == nil,
               end == nil {
                dateLbl.text = "Wish date".localized() + ": \("Unlimited".localized())"
                
            }else {
                dateLbl.text = "Wish date".localized() + ": \(start ?? "Now".localized()) - \(end ?? "Unlimited".localized())"
            }
            
        case .BUY:
            if start == nil,
               end == nil {
                dateLbl.text = "Buy date".localized() + ": \("Unlimited".localized())"
                
            }else {
                dateLbl.text = "Buy date".localized() + ": \(start ?? "Now".localized()) - \(end ?? "Unlimited".localized())"
            }
        
        case nil:
            dateLbl.text = nil
        }
        
        //Product Price
        if let price = product.price,
           price != 0 {
            priceLbl.text = "$ \(price.priceFormatting())"
            
        }else {
            priceLbl.text = nil
        }
        
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
        
        //Product country
        if let code = product.countryCode {
            countryView.isHidden = false
            countryView.configure(code: code)
        }else {
            countryView.isHidden = true
        }
    }
    
    private func handleImage(_ user: User) {
        self.userImageView.image = nil
        guard let fileId = user.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId else { return }
        self.currentFileIdUser = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileIdUser else {
                self.userImageView.image = nil
                return
            }
            self.userImageView.image = image
        }
    }
    
    private func handleImage(_ product: Product) {
        self.productImageView.image = nil
        guard let fileId = product.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId else { return }
        self.currentFileIdProd = fileId
        FileService.shared.getImage(fileId: fileId) { image in
            guard fileId == self.currentFileIdProd else {
                self.productImageView.image = nil
                return
            }
            self.productImageView.image = image
        }
    }
    
    func showMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let report = UIAlertAction(title: "Report".localized(), style: .default) { action in
            guard let receiverUserId = self.currentProduct?.user?.userId else { return }
            UIApplication.topViewController()?.showReportView(receiverUserId)
        }
        let share = UIAlertAction(title: "Share".localized(), style: .default) { action in
            self.shareAction(sender)
        }
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(report)
        alert.addAction(share)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func shareAction(_ sender: UIButton) {
        guard let product = self.currentProduct else { return }
        var items: [Any] = [product.title]
        if let image = self.productImageView.image {
            items.append(image)
        }
        OpenManager.shared.shareItems(activityItems: items, sender: sender)
    }
    
    //MARK: Action
    @IBAction func moreAction(_ sender: UIButton) {
        showMoreAlert(sender)
    }
    
    @objc private func userAction() {
        guard let user = self.currentProduct?.user else { return }
        UIApplication.topViewController()?.showCustomUserView(user)
    }
    
    //MARK: Layout
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return contentView.systemLayoutSizeFitting(CGSize(width: cellWidth, height: cellHeight))
    }
}
