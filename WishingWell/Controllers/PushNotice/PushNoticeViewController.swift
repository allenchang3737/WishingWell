//
//  PushNoticeViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/21.
//

import UIKit

public struct PushNoticeTemplate {
    var pushNoticeOb: PushNoticeOb
    var collapsed: Bool = false
}

class PushNoticeViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var personalBtn: LUNBadgeButton!
    @IBOutlet weak var personalSelectedView: UIView!
    @IBOutlet weak var orderBtn: LUNBadgeButton!
    @IBOutlet weak var orderSelectedView: UIView!
    @IBOutlet weak var activityBtn: LUNBadgeButton!
    @IBOutlet weak var activitySelectedView: UIView!
    
    @IBOutlet weak var noteStackView: UIStackView!
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var noteLbl: UILabel!
    
    //Configuration
    var activeType: PushType = .PERSONAL
    
    //Data
    private var activeTemplates: [PushNoticeTemplate] = [] {
        didSet {
            noteStackView.isHidden = !activeTemplates.isEmpty
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBarButton()
        setupLayout()
        checkActivePushType()
        
        //點擊推播後clear pushMessage
        PushNoticeService.shared.onclickNotice = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerNotifications()
        showNavigationBar()
        hideTabBar()
    }
    
    deinit {
        removeNotifications()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateNoticeBadgeCompletedHandler(notification:)), name: .updateNoticeBadgeCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateNoticeBadgeCompleted, object: nil)
    }
    
    func setupBarButton() {
        let editBtn = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(editAction))
        navigationItem.rightBarButtonItem = editBtn
    }
    
    func setupLayout() {
        //Personal
        personalBtn.setTitle("Personal".localized(), for: .normal)
        personalBtn.tag = 1
        personalBtn.addTarget(self, action: #selector(themeAction(_:)), for: .touchUpInside)
        personalBtn.setBadge(count: PushNoticeService.shared.personalBadge)
        
        //Order
        orderBtn.setTitle("Order".localized(), for: .normal)
        orderBtn.tag = 2
        orderBtn.addTarget(self, action: #selector(themeAction(_:)), for: .touchUpInside)
        orderBtn.setBadge(count: PushNoticeService.shared.orderBadge)
        
        //Activity
        activityBtn.setTitle("Activity".localized(), for: .normal)
        activityBtn.tag = 3
        activityBtn.addTarget(self, action: #selector(themeAction(_:)), for: .touchUpInside)
        activityBtn.setBadge(count: PushNoticeService.shared.activityBadge)
        
        //Table View
        tableview.register(UINib(nibName: "PushNoticeCell", bundle: nil), forCellReuseIdentifier: "PushNoticeCell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        //Empty note
        noteImageView.image = UIImage(systemName: "plus.message")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        noteLbl.text = "No push notice".localized()
    }
    
    func checkActivePushType() {
        setActiveTemplates()
        setActiveButton()
    }
    
    private func setActiveTemplates() {
        let notices = PushNoticeService.shared.getNotice(self.activeType)
        var templates: [PushNoticeTemplate] = []
        for notice in notices {
            let template = PushNoticeTemplate(pushNoticeOb: notice)
            templates.append(template)
        }
        self.activeTemplates = templates
        self.tableview.reloadData()
    }
    
    private func setActiveButton() {
        personalBtn.isSelected = false
        personalSelectedView.backgroundColor = .clear
        orderBtn.isSelected = false
        orderSelectedView.backgroundColor = .clear
        activityBtn.isSelected = false
        activitySelectedView.backgroundColor = .clear
        
        switch self.activeType {
        case .PERSONAL:
            personalBtn.isSelected = true
            personalSelectedView.backgroundColor = .label
            
        case .ORDER:
            orderBtn.isSelected = true
            orderSelectedView.backgroundColor = .label
            
        case .ACTIVITY:
            activityBtn.isSelected = true
            activitySelectedView.backgroundColor = .label
        }
    }
    
    //MARK: Message
    func changeTemplate(row: Int) {
        var template = self.activeTemplates[row]
        template.collapsed = !template.collapsed
        self.activeTemplates[row] = template
        
        let ob = template.pushNoticeOb
        PushNoticeService.shared.updateNoticeIsRead(ob, true)
        
        self.tableview.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
    }
    
    func deleteNotice(ob: PushNoticeOb, indexPath: IndexPath) {
        //Delete Local Notice
        PushNoticeService.shared.deleteNotice(ob)
        
        //Delete Cell
        self.activeTemplates.remove(at: indexPath.row)
        self.tableview.beginUpdates()
        self.tableview.deleteRows(at: [indexPath], with: .automatic)
        self.tableview.endUpdates()
    }
    
    //MARK: Notification
    @objc func updateNoticeBadgeCompletedHandler(notification: Notification) {
        guard let type = notification.userInfo?[MyKey.UserInfo.pushType] as? PushType else { return }
        
        switch type {
        case .PERSONAL:
            let count = PushNoticeService.shared.personalBadge
            personalBtn.setBadge(count: count)
            
        case .ORDER:
            let count = PushNoticeService.shared.orderBadge
            orderBtn.setBadge(count: count)
            
        case .ACTIVITY:
            let count = PushNoticeService.shared.activityBadge
            activityBtn.setBadge(count: count)
        }
    }
    
    //MARK: Action
    @objc func editAction() {
        self.tableview.setEditing(!self.tableview.isEditing, animated: true)
    }
    
    @objc func themeAction(_ sender: UIButton) {
        let tag = sender.tag
        switch tag {
        case 1: 
            self.activeType = .PERSONAL
        
        case 2: 
            self.activeType = .ORDER
        
        case 3: 
            self.activeType = .ACTIVITY
        
        default:
            break
        }
        checkActivePushType()
    }
    
    @objc func moveAction(_ sender: UIButton) {
        let tag = sender.tag
        let ob = self.activeTemplates[tag].pushNoticeOb
        
        guard let type = PushAction(rawValue: ob.action),
              ob.dataId != 0 else { return }
        switch type {
        case .PRODUCT:
            getProduct(productId: ob.dataId)
            
        case .ORDER:
            getOrder(orderId: ob.dataId)
            
        case .COMMENT:
            print("Move to comment...")
        }
    }
}

//MARK: UITableViewDelegate
extension PushNoticeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeTemplates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushNoticeCell", for: indexPath) as! PushNoticeCell
        
        let template = activeTemplates[row]
        cell.configure(template: template)
        
        cell.moveBtn.tag = row
        cell.moveBtn.addTarget(self, action: #selector(moveAction(_:)), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        changeTemplate(row: row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return tableView.isEditing
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if editingStyle == .delete {
            let ob = self.activeTemplates[row].pushNoticeOb
            self.deleteNotice(ob: ob, indexPath: indexPath)
        }
    }
}

//MARK: Server
extension PushNoticeViewController {
    func getProduct(productId: Int) {
        self.showActivityIndicator()
        ProductService.shared.getProduct(productId: productId) { data in
            self.hideActivityIndicator()
            if let product = data {
                self.showProductDetailView(type: .Watch, product: product, productUser: product.user)
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized())
            }
        }
    }
    
    func getOrder(orderId: Int) {
        self.showActivityIndicator()
        OrderService.shared.getOrder(orderId: orderId) { data in
            self.hideActivityIndicator()
            if let order = data {
                self.showOrderDetailView(type: .Update, order: order)
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized())
            }
        }
    }
}
