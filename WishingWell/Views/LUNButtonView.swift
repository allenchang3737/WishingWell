//
//  LUNButtonView.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/6/17.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class LUNButtonView: UIView {
    @IBOutlet weak var button: UIButton!
    @IBOutlet var contentview: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeView()
    }
    
    private func initializeView() {
        //Load Nib
        self.contentview = loadNib()
        self.contentview.frame = bounds
        addSubview(contentview)
    }
}
