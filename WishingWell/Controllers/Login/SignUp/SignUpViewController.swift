//
//  SignUpViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import UIKit
import YPImagePicker

protocol SignUpViewControllerDelegate {
    //ACCOUNT: account, password
    //FACEBOOK, GOOGLE, APPLE: authUserId
    func didSuccess(authType: AuthType, account: String?, password: String?, authUserId: String?)
}

class SignUpViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountForm: LUNTextFieldView!
    @IBOutlet weak var emailForm: LUNTextFieldView!
    @IBOutlet weak var passwordForm: LUNTextFieldView!
    @IBOutlet weak var confirmForm: LUNTextFieldView!
    @IBOutlet weak var buttonview: LUNButtonView!
    @IBOutlet weak var authImageView: UIImageView!
    @IBOutlet weak var noteTextView: UITextView!
    
    //Configuration
    var authType: AuthType = .ACCOUNT
    var authUserId: String?
    var email: String?
    
    //Data
    var selectedImage: UIImage? {
        didSet {
            self.userImageView.image = self.selectedImage
        }
    }
    
    var delegate: SignUpViewControllerDelegate?
    
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
        userImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(photoPickerAction))
        userImageView.addGestureRecognizer(tap)
        
        //Account
        accountForm.titleLbl.text = "Account".localized()
        accountForm.textField.placeholder = "Account".localized()
        accountForm.textField.keyboardType = .default
        accountForm.textField.returnKeyType = .next
        accountForm.textField.delegate = self
        
        //Email
        emailForm.titleLbl.text = "Email".localized()
        emailForm.textField.text = self.email
        emailForm.textField.placeholder = "Email".localized()
        emailForm.textField.keyboardType = .emailAddress
        emailForm.textField.returnKeyType = .next
        emailForm.textField.delegate = self
        
        //Password
        passwordForm.titleLbl.text = "Password".localized()
        passwordForm.textField.placeholder = "Password".localized()
        passwordForm.textField.isSecureTextEntry = true
        passwordForm.textField.keyboardType = .default
        passwordForm.textField.returnKeyType = .next
        passwordForm.textField.delegate = self
        
        //Confirm Password
        confirmForm.titleLbl.text = "Password check".localized()
        confirmForm.textField.placeholder = "Password check".localized()
        confirmForm.textField.isSecureTextEntry = true
        confirmForm.textField.keyboardType = .default
        confirmForm.textField.delegate = self
        
        passwordForm.isHidden = authType == .ACCOUNT ? false : true
        confirmForm.isHidden = authType == .ACCOUNT ? false : true
        emailForm.isHidden = authType == .APPLE ? true : false      //For Apple rejected: Apple登入不可要求用戶輸入email
        
        switch authType {
        case .ACCOUNT:
            authImageView.isHidden = true
            
        case .FACEBOOK:
            let image = UIImage(named: "facebook_24")
            authImageView.image = image
            
        case .GOOGLE:
            let image = UIImage(named: "google_24")
            authImageView.image = image
            
        case .APPLE:
            let image = UIImage(systemName: "applelogo")?.withRenderingMode(.alwaysTemplate)
            authImageView.tintColor = .label
            authImageView.image = image
        }
        
        //Note
        let attributedString = NSMutableAttributedString(string: "By signing up, you agree to our".localized(),
                                                         attributes: [.foregroundColor: UIColor.label])
        let selectablePart = NSMutableAttributedString(string: "Terms of Service and Privacy Policy".localized())
        let length = selectablePart.length
        selectablePart.addAttribute(.underlineStyle,
                                    value: 1,
                                    range: NSRange(location: 0, length: length))
        selectablePart.addAttribute(.link,
                                    value: "OpenWebLink",
                                    range: NSRange(location: 0,length: length))
        attributedString.append(selectablePart)
        noteTextView.attributedText = attributedString
        noteTextView.delegate = self
        noteTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        //Button View
        buttonview.button.setTitle("Confirm".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    func validateTextField() -> Bool {
        if !isAccountValid(accountForm.textField.text) {
            accountForm.showErrorMessage(message: "Input account".localized())
            return false
        }
        
        if self.authType != .APPLE, //For Apple rejected: Apple登入不可要求用戶輸入email
           !isEmailValid(emailForm.textField.text) {
            emailForm.showErrorMessage(message: "Input email".localized())
            return false
        }
        
        //Check Password
        if authType == .ACCOUNT {
            if !isPasswordValid(passwordForm.textField.text) {
                passwordForm.showErrorMessage(message: "Input password".localized())
                return false
            }
            
            if passwordForm.textField.text != confirmForm.textField.text {
                confirmForm.showErrorMessage(message: "Input password check".localized())
                return false
            }
        }
        
        return true
    }
    
    func openImagePicker() {
        var config = YPImagePickerConfiguration()
        config.onlySquareImagesFromCamera = false
        config.startOnScreen = YPPickerScreen.library
        
        let picker = YPImagePicker(configuration: config)
        //issue: YPImagePicker會導致NavigationBar跑版，必須設定modalPresentationStyle
        picker.modalPresentationStyle = .overFullScreen
        picker.didFinishPicking { [unowned picker] items, _ in
            if let photo = items.singlePhoto {
                self.selectedImage = photo.image
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func showTNC() {
        guard let tncUrl = AppConfigService.shared.config?.tncUrl,
              let url = URL(string: tncUrl) else { return }
        self.showLUNWebView(url: url)
    }
    
    //MARK: Action
    @objc func backAction() {
        self.dismiss(animated: true)
    }
    
    @objc func photoPickerAction() {
        let manager = PermissionsManager()
        manager.requestPermission(.photoLibrary) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.openImagePicker()
                
                }else {
                    self.showOpenSetting(title: nil, message: "Open camera permission".localized())
                }
            }
        }
    }
    
    @objc func confirmAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateTextField() {
            //註冊用戶資料
            //上傳圖片
            self.showActivityIndicator()
            UserService.shared.signUp(authType: self.authType,
                                      account: accountForm.textField.text ?? "",
                                      email: emailForm.textField.text,
                                      password: passwordForm.textField.text,
                                      authUserId: self.authUserId) { userId in
                let dispatchGroup = DispatchGroup()
                
                if let image = self.selectedImage {
                    let file = File(customId: userId, type: .USER)
                    dispatchGroup.enter()
                    FileService.shared.uploadImage(file: file, image: image) {
                        print("Upload image successfully...")
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(),
                                   message: "Create successfully".localized()) {
                        self.dismiss(animated: true)
                        self.delegate?.didSuccess(authType: self.authType,
                                                  account: self.accountForm.textField.text ?? "",
                                                  password: self.passwordForm.textField.text,
                                                  authUserId: self.authUserId)
                    }
                }
            }
        }
    }
}

//MARK: Keyboard
extension SignUpViewController {
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
extension SignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //用戶名稱轉換小寫
        if textField == accountForm.textField {
            textField.text = textField.text?.lowercased()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.inactive()
        
        case emailForm.textField:
            emailForm.inactive()
        
        case passwordForm.textField:
            passwordForm.inactive()
        
        case confirmForm.textField:
            confirmForm.inactive()
        
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            //用戶名稱轉換小寫
            textField.text = textField.text?.lowercased()
            accountForm.deactive()
        
        case emailForm.textField:
            emailForm.deactive()
        
        case passwordForm.textField:
            passwordForm.deactive()
        
        case confirmForm.textField:
            confirmForm.deactive()
        
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case accountForm.textField:
            accountForm.deactive()
            emailForm.textField.becomeFirstResponder()
        
        case emailForm.textField:
            emailForm.deactive()
            passwordForm.textField.becomeFirstResponder()
       
        case passwordForm.textField:
            passwordForm.deactive()
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

//MARK: UITextViewDelegate
extension SignUpViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.showTNC()
        return false
    }
}
