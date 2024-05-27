//
//  UserEditViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/24.
//

import UIKit
import YPImagePicker

class UserEditViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountForm: LUNTextFieldView!
    @IBOutlet weak var emailForm: LUNTextFieldView!
    @IBOutlet weak var phoneForm: LUNTextFieldView!
    @IBOutlet weak var introLbl: UILabel!
    @IBOutlet weak var introTextView: UITextView!
    
    @IBOutlet weak var authImageView: UIImageView!
    
    @IBOutlet weak var buttonview: LUNButtonView!

    //Configuration
    var currentUser: User?
    
    //Data
    var selectedImage: UIImage? {
        didSet {
            self.userImageView.image = self.selectedImage
        }
    }
    
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
        let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(moreAction(_:)))
        navigationItem.rightBarButtonItem = moreBtn
    }
    
    func setupLayout() {
        //User Image
        if let fileId = self.currentUser?.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId {
            FileService.shared.getImage(fileId: fileId) { image in
                self.userImageView.image = image
            }
        }
        userImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(photoPickerAction))
        userImageView.addGestureRecognizer(tap)
        
        //Account
        accountForm.titleLbl.text = "Account".localized()
        accountForm.textField.text = self.currentUser?.account
        accountForm.textField.isEnabled = false
        
        //Email
        emailForm.titleLbl.text = "Email".localized()
        emailForm.textField.text = self.currentUser?.email
        emailForm.textField.placeholder = "Email".localized()
        emailForm.textField.keyboardType = .emailAddress
        emailForm.textField.returnKeyType = .next
        emailForm.textField.delegate = self
        
        //Phone
        phoneForm.titleLbl.text = "Phone".localized()
        phoneForm.textField.text = self.currentUser?.phone
        phoneForm.textField.placeholder = "Phone".localized()
        phoneForm.textField.keyboardType = .numberPad
        phoneForm.textField.returnKeyType = .done
        phoneForm.textField.delegate = self

        //Intro
        introLbl.text = "User intro".localized()
        introTextView.text = self.currentUser?.intro
        introTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        //Verified
        checkVerified()
        
        //Auth Type
        let type = AuthType(rawValue: self.currentUser?.authType ?? "")
        switch type {
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
            
        default:
            authImageView.isHidden = true
        }
        
        //Button View
        buttonview.button.setTitle("Update".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
    }
    
    func checkVerified() {
        if let isVerified = self.currentUser?.emailVerified,
           isVerified {
            let image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            emailForm.questionBtn.isHidden = false
            emailForm.questionBtn.setImage(image, for: .normal)
        }
        
        if let isVerified = self.currentUser?.phoneVerified,
           isVerified {
            let image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
            phoneForm.questionBtn.isHidden = false
            phoneForm.questionBtn.setImage(image, for: .normal)
        }
    }
    
    func validateTextField() -> Bool {
        //Email: 不可空白
        if !isEmailValid(emailForm.textField.text) {
            emailForm.showErrorMessage(message: "Input email".localized())
            return false
        }
        self.currentUser?.email = emailForm.textField.text ?? ""
        
        //Phone: 可以空白
        if let text = phoneForm.textField.text,
           !text.isEmpty,
           !isPhoneValid(text) {
            phoneForm.showErrorMessage(message: "Input phone".localized())
            return false
        }
        self.currentUser?.phone = phoneForm.textField.text
        
        //Intro: 可以空白
        self.currentUser?.intro = introTextView.text
        
        print("--------------------------------------------------")
        print("New current user: \(self.currentUser)")
        print("--------------------------------------------------")
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
    
    func showMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let delete = UIAlertAction(title: "Delete user".localized(), style: .destructive) { action in
            self.deleteUser()
        }
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(delete)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func gotoOTPView(type: OTPType, userInfo: String) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        otpVC.type = type
        otpVC.userInfo = userInfo
        otpVC.completionHandler = { (success, token) in
            if success {
                self.currentUser = UserService.shared.currentUser
                self.buttonview.button.removeTarget(nil, action: nil, for: .allEvents)
                self.setupLayout()
  
            }else {
                print("Verify OTP Failed...\(type)")
            }
        }
        otpVC.modalPresentationStyle = .overCurrentContext
        self.present(otpVC, animated: true, completion: nil)
    }
    
    //MARK: Action
    @objc func moreAction(_ sender: UIButton) {
        showMoreAlert(sender)
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
    
    @objc func updateAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateTextField() {
            //更新用戶資料
            //上傳圖片
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                guard let user = self.currentUser else { return }
                self.showActivityIndicator()
                let dispatchGroup = DispatchGroup()
                
                if let image = self.selectedImage {
                    let file = File(customId: user.userId, type: .USER)
                    dispatchGroup.enter()
                    FileService.shared.uploadImage(file: file, image: image) {
                        print("Upload image successfully...")
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.enter()
                UserService.shared.updateCurrentUser(user: user) {
                    print("updateCurrentUser successfully...")
                    dispatchGroup.leave()
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(),
                                   message: "Update successfully".localized())
                }
            }
        }
    }
}

//MARK: Keyboard
extension UserEditViewController {
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
extension UserEditViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //用戶名稱轉換小寫
        if textField == accountForm.textField {
            textField.text = textField.text?.lowercased()
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case emailForm.textField:
            if let isVerified = self.currentUser?.emailVerified,
               isVerified {
                gotoOTPView(type: .EMAIL, userInfo: self.currentUser?.email ?? "")
                return false
            }
            
        case phoneForm.textField:
            if let isVerified = self.currentUser?.phoneVerified,
               isVerified {
                gotoOTPView(type: .PHONE, userInfo: self.currentUser?.phone ?? "")
                return false
            }
            
        default:
            break
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case accountForm.textField:
            accountForm.inactive()
        
        case emailForm.textField:
            emailForm.inactive()
        
        case phoneForm.textField:
            phoneForm.inactive()
        
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
        
        case phoneForm.textField:
            phoneForm.deactive()
        
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
            phoneForm.textField.becomeFirstResponder()
        
        case phoneForm.textField:
            phoneForm.deactive()
            textField.resignFirstResponder()
        
        default:
            break
        }
        return false
    }
}

//MARK: Server
extension UserEditViewController {
    func deleteUser() {
        showAlert(title: "Confirm delete?".localized(), message: "Delete user message".localized(), showCancel: true) {
            self.showActivityIndicator()
            UserService.shared.deleteCurrentUser {
                self.hideActivityIndicator()
                self.showAlert(title: nil, message: "Delete successfully".localized()) {
                    self.tabBarController?.selectedIndex = 0
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}
