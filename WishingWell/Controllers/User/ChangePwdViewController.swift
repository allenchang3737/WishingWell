//
//  ChangePwdViewController.swift
//  TheWayToBasketball
//
//  Created by Lun YU Chang on 2019/7/13.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit

class ChangePwdViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var oldPwdForm: LUNTextFieldView!
    @IBOutlet weak var newPwdForm: LUNTextFieldView!
    @IBOutlet weak var confirmForm: LUNTextFieldView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(scrollview)
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotifications()
        showNavigationBar()
        hideTabBar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
    }

    func setupLayout() {
        //New Password
        oldPwdForm.titleLbl.text = "Old password".localized()
        oldPwdForm.textField.placeholder = "Old password".localized()
        oldPwdForm.textField.isSecureTextEntry = true
        oldPwdForm.textField.returnKeyType = .next
        oldPwdForm.textField.delegate = self
        
        //New Password
        newPwdForm.titleLbl.text = "New password".localized()
        newPwdForm.textField.placeholder = "New password".localized()
        newPwdForm.textField.isSecureTextEntry = true
        newPwdForm.textField.returnKeyType = .next
        newPwdForm.textField.delegate = self
        
        //Confirm Password
        confirmForm.titleLbl.text = "Password check".localized()
        confirmForm.textField.placeholder = "Password check".localized()
        confirmForm.textField.isSecureTextEntry = true
        confirmForm.textField.returnKeyType = .done
        confirmForm.textField.delegate = self
        
        buttonview.button.setTitle("Confirm".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    func validateTextField() -> Bool {
        if !isPasswordValid(oldPwdForm.textField.text) {
            oldPwdForm.showErrorMessage(message: "Input old password".localized())
            return false
        }
        
        if !isPasswordValid(newPwdForm.textField.text) {
            newPwdForm.showErrorMessage(message: "Input new password".localized())
            return false
        }
        
        if newPwdForm.textField.text != confirmForm.textField.text {
            confirmForm.showErrorMessage(message: "Input password check".localized())
            return false
        }
        
        return true
    }
    
    @objc func confirmAction() {
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateTextField() {
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                self.showActivityIndicator()
                UserService.shared.changePwd(oldPwd: self.oldPwdForm.textField.text ?? "",
                                             newPwd: self.newPwdForm.textField.text ?? "") {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(),
                                   message: "Update successfully".localized()) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

//MARK: KeyboardNotifications
extension ChangePwdViewController {
    func registerKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWasShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardNotifications () {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let duration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double

            UIView.animate(withDuration: duration) {
                self.scrollview.contentInset = UIEdgeInsets(top: self.scrollview.contentInset.top, left: 0, bottom: keyboardFrame.size.height, right: 0)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollview.contentInset = contentInsets
        scrollview.scrollIndicatorInsets = contentInsets
    }
}

//MARK: UITextFieldDelegate
extension ChangePwdViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case oldPwdForm.textField:
            oldPwdForm.inactive()
            
        case newPwdForm.textField:
            newPwdForm.inactive()
       
        case confirmForm.textField:
            confirmForm.inactive()
        
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case oldPwdForm.textField:
            oldPwdForm.deactive()
            
        case newPwdForm.textField:
            newPwdForm.deactive()
        
        case confirmForm.textField:
            confirmForm.deactive()
        
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case oldPwdForm.textField:
            oldPwdForm.deactive()
            newPwdForm.textField.becomeFirstResponder()
            
        case newPwdForm.textField:
            newPwdForm.deactive()
            confirmForm.textField.becomeFirstResponder()
        
        case confirmForm.textField:
            confirmForm.deactive()
            textField.resignFirstResponder()
        
        default:
            break
        }
        return false
    }
}
