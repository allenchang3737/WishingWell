//
//  LUNBadgeButton.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/11/21.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class LUNBadgeButton: UIButton {
    var badgeLbl = UILabel()
    let badgeSize: CGFloat = 20
    let badgeTag = 9830384
    
    //Dot
    var dotLbl = UILabel()
    let dotSize: CGFloat = 8
    let dotTag = 9830383
    
    override func awakeFromNib() {
        superview?.awakeFromNib()
    }
    
    func setBadge(count: Int, padding: Int = 0) {
        removeBadge()
        badgeLbl = badgeLabel(withCount: count)
        self.addSubview(badgeLbl)
        
        var width = badgeSize
        if count >= 100 {
            width += 5
        }
        badgeLbl.leftAnchor.constraint(equalTo: self.rightAnchor, constant: CGFloat(padding)).isActive = true   // - 靠右
        badgeLbl.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive = true                 // + 往下
        badgeLbl.widthAnchor.constraint(equalToConstant: width).isActive = true
        badgeLbl.heightAnchor.constraint(equalToConstant: badgeSize).isActive = true
        badgeLbl.isHidden = count == 0 ? true : false
    }
    
    private func badgeLabel(withCount count: Int) -> UILabel {
        let badgeCount = UILabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        badgeCount.translatesAutoresizingMaskIntoConstraints = false
        badgeCount.tag = badgeTag
        badgeCount.layer.cornerRadius = badgeCount.bounds.size.height / 2
        badgeCount.textAlignment = .center
        badgeCount.layer.masksToBounds = true
        badgeCount.textColor = .white
        badgeCount.font = badgeCount.font.withSize(12)
        badgeCount.backgroundColor = .systemRed
        badgeCount.text = String(count)
        return badgeCount
    }
    
    func removeBadge() {
        if let badge = self.viewWithTag(badgeTag) {
            badge.removeFromSuperview()
        }
    }
    
    func setDot(_ isShow: Bool) {
        removeDot()
        dotLbl = dotLabel()
        self.addSubview(dotLbl)
        
        dotLbl.topAnchor.constraint(equalTo: self.topAnchor, constant: CGFloat(-4)).isActive = true
        dotLbl.leftAnchor.constraint(equalTo: self.rightAnchor, constant: CGFloat(-2)).isActive = true
//        dotLbl.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 14).isActive = true
        dotLbl.widthAnchor.constraint(equalToConstant: dotSize).isActive = true
        dotLbl.heightAnchor.constraint(equalToConstant: dotSize).isActive = true
        dotLbl.isHidden = isShow ? false : true
    }
    
    private func dotLabel() -> UILabel {
        let dotLbl = UILabel(frame: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        dotLbl.translatesAutoresizingMaskIntoConstraints = false
        dotLbl.tag = dotTag
        dotLbl.layer.cornerRadius = dotLbl.bounds.size.height / 2
        dotLbl.layer.masksToBounds = true
        dotLbl.backgroundColor = .systemRed
        return dotLbl
    }
    
    func removeDot() {
        if let dot = self.viewWithTag(dotTag) {
            dot.removeFromSuperview()
        }
    }
}
