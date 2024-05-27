//
//  MenuViewController.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/22.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import MessageUI

class MenuViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    var currentUser: User? {
        get {
            return UserService.shared.currentUser
        }
    }
    
    var sectionData: [Int: [ImageTitleData]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "My Profile"
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerNotifications()
        showNavigationBar(isLarge: true)
        hideTabBar()
    }
    
    deinit {
        removeNotifications()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(currentUserCompletedHandler(notification:)), name: .currentUserCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .currentUserCompleted, object: nil)
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "MenuUserCell", bundle: nil), forCellReuseIdentifier: "MenuUserCell")
        tableview.register(UINib(nibName: "LUNImageTitleCell", bundle: nil), forCellReuseIdentifier: "LUNImageTitleCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        //Section 1
        let settingData = [ImageTitleData(image: UIImage(systemName: "checkmark.shield"),
                                          title: "Become a buyer".localized()),
                           ImageTitleData(image: UIImage(systemName: "doc.text"),
                                          title: "My order".localized()),
                           ImageTitleData(image: UIImage(systemName: "lock.open"),
                                          title: "Change password".localized())]
        sectionData[1] = settingData
        
        //Section 2
        let helpData = [ImageTitleData(image: UIImage(systemName: "questionmark.circle"),
                                       title: "What's up FAQ".localized()),
                        ImageTitleData(image: UIImage(systemName: "captions.bubble"),
                                       title: "Contact service".localized()),
                        ImageTitleData(image: UIImage(systemName: "rectangle.portrait.and.arrow.forward"),
                                       title: "Log out".localized())]
        sectionData[2] = helpData
    }
    
    @objc func currentUserCompletedHandler(notification: Notification) {
        self.tableview.reloadData()
    }
    
    func showContactAlert(_ sender: UITableViewCell?) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //Email
        let email = UIAlertAction(title: "Email".localized(), style: .default) { action in
            guard let email = AppConfigService.shared.config?.serviceEmail else { return }
            OpenManager.shared.sendEmail(email: email, subject: nil, message: nil)
        }
        
        //Phone
        let phone = UIAlertAction(title: "Phone".localized(), style: .default) { action in
            guard let phone = AppConfigService.shared.config?.servicePhone else { return }
            OpenManager.shared.openPhone(phoneNumber: phone)
        }
        
        //Cancel
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(email)
//        alert.addAction(phone)
        alert.addAction(cancel)
        
        //For iPad
        if let cell = sender,
           let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func gotoBecomeBuyerView() {
        let becomeBuyerVC = BecomeBuyerViewController(nibName: "BecomeBuyerViewController", bundle: nil)
        self.navigationController?.pushViewController(becomeBuyerVC, animated: true)
    }
    
    func gotoUserEditView() {
        let userEditVC = UserEditViewController(nibName: "UserEditViewController", bundle: nil)
        userEditVC.currentUser = self.currentUser
        self.navigationController?.pushViewController(userEditVC, animated: true)
    }
    
    func gotoOrderListView() {
        let orderListVC = OrderListViewController(nibName: "OrderListViewController", bundle: nil)
        self.navigationController?.pushViewController(orderListVC, animated: true)
    }
    
    func gotoChangePwdView() {
        let changePwdVC = ChangePwdViewController(nibName: "ChangePwdViewController", bundle: nil)
        self.navigationController?.pushViewController(changePwdVC, animated: true)
    }
    
    //MARK: Action
    @objc func userEditAction() {
        gotoUserEditView()
    }

    func logoutAction() {
        self.showAlert(title: nil, message: "Confirm log out?".localized(), showCancel: true) {
            UserService.shared.logout {
                self.tabBarController?.selectedIndex = 0
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

//MARK: UITableViewDelegate
extension MenuViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = My Profile
        //1 = Setting
        //2 = Help
        return 3
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        
        case 1:
            return self.sectionData[section]?.count ?? 0
            
        case 2:
            return self.sectionData[section]?.count ?? 0
            
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuUserCell", for: indexPath) as! MenuUserCell
            if let user = self.currentUser {
                cell.configure(user: user)
            }
            cell.editBtn.addTarget(self, action: #selector(userEditAction), for: .touchUpInside)
            return cell
       
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNImageTitleCell", for: indexPath) as! LUNImageTitleCell
            if let data = self.sectionData[section]?[row] {
                cell.configure(data: data)
            }
            if row == 0,
               let type = UserType(rawValue: self.currentUser?.userType ?? 0) {
                cell.checkUserType(type: type)
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNImageTitleCell", for: indexPath) as! LUNImageTitleCell
            if let data = self.sectionData[section]?[row] {
                cell.configure(data: data)
            }
            return cell
       
        default:
            break
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        switch (section, row) {
        case (1, 0):
            gotoBecomeBuyerView()
            
        case (1, 1):
            gotoOrderListView()
            
        case (1, 2):
            gotoChangePwdView()
            
        case (2, 0):
            guard let questionUrl = AppConfigService.shared.config?.questionUrl,
                  let url = URL(string: questionUrl) else { return }
            self.showLUNWebView(url: url)
            
        case (2, 1):
            let cell = tableView.cellForRow(at: indexPath)
            showContactAlert(cell)
            
        case (2, 2):
            logoutAction()
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Setting".localized()
            
        case 2:
            return "Help".localized()
            
        default:
            break
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            return "v \(version)"
            
        default:
            break
        }
        return nil
    }
}

//MARK: MailDelegate
extension MenuViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
