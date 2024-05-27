//
//  LUNTextViewController.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/27.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import MobileCoreServices

class LUNTextViewController: UIViewController {
    @IBOutlet weak var limitLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    @IBOutlet var accessoryview: UIView!
    @IBOutlet weak var accessoryBtn: UIButton!
    var toolBar = UIToolbar()
    
    //Configuration
    private var indexPath: IndexPath?
    private var titleText: String?
    private var placeholder: String?
    private var textLimit: Int?
    
    var resultText: String?
    var completionHandler: ((_ indexPath: IndexPath?, _ text: String?) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(self.view)
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotifications()
        showNavigationBar()
        hideTabBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
    }
    
    func configure(indexPath: IndexPath?, titleText: String?, placeholder: String?, textLimit: Int?) {
        self.indexPath = indexPath
        self.titleText = titleText
        self.placeholder = placeholder
        self.textLimit = textLimit
    }
    
    func setupLayout() {
        //limit
        if let limit = self.textLimit {
            limitLbl.text = "Text limit".localized() + " (\(limit))"
        }else {
            limitLbl.text = nil
        }
        
        //Title
        titleLbl.text = titleText
        
        //Text View
        textview.delegate = self
        textview.isUserInteractionEnabled = true
        if let text = self.resultText,
           !text.isEmpty {
            textview.text = text
            textview.textColor = .label
            
        }else {
            textview.text = self.placeholder
            textview.textColor = .lightGray
        }
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        //Accessory View
        textview.inputAccessoryView = accessoryview
        accessoryBtn.setTitle("Confirm".localized(), for: .normal)
        accessoryBtn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        
        //Button View
        buttonview.button.setTitle("Confirm".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    func validateTextView() -> Bool {
        if textview.text == placeholder || textview.text.isEmpty {
            self.resultText = nil
            self.showAlert(title: nil, message: self.placeholder ?? "")
            return false
        
        }else {
            self.resultText = textview.text
            return true
        }
    }
    
    //MARK: Action
    @objc func confirmAction() {
        self.view.endEditing(true)
        
        if validateTextView() {
            completionHandler?(self.indexPath, self.resultText)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

//MARK: Keyboard
extension LUNTextViewController {
    func registerKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWasShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let duration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let padding: CGFloat = getPadding()
            
            UIView.animate(withDuration: duration) {
                self.textview.contentInset = UIEdgeInsets(top: self.textview.contentInset.top, left: 0, bottom: keyboardFrame.size.height + padding, right: 0)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        self.textview.contentInset = contentInsets
        self.textview.scrollIndicatorInsets = contentInsets
    }
    
    func removeKeyboardNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIWindow.keyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
    }
}

//MARK: UITextViewDelegate
extension LUNTextViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let limit = self.textLimit {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            let numberOfChars = newText.count
            return numberOfChars <= limit
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = self.placeholder
            textView.textColor = .lightGray
        }
    }
}
