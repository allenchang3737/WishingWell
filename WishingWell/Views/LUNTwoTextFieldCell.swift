//
//  LUNTwoTextFieldCell.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/6/12.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import EasyTipView

class LUNTwoTextFieldCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel! {
        didSet {
            self.titleLbl.alpha = 1
        }
    }
    @IBOutlet weak var oneTextField: LUNTextField!
    @IBOutlet weak var twoTextField: LUNTextField!
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var questionBtn: UIButton!
    var easyTipView: EasyTipView?
    
    //MARK: Animated Setting
    private var animated: Bool = true
    public private(set) var animationDuration: Double = 1.0
    
    private var errorMessage: String = ""
    var tipMessage: String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        errorLbl.text = ""
    }
    
    //MARK: Error message
    func showErrorMessage(message: String, index: Int) {
        errorMessage = message
        if index == 1 {
            oneTextField.becomeFirstResponder()
            perform(#selector(oneErrorAnimated))
            
        }else {
            twoTextField.becomeFirstResponder()
            perform(#selector(twoErrorAnimated))
        }
    }
    
    @objc func oneErrorAnimated() {
        errorLbl.text = errorMessage
        titleLbl.textColor = .systemRed
        oneTextField.addTextFieldBorder(color: .systemRed)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                self.titleLbl.alpha = 1
            }, completion: nil)
        }
    }
    
    @objc func twoErrorAnimated() {
        errorLbl.text = errorMessage
        titleLbl.textColor = .systemRed
        twoTextField.addTextFieldBorder(color: .systemRed)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                self.titleLbl.alpha = 1
            }, completion: nil)
        }
    }
    
    func hideErrorMessage(index: Int) {
        errorMessage = ""
        errorLbl.text = ""
        titleLbl.textColor = .darkGray
        let active: LUNTextField = index == 1 ? oneTextField : twoTextField
        active.addTextFieldBorder(color: .placeholderText)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                self.titleLbl.alpha = 0
            }, completion: nil)
        }
    }
    
    public func inactive(index: Int) {
        if errorMessage.isEmpty {
            hideErrorMessage(index: index)
            titleLbl.textColor = .systemBlue
            let active: LUNTextField = index == 1 ? oneTextField : twoTextField
            active.addTextFieldBorder(color: .systemBlue)
            
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                    self.titleLbl.alpha = 1
                })
            }
            
        }else {
            return
        }
    }
    
    public func deactive(index: Int) {
        hideErrorMessage(index: index)
        titleLbl.textColor = .darkGray
        let active: LUNTextField = index == 1 ? oneTextField : twoTextField
        active.addTextFieldBorder(color: .placeholderText)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                if active.text?.count == 0 {
                    self.titleLbl.alpha = 0
                    
                }else {
                    self.titleLbl.alpha = 1
                }
            }, completion: nil)
        }
    }
    
    override func prepareForReuse() {
        //reload cell 移除錯誤顯示
        if !errorMessage.isEmpty {
            hideErrorMessage(index: 1)
            hideErrorMessage(index: 2)
        }
        easyTipView?.dismiss(withCompletion: nil)
        easyTipView = nil
    }
    
    func handleTipView() {
        if easyTipView != nil {
            easyTipView?.dismiss(withCompletion: nil)
            easyTipView = nil
            
        }else {
            easyTipView = EasyTipView(text: tipMessage)
            easyTipView?.show(animated: true,
                              forView: self.questionBtn,
                              withinSuperview: self.contentView)
        }
    }
    
    @IBAction func questionAction(_ sender: Any) {
        handleTipView()
    }
}
