//
//  LUNTextFieldView.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/4/26.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class LUNTextField: UITextField {
    var textPadding = UIEdgeInsets(top: 5,
                                   left: 8,
                                   bottom: 5,
                                   right: 8)
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
    
    func addTextFieldBorder(color: UIColor) {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 8.0
        self.layer.borderWidth = 0.25
        self.layer.borderColor = color.cgColor
    }
}

class LUNTextFieldView: UIView {
    @IBOutlet var contentview: UIView!
    @IBOutlet weak var titleLbl: UILabel! {
        didSet {
            self.titleLbl.alpha = 1
        }
    }
    @IBOutlet weak var textField: LUNTextField!
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var questionBtn: UIButton!
    
    //MARK: Left Icon Image
    public var leftImageIsCircle: Bool = false
    public var leftImage: UIImage? {
        didSet {
            if let image = leftImage {
                var padding: CGFloat = 56 //圖片和文字間隔
                let leftImageView = UIImageView(image: image)
                leftImageView.contentMode = .scaleAspectFill
                leftImageView.clipsToBounds = true
                if leftImageIsCircle {
                    leftImageView.frame = CGRect(x: 16, y: 0, width: 28, height: 28)
                    leftImageView.circleCorner = true
                    padding = 50
                
                }else {
                    leftImageView.frame = CGRect(x: 0, y: 0, width: 38, height: 24)
                }
                
                //Padding
                let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 24))
                paddingView.addSubview(leftImageView)
                
                textField.leftView = paddingView
                textField.leftViewMode = .always
           
            }else {
                textField.leftView = nil
            }
        }
    }
    
    //MARK: Right Button
    var rightButton: UIButton = UIButton(type: .system)
    public var rightIconName: String? {
        didSet {
            guard let iconName = rightIconName else { return }
            let padding: CGFloat = 16 //圖片和文字間隔
            
            let image = UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal)
            rightButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            rightButton.setImage(image, for: .normal)
            
            //Padding
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: 20))
            paddingView.addSubview(rightButton)
            
            textField.rightView = paddingView
            textField.rightViewMode = .always
        }
    }
    
    //MARK: Animated Setting
    private var animated: Bool = true
    public private(set) var animationDuration: Double = 1.0
    
    private var errorMessage: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initializeView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initializeView()
    }
    
    private func initializeView() {
        backgroundColor = .clear
        
        //Load Nib
        self.contentview = loadNib()
        self.contentview.frame = bounds
        addSubview(contentview)
        
        errorLbl.text = ""
    }
    
    //MARK: Error message
    func showErrorMessage(message: String) {
        errorMessage = message
        textField.becomeFirstResponder()
        perform(#selector(errorAnimated))
    }
    
    @objc func errorAnimated() {
        errorLbl.text = errorMessage
        titleLbl.textColor = .systemRed
        textField.addTextFieldBorder(color: .systemRed)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                self.titleLbl.alpha = 1
            }, completion: nil)
        }
    }
    
    private func hideErrorMessage() {
        errorMessage = ""
        errorLbl.text = ""
        titleLbl.textColor = .darkGray
        textField.addTextFieldBorder(color: .placeholderText)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                self.titleLbl.alpha = 0
            }, completion: nil)
        }
    }
    
    public func inactive() {
        if errorMessage.isEmpty {
            hideErrorMessage()
            titleLbl.textColor = .systemBlue
            textField.addTextFieldBorder(color: .systemBlue)
            
            if animated {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                    self.titleLbl.alpha = 1
                })
            }
        
        }else {
            return
        }
    }
    
    public func deactive() {
        hideErrorMessage()
        titleLbl.textColor = .darkGray
        textField.addTextFieldBorder(color: .placeholderText)
        
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [.transitionCrossDissolve], animations: {
                if self.textField.text?.count == 0 {
                    self.titleLbl.alpha = 0
                
                }else {
                    self.titleLbl.alpha = 1
                }
            }, completion: nil)
        }
    }
}
