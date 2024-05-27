//
//  PhotoViewerViewController.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2024/1/3.
//  Copyright © 2024 LunYuChang. All rights reserved.
//

import UIKit

class PhotoViewerViewController: UIViewController {
    @IBOutlet weak var imageScrollView: ImageScrollView!
    @IBOutlet weak var numberLbl: UILabel!
    
    //Configuration
    var images: [UIImage] = []
    
    //Data
    var index = 0 {
        didSet {
            DispatchQueue.main.async {
                self.setNumberLbl()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showNavigationBar()
        hideTabBar()
    }

    func setupLayout() {
        imageScrollView.setup()
        imageScrollView.imageScrollViewDelegate = self
        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center
        imageScrollView.display(image: images[index])
        
        // Add swipe gesture recognizers
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        setNumberLbl()
    }
    
    func setNumberLbl() {
        numberLbl.text = "\(index + 1) / \(self.images.count)"
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            print("Swiped Left...")
            index = (index + 1) % images.count
            imageScrollView.display(image: images[index])
            
        }else if gesture.direction == .right {
            print("Swiped Right...")
            index = (index - 1 + images.count) % images.count
            imageScrollView.display(image: images[index])
        }
    }
}

extension PhotoViewerViewController: ImageScrollViewDelegate {
    func imageScrollViewDidChangeOrientation(imageScrollView: ImageScrollView) {
        print("Did change orientation")
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("scrollViewDidEndZooming at scale \(scale)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollViewDidScroll at offset \(scrollView.contentOffset)")
    }
}
