//
//  LUNImagesCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/31.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import YPImagePicker

protocol LUNImagesCellDelegate {
    func didSelectImages(data: [ImageFileData])
    func didDeleteImage(index: Int)
}

struct ImageFileData {
    var image: UIImage?
    var file: File?
}

class LUNImagesCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var collectionview: UICollectionView!
    
    //Configuration
    private var activeData: [ImageFileData] = []
    private var maxCount: Int = 0
    
    var delegate: LUNImagesCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        collectionview.register(UINib(nibName: "ImageCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ImageCollectionCell")
        collectionview.dataSource = self
        collectionview.delegate = self
    }
    
    func configure(data: [ImageFileData], max: Int) {
        activeData = data
        maxCount = max
        
        titleLbl.text = "\(self.activeData.count) / \(maxCount)"
        collectionview.reloadData()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func photoPickerAction() {
        let manager = PermissionsManager()
        manager.requestPermission(.photoLibrary) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.openImagePicker()
                
                }else {
                    UIApplication.topViewController()?.showOpenSetting(title: nil, message: "Open camera permission".localized())
                }
            }
        }
    }
    
    func openImagePicker() {
        var config = YPImagePickerConfiguration()
        config.onlySquareImagesFromCamera = false
        config.startOnScreen = YPPickerScreen.library
        
        //Max count
        let max = self.maxCount - self.activeData.count
        config.library.maxNumberOfItems = max
        
        let picker = YPImagePicker(configuration: config)
        //issue: YPImagePicker會導致NavigationBar跑版，必須設定modalPresentationStyle
        picker.modalPresentationStyle = .overFullScreen
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled {
                print("Picker was canceled...")
                
            }else {
                for item in items {
                    switch item {
                    case .photo(let photo):
                        let new = ImageFileData(image: photo.image)
                        self.activeData.append(new)
                        
                    case .video(let video):
                        print("Select video...")
                    }
                }
                self.delegate?.didSelectImages(data: self.activeData)
            }
            picker.dismiss(animated: true, completion: nil)
        }
        UIApplication.topViewController()?.present(picker, animated: true, completion: nil)
    }
    
    //MARK: Action
    @IBAction func addAction(_ sender: Any) {
        //檢查照片上限
        if self.activeData.count >= self.maxCount {
            UIApplication.topViewController()?.showAlert(title: nil, message: "Exceed maximum number of photos".localized())
            
        }else {
            photoPickerAction()
        }
    }
    
    func showDeleteImageAlert(index: Int) {
        let alert = UIAlertController(title: nil, message: "Confirm delete?".localized(), preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        let confirm = UIAlertAction(title: "Confirm".localized(), style: .default) { action in
            self.delegate?.didDeleteImage(index: index)
        }
        alert.addAction(confirm)
        alert.addAction(cancel)
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }
}

//MARK: UICollectionViewDelegate
extension LUNImagesCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activeData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as! ImageCollectionCell
        
        let data = activeData[row]
        if let image = data.image {
            cell.configure(image: image)
            
        }else if let file = data.file {
            cell.configure(fileId: file.fileId)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        showDeleteImageAlert(index: row)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.collectionview.frame.height
        let width = self.collectionview.frame.width
        
        return CGSize(width: width, height: height)
    }
}
