//
//  ReportViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/21.
//

import UIKit

class ReportViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var typePickerView: UIPickerView!
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    @IBOutlet var accessoryview: UIView!
    @IBOutlet weak var accessoryBtn: UIButton!
    
    //Configuration
    var receiverUserId: Int?
    var senderUserId: Int? = UserService.shared.currentUser?.userId
    
    private var placeholder = "Input report message".localized()
    private let reportTypes: [ReportType] = [.HateSpeech,
                                             .ViolenceOrThreats,
                                             .ExplicitContent,
                                             .FalseInformation,
                                             .CopyrightInfringement,
                                             .PrivacyViolation,
                                             .InvolvingScam,
                                             .OtherIllegalOrInappropriateContent]
    //Data
    private var report = Report()
    
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
        //Picker View
        typePickerView.dataSource = self
        typePickerView.delegate = self
        
        //Text View
        textview.text = placeholder
        textview.textColor = .systemGray
        textview.delegate = self
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textview.inputAccessoryView = accessoryview
        accessoryBtn.setTitle("Confirm".localized(), for: .normal)
        accessoryBtn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        
        buttonview.button.setTitle("Confirm".localized(), for: .normal)
        buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
    }
    
    func validateReport() -> Bool {
        if self.report.type == nil {
            self.showAlert(title: nil, message: "Input report type".localized())
            return false
        }
        
        if self.report.text == nil {
            self.showAlert(title: nil, message: "Input report message".localized())
            return false
        }
        
        self.report.senderUserId = self.senderUserId
        self.report.receiverUserId = self.receiverUserId
        print("---------------------------------------------")
        print("Report: \(self.report)")
        print("---------------------------------------------")
        return true
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func confirmAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateReport() {
            showAlert(title: nil, message: "Confirm create?".localized(), showCancel: true) {
                self.showActivityIndicator()
                ReportService.shared.createReport(report: self.report) {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(), 
                                   message: "Create successfully".localized()) {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

//MARK: Keyboard
extension ReportViewController {
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

//MARK: UITextViewDelegate
extension ReportViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == self.placeholder {
            textView.text = nil
            textView.textColor = .label
            self.report.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text,
           !text.isEmpty {
            self.report.text = text
    
        }else {
            textView.text = placeholder
            textView.textColor = .systemGray
            self.report.text = nil
        }
    }
}

//MARK: UIPickerViewDelegate
extension ReportViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.reportTypes.count + 1   //+1 請選擇
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        if row == 0 {
            label.text = "Choice".localized()
       
        }else {
            label.text = self.reportTypes[row - 1].rawValue.convertReportType()
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            self.report.type = nil
       
        }else {
            self.report.type = self.reportTypes[row - 1].rawValue
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
}
