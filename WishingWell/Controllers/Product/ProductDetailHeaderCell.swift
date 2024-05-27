//
//  ProductDetailHeaderCell.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/22.
//

import UIKit

class ProductDetailHeaderCell: UITableViewCell {
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var pagecontrol: UIPageControl!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    
    var imageFiles: [File] = [] {
        didSet {
            self.pagecontrol.numberOfPages = self.imageFiles.count
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        collectionview.register(UINib(nibName: "ImageCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ImageCollectionCell")
        collectionview.dataSource = self
        collectionview.delegate = self
        
        pagecontrol.hidesForSinglePage = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showImages))
        collectionview.addGestureRecognizer(tap)
    }
    
    func configure(product: Product) {
        //Product
        handleImages(product)
        titleLbl.text = product.title
        
        //Product Price
        if let price = product.price,
           price != 0 {
            priceLbl.text = "$ \(price.priceFormatting())"
            
        }else {
            priceLbl.text = "Price negotiation".localized()
        }
    }
    
    private func handleImages(_ product: Product) {
        guard let files = product.files?.filter({ $0.type == FileType.PRODUCT.rawValue }) else {
            self.imageFiles = []
            return
        }
        self.imageFiles = files
        self.collectionview.reloadData()
    }

    @objc func showImages() {
        guard !self.imageFiles.isEmpty,
              let topVC = UIApplication.topViewController() else { return }
        
        var images: [UIImage] = []
        topVC.showActivityIndicator()
        DispatchQueue(label: "serialQueue").async {
            for file in self.imageFiles {
                FileService.shared.getImage(fileId: file.fileId) { image in
                    print("getImage fileId: \(file.fileId)")
                    images.append(image)
                }
            }
            
            DispatchQueue.main.async {
                topVC.hideActivityIndicator()
                topVC.showPhotoViewerView(images: images)
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

//MARK: UICollectionViewDelegate
extension ProductDetailHeaderCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! ImageCollectionCell
        
        let imagefile = imageFiles[row]
        cell.configure(fileId: imagefile.fileId)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height
        let width = collectionView.frame.width
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.pagecontrol.currentPage = indexPath.item
    }
}
