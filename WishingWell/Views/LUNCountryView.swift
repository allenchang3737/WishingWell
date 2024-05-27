//
//  LUNCountryView.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2021/11/24.
//  Copyright © 2021 LunYuChang. All rights reserved.
//

import UIKit
import SKCountryPicker

class LUNCountryView: UIView {
    @IBOutlet var contentview: UIView!
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
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
        
        self.contentview.isHidden = true
    }
    
    func configure(code: String) {
        //檢查第三方套件'SKCountryPicker': mapping不到countryCode閃退
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? "")
        guard let localisedCountryName = locale.localizedString(forRegionCode: code) else {
            contentview.isHidden = true
            return
        }
        
        let country = Country(countryCode: code)
        if country.countryName.isEmpty {
            contentview.isHidden = true
            
        }else {
            contentview.isHidden = false
            imageview.image = country.flag
            titleLbl.text = country.countryName
        }
        
        imageview.cornerRadius = imageview.frame.height / 2
        contentview.cornerRadius = self.frame.size.height / 2
    }
}
