//
//  LoginViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/17.
//

import UIKit
import AuthenticationServices

class LoginViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    
    @IBOutlet weak var accountForm: LUNTextFieldView!
    @IBOutlet weak var passwordForm: LUNTextFieldView!
    @IBOutlet weak var loginBtn: UIButton!
    
    @IBOutlet weak var loginBtnStackView: UIStackView!
    @IBOutlet weak var googleBtn: UIButton!
    @IBOutlet weak var facebookBtn: UIButton!
    
    var completionHandler: ((_ success: Bool) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(self.contentView)
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        hideTabBar()
    }
    
    func setupLayout() {
        //Account
        accountForm.titleLbl.isHidden = true
        accountForm.textField.placeholder = "Log in information".localized()
        accountForm.textField.returnKeyType = .next
        accountForm.textField.delegate = self
        
        //Password
        passwordForm.titleLbl.isHidden = true
        passwordForm.textField.placeholder = "Password".localized()
        passwordForm.textField.isSecureTextEntry = true
        passwordForm.textField.returnKeyType = .done
        passwordForm.textField.delegate = self
        
        //Login Buttons
        loginBtn.setTitle("Log in".localized(), for: .normal)
        googleBtn.setTitle("Sign in with Google".localized(), for: .normal)
        facebookBtn.setTitle("Sign in with Facebook".localized(), for: .normal)
        //Apple
        let appleBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .default,
                                                    authorizationButtonStyle: .whiteOutline)
        (appleBtn as UIControl).cornerRadius = 20.0
        appleBtn.heightAnchor.constraint(equalToConstant: CGFloat(40)).isActive = true
        appleBtn.addTarget(self, action: #selector(appleAction), for: .touchUpInside)
        loginBtnStackView.addArrangedSubview(appleBtn)
    }
    
    func validateTextField() -> Bool {
        if isEmptyValid(accountForm.textField.text) {
            accountForm.showErrorMessage(message: "Input log in information".localized())
            return false
        }
        
        if !isPasswordValid(passwordForm.textField.text) {
            passwordForm.showErrorMessage(message: "Input password" .localized())
            return false
        }
        
        return true
    }
    
    func gotoSignUpView(authType: AuthType, authUserId: String?, email: String?) {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        signUpVC.authType = authType
        signUpVC.authUserId = authUserId
        signUpVC.email = email
        signUpVC.delegate = self
        
        let nav = UINavigationController(rootViewController: signUpVC)
        nav.modalPresentationStyle = .overFullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    func gotoForgetPwdStep1View() {
        let forgetPwdStep1VC = ForgetPwdStep1ViewController(nibName: "ForgetPwdStep1ViewController", bundle: nil)
        
        let nav = UINavigationController(rootViewController: forgetPwdStep1VC)
        nav.modalPresentationStyle = .overFullScreen
        self.present(nav, animated: true, completion: nil)
    }

    //MARK: Action
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
        completionHandler?(false)
    }
    
    @IBAction func loginAction(_ sender: Any) {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateTextField() {
            self.login(authType: .ACCOUNT,
                       account: accountForm.textField.text,
                       password: passwordForm.textField.text,
                       authUserId: nil)
        }
    }
    
    @IBAction func forgetAction(_ sender: Any) {
        gotoForgetPwdStep1View()
    }
    
    @IBAction func signUpAction(_ sender: Any) {
        gotoSignUpView(authType: .ACCOUNT, authUserId: nil, email: nil)
    }
    
    @IBAction func googleAction(_ sender: Any) {
#if DEV
        self.gotoSignUpView(authType: .GOOGLE, authUserId: "test", email: "test@test.com")
#else
        //TODO: API
#endif
    }
    
    @IBAction func facebookAction(_ sender: Any) {
#if DEV
        self.gotoSignUpView(authType: .FACEBOOK, authUserId: "test", email: "test@test.com")
#else
        //TODO: API
#endif
    }
    
    @objc func appleAction() {
#if DEV
        self.gotoSignUpView(authType: .APPLE, authUserId: "test", email: "test@test.com")
#else
        //TODO: API
#endif
    }
}

//MARK: SignUpViewControllerDelegate
extension LoginViewController: SignUpViewControllerDelegate {
    func didSuccess(authType: AuthType, account: String?, password: String?, authUserId: String?) {
        self.login(authType: authType,
                   account: account,
                   password: password, 
                   authUserId: authUserId)
    }
}

//MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.inactive()
       
        case passwordForm.textField:
            passwordForm.inactive()
        
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.deactive()
        
        case passwordForm.textField:
            passwordForm.deactive()
        
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case accountForm.textField:
            accountForm.deactive()
            passwordForm.textField.becomeFirstResponder()
        
        case passwordForm.textField:
            passwordForm.deactive()
            textField.resignFirstResponder()
        
        default:
            break
        }
        return false
    }
}

//MARK: Server
extension LoginViewController {
    func login(authType: AuthType, account: String?, password: String?, authUserId: String?) {
        self.showActivityIndicator()
        UserService.shared.login(authType: authType,
                                 account: account,
                                 password: password,
                                 authUserId: authUserId) { isNotExist in
            if isNotExist {
                self.gotoSignUpView(authType: .ACCOUNT, authUserId: nil, email: nil)
                
            }else {
                self.dismiss(animated: true)
                self.completionHandler?(true)
            }
            self.hideActivityIndicator()
        }
    }
}
