//
//  ForgetPwdStep1ViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import UIKit

class ForgetPwdStep1ViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var accountForm: LUNTextFieldView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(scrollview)
        setupBarButton()
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
    
    func setupBarButton() {
        let image = UIImage(systemName: "chevron.backward")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        let backBtn = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(backAction))
        self.navigationItem.leftBarButtonItem = backBtn
    }
    
    func setupLayout() {
        //Account
        accountForm.titleLbl.text = "Forget password".localized()
        accountForm.textField.placeholder = "Log in information".localized()
        accountForm.textField.keyboardType = .emailAddress
        accountForm.textField.delegate = self
        
        buttonview.button.setTitle("Confirm".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    func validateTextField() -> Bool {
        if isEmailValid(accountForm.textField.text) {
            return true
        
        }else if isAccountValid(accountForm.textField.text) {
            return true
            
        }else if isPhoneValid(accountForm.textField.text) {
            return true
            
        }else {
            accountForm.showErrorMessage(message: "Input log in information".localized())
            return false
        }
    }
    
    func gotoOTPView(userInfo: String) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        otpVC.type = .USER
        otpVC.userInfo = userInfo
        otpVC.completionHandler = { (success, token) in
            if success,
               let token = token {
                self.gotoForgetPwdStep2View(token: token)
  
            }else {
                print("Verify OTP Failed...")
            }
        }
        otpVC.modalPresentationStyle = .overCurrentContext
        self.present(otpVC, animated: true, completion: nil)
    }
    
    func gotoForgetPwdStep2View(token: String) {
        let forgetPwdStep2VC = ForgetPwdStep2ViewController(nibName: "ForgetPwdStep2ViewController", bundle: nil)
        forgetPwdStep2VC.token = token
        self.navigationController?.pushViewController(forgetPwdStep2VC, animated: true)
    }
    
    //MARK: Action
    @objc func backAction() {
        self.dismiss(animated: true)
    }
    
    @objc func confirmAction() {
        if validateTextField() {
            gotoOTPView(userInfo: accountForm.textField.text ?? "")
        }
    }
}

//MARK: Keyboard
extension ForgetPwdStep1ViewController {
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
extension ForgetPwdStep1ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.inactive()
            
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.deactive()
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case accountForm.textField:
            accountForm.deactive()
            textField.resignFirstResponder()
            
        default:
            break
        }
        return false
    }
}
