//
//  OTPViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import UIKit
import CountdownLabel

class OTPViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var infoForm: LUNTextFieldView!
    @IBOutlet weak var otpForm: LUNTextFieldView!
    @IBOutlet weak var resendBtn: UIButton!
    @IBOutlet weak var countdownLbl: CountdownLabel!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    //Configuration
    var type: OTPType = .USER
    var userInfo: String = ""
    var userId = UserService.shared.currentUser?.userId
    
    //Data
    var expiryTime: Int?
    var token: String?
    
    var completionHandler: ((_ success: Bool, _ token: String?) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hideKeyboardWhenTappedAround(scrollview)
        setupLayout()
        
        if self.type == .USER {
            generateOTP()
        }
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
        //Info Form
        switch self.type {
        case .USER:
            infoForm.titleLbl.text = ""
            
        case .EMAIL:
            infoForm.titleLbl.text = "Email".localized()
            infoForm.textField.placeholder = "Email".localized()
            infoForm.textField.keyboardType = .emailAddress
            
        case .PHONE:
            infoForm.titleLbl.text = "Phone".localized()
            infoForm.textField.placeholder = "Phone".localized()
            infoForm.textField.keyboardType = .phonePad
        }
        infoForm.textField.text = self.userInfo
        infoForm.textField.delegate = self
        
        //OTP Form
        otpForm.titleLbl.text = "OTP".localized()
        otpForm.textField.placeholder = "OTP".localized()
        otpForm.textField.keyboardType = .numberPad
        otpForm.textField.returnKeyType = .done
        otpForm.textField.delegate = self
        if #available(iOS 12.0, *) {
            otpForm.textField.textContentType = .oneTimeCode
        } else {
            // Fallback on earlier versions
        }
        
        //Resend Button
        resendBtn.setTitle("Resend OTP".localized(), for: .normal)
        resendBtn.isEnabled = false
        
        //Countdown Label
        countdownLbl.countdownDelegate = self
        
        checkOTP(isGenerated: false)
        if self.type == .USER {
            infoForm.textField.isEnabled = false
        }
    }
    
    func setExpiryTime() {
        let time = self.expiryTime ?? 60 * 5   //default 5 min
        setCountdownLabel(time)
    }
    
    func setCountdownLabel(_ expiryTime: Int) {
        countdownLbl.timeFormat = "mm:ss"
        countdownLbl.setCountDownTime(minutes: Double(expiryTime))
        countdownLbl.start()
    }
    
    func checkOTP(isGenerated: Bool) {
        infoForm.textField.isEnabled = !isGenerated
        otpForm.isHidden = !isGenerated
        resendBtn.isHidden = !isGenerated
        countdownLbl.isHidden = !isGenerated
        
        //Button View
        buttonview.button.removeTarget(nil, action: nil, for: .allEvents)
        if isGenerated {
            buttonview.button.setTitle("Verify".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(verifyAction), for: .touchUpInside)
            
        }else {
            buttonview.button.setTitle("Confirm".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(generateAction), for: .touchUpInside)
        }
        
        switch self.type {
        case.USER:
            if isGenerated {
                titleLbl.text = "User auth send".localized()
            }else {
                titleLbl.text = "User auth, we will send OTP".localized()
            }
            
        case .EMAIL:
            if isGenerated {
                titleLbl.text = "Email OTP send".localized() + self.userInfo
            }else {
                titleLbl.text = "Edit email, we will send OTP".localized()
            }
            
        case .PHONE:
            if isGenerated {
                titleLbl.text = "Phone OTP send".localized() + self.userInfo
            }else {
                titleLbl.text = "Edit phone, we will send OTP".localized()
            }
        }
    }
    
    func validateUserInfo() -> Bool {
        switch self.type {
        case .EMAIL:
            if !isEmailValid(infoForm.textField.text) {
                infoForm.showErrorMessage(message: "Input email".localized())
                return false
            
            }else {
                self.userInfo = infoForm.textField.text ?? ""
            }
            
        case .PHONE:
            if !isPhoneValid(infoForm.textField.text) {
                infoForm.showErrorMessage(message: "Input phone".localized())
                return false
            
            }else {
                self.userInfo = infoForm.textField.text ?? ""
            }
            
        default:
            break
        }
        return true
    }
    
    func validateOTP() -> Bool {
        if isEmptyValid(otpForm.textField.text) {
            otpForm.showErrorMessage(message: "Input OTP".localized())
            return false
        }
        return true
    }
    
    //MARK: Action
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
        completionHandler?(false, nil)
    }
    
    @objc func generateAction() {
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateUserInfo() {
            self.generateOTP()
        }
    }
    
    @objc func verifyAction() {
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateOTP() {
            self.verifyOTP()
        }
    }
    
    @IBAction func resendAction(_ sender: Any) {
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        self.resendOTP()
    }
}

//MARK: Keyboard
extension OTPViewController {
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

//MARK: CountdownLabelDelegate
extension OTPViewController: CountdownLabelDelegate {
    func countdownStarted() {
        resendBtn.isEnabled = false
    }
    
    func countdownFinished() {
        resendBtn.isEnabled = true
    }
}

//MARK: UITextFieldDelegate
extension OTPViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case infoForm.textField:
            infoForm.inactive()
            
        case otpForm.textField:
            otpForm.inactive()
            
        default:
            break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case infoForm.textField:
            infoForm.deactive()
            
        case otpForm.textField:
            otpForm.deactive()
            
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case infoForm.textField:
            infoForm.deactive()
            otpForm.textField.becomeFirstResponder()
            
        case otpForm.textField:
            otpForm.deactive()
            textField.resignFirstResponder()
            
        default:
            break
        }
        return false
    }
}

//MARK: Server
extension OTPViewController {
    func generateOTP() {
        guard !self.userInfo.isEmpty else { return }
        let rq = GenerateOTPRq(userInfo: self.userInfo,
                               otpType: self.type.rawValue,
                               userId: self.userId)
        
        self.showActivityIndicator()
        OTPService.shared.generateOTP(rq: rq) { response in
            self.token = response.token
            self.expiryTime = response.expiryTime
            self.setExpiryTime()
            
            self.checkOTP(isGenerated: true)
            self.hideActivityIndicator()
        }
    }
    
    func verifyOTP() {
        guard let otp = otpForm.textField.text,
              let token = self.token else { return }
        
        self.showActivityIndicator()
        OTPService.shared.verifyOTP(otpCode: otp, token: token) {
            switch self.type {
            case .EMAIL:
                UserService.shared.currentUser?.email = self.userInfo
                UserService.shared.currentUser?.emailVerified = true
                
            case .PHONE:
                UserService.shared.currentUser?.phone = self.userInfo
                UserService.shared.currentUser?.phoneVerified = true
                
            default:
                break
            }
            self.completionHandler?(true, token)
            self.dismiss(animated: true, completion: nil)
            self.hideActivityIndicator()
        }
    }
    
    func resendOTP() {
        guard let token = self.token else { return }
        
        self.showActivityIndicator()
        OTPService.shared.resendOTP(token: token) {
            self.otpForm.textField.text = nil
            self.setExpiryTime()
            self.hideActivityIndicator()
        }
    }
}
