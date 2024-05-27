//
//  ForgetPwdStep2ViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/19.
//

import UIKit

class ForgetPwdStep2ViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var newPwdForm: LUNTextFieldView!
    @IBOutlet weak var confirmForm: LUNTextFieldView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    //Configuration
    var token: String = ""
    
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
            self.showActivityIndicator()
            UserService.shared.forgetPwd(token: self.token,
                                         password: self.newPwdForm.textField.text ?? "") {
                self.hideActivityIndicator()
                self.showAlert(title: "Congratulation".localized(), 
                               message: "Update successfully".localized()) {
                    //Forget Password: UI flow 是建立新的 navigationController
                    self.navigationController?.dismiss(animated: true)
                }
            }
        }
    }
}

//MARK: Keyboard
extension ForgetPwdStep2ViewController {
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
extension ForgetPwdStep2ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
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
