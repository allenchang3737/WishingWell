//
//  BecomeBuyerViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/30.
//

import UIKit

enum BecomeStepType {
    case email          //Email驗證
    case phone          //Phone驗證
    case userType       //會員費用
}

class BecomeBuyerViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    var currentUser: User? {
        get {
            return UserService.shared.currentUser
        }
    }
    
    //Data
    var stepTypes: [BecomeStepType] = [.email, .phone]
    var isEmailVerified: Bool {
        get {
            return UserService.shared.currentUser?.emailVerified ?? false
        }
    }
    var isPhoneVerified: Bool {
        get {
            return UserService.shared.currentUser?.phoneVerified ?? false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Become a buyer".localized()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        showNavigationBar(isLarge: true)
        hideTabBar()
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "BecomeBuyerCell", bundle: nil), forCellReuseIdentifier: "BecomeBuyerCell")
        tableview.register(UINib(nibName: "BecomeTypeCell", bundle: nil), forCellReuseIdentifier: "BecomeTypeCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        checkFinishBtn()
    }
    
    func checkFinishBtn() {
        buttonview.button.setTitle("Finish".localized(), for: .normal)
        buttonview.button.removeTarget(nil, action: nil, for: .allEvents)
        buttonview.button.addTarget(self, action: #selector(finishAction), for: .touchUpInside)
        if isEmailVerified,
           isPhoneVerified {
            buttonview.button.isEnabled = true
            buttonview.button.backgroundColor = .label
            
        }else {
            buttonview.button.isEnabled = false
            buttonview.button.backgroundColor = .lightGray
        }
    }
    
    func validateCurrentUser() -> Bool {
        //Email verify
        if !isEmailVerified {
            showAlert(title: "Email".localized(), message: "Not verified yet".localized())
            return false
        }
        
        //Phone verify
        if !isPhoneVerified {
            showAlert(title: "Phone".localized(), message: "Not verified yet".localized())
            return false
        }
        
        return true
    }
    
    func gotoOTPView(type: OTPType, userInfo: String) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        otpVC.type = type
        otpVC.userInfo = userInfo
        otpVC.completionHandler = { (success, token) in
            if success {
                switch type {
                case .EMAIL:
                    self.tableview.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.checkFinishBtn()
                    
                case .PHONE:
                    self.tableview.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
                    self.checkFinishBtn()
                    
                default:
                    break
                }
  
            }else {
                print("Verify OTP Failed...\(type)")
            }
        }
        otpVC.modalPresentationStyle = .overCurrentContext
        self.present(otpVC, animated: true, completion: nil)
    }
    
    //MARK: Action
    @objc func verifyEmailAction() {
        gotoOTPView(type: .EMAIL, userInfo: self.currentUser?.email ?? "")
    }
    
    @objc func verifyPhoneAction() {
        gotoOTPView(type: .PHONE, userInfo: self.currentUser?.phone ?? "")
    }
    
    @objc func finishAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateCurrentUser() {
            //更新用戶資料: userType = Buyer
            guard var user = self.currentUser else { return }
            user.userType = UserType.BUYER.rawValue
            
            self.showActivityIndicator()
            UserService.shared.updateCurrentUser(user: user) {
                
                self.hideActivityIndicator()
                UserService.shared.currentUser?.userType = UserType.BUYER.rawValue
                self.showAlert(title: "Congratulation".localized(),
                               message: "Update successfully".localized()) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

//MARK: UITableViewDelegate
extension BecomeBuyerViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = Verify Email, Phone
        return 1
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return stepTypes.count
            
        default:
            break
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BecomeBuyerCell", for: indexPath) as! BecomeBuyerCell
    
            guard let user = self.currentUser else { return UITableViewCell() }
            let type = stepTypes[row]
            switch type {
            case .email:
                cell.configureEmail(user: user)
                cell.verifyBtn.addTarget(self, action: #selector(verifyEmailAction), for: .touchUpInside)
                
            case .phone:
                cell.configurePhone(user: user)
                cell.verifyBtn.addTarget(self, action: #selector(verifyPhoneAction), for: .touchUpInside)
                
            default:
                break
            }
            return cell
       
        default:
            break
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
