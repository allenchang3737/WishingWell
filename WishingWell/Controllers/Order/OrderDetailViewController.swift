//
//  OrderDetailViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/28.
//

import UIKit

class OrderDetailViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    //Configuration
    var viewType: ViewType = .Watch
    var order: Order?
    
    //Data
    private var orderUser: User? {
        get {
            return self.order?.orderUser
        }
    }
    private var user: User? {
        get {
            return self.order?.user
        }
    }
    private var isOrderOwner: Bool {
        get {
            return UserService.shared.currentUser?.userId == self.orderUser?.userId
        }
    }
    private var sectionData: [Int: [TitleTextViewData]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setOrder()
        setupBarButton()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        registerNotifications()
        showNavigationBar(isLarge: true)
        hideTabBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
    }
    
    deinit {
        removeNotifications()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrdereCompletedHandler(notification:)), name: .updateOrderCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateOrderCompleted, object: nil)
    }
    
    @objc func updateOrdereCompletedHandler(notification: Notification) {
        getOrder()
    }
    
    func setOrder() {
        guard let order = self.order else { return }
        //Order Status
        navigationItem.title = order.status.convertOrderStatus()
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.convertOrderStatus(order.status)]
        
        //Section 1
        //Order Id
        let idData = TitleTextViewData(title: "Order ID".localized() + "：",
                                       text: "\(order.orderId)",
                                       axis: .horizontal)
        //Order create date
        let createDate = order.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm) ?? ""
        let createDateData = TitleTextViewData(title: "Order create date".localized() + "：",
                                               text: createDate,
                                               axis: .horizontal)
        //Order note
        let noteData = TitleTextViewData(title: "Order note".localized() + "：",
                                         text: order.orderNote)
        //Order deal date
        let dealDate = order.dealDate.convertString(origin: .Server, result: .yyyyMMdd) ?? ""
        let dealDateData = TitleTextViewData(title: "Order deal date".localized() + "：",
                                             text: dealDate,
                                             axis: .horizontal)
        //Order Amount
        let amountData = TitleTextViewData(title: "Order amount".localized() + "：",
                                           text: "$ \(order.amount.priceFormatting())",
                                           axis: .horizontal)
        self.sectionData[1] = [idData, createDateData, noteData, dealDateData, amountData]
        
        //Section 2
        //Order deal type
        let typeData = TitleTextViewData(title: "Order deal type".localized() + "：",
                                         text: order.dealType?.convertDealType() ?? "",
                                         axis: .horizontal)
        self.sectionData[2] = [typeData]
        
        //Section 3
        //Order user name
        let nameData = TitleTextViewData(title: "Order user name".localized(),
                                         text: order.userName ?? "")
        //Order user phone
        let phoneData = TitleTextViewData(title: "Order user phone".localized(),
                                          text: order.userPhone ?? "")
        //Order user email
        let emailData = TitleTextViewData(title: "Order user email".localized(),
                                          text: order.userEmail ?? "")
        self.sectionData[3] = [nameData, phoneData, emailData]
    }
    
    func setupBarButton() {
        switch self.viewType {
        case .Update:
            let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(moreAction(_:)))
            navigationItem.rightBarButtonItem = moreBtn
            
        default:
            break
        }
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "ProductDetailHeaderCell", bundle: nil), forCellReuseIdentifier: "ProductDetailHeaderCell")
        tableview.register(UINib(nibName: "LUNTitleTextViewCell", bundle: nil), forCellReuseIdentifier: "LUNTitleTextViewCell")
        tableview.register(UINib(nibName: "ProductUserCell", bundle: nil), forCellReuseIdentifier: "ProductUserCell")
        tableview.register(UINib(nibName: "OrderUserCell", bundle: nil), forCellReuseIdentifier: "OrderUserCell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
    }
    
    func showMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let updateOrder = UIAlertAction(title: "Update".localized() + "Order".localized(), style: .default) { action in
            self.updateOrder()
        }
        alert.addAction(updateOrder)
        
        let cancelOrder = UIAlertAction(title: "Cancel".localized() + "Order".localized(), style: .default) { action in
            self.cancelOrder()
        }
        alert.addAction(cancelOrder)
        
        if isOrderOwner {
            let deleteOrder = UIAlertAction(title: "Delete".localized() + "Order".localized(), style: .destructive) { action in
                self.deleteOrder()
            }
            alert.addAction(deleteOrder)
        }
        
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func gotoNewOrderView(type: ViewType, order: Order?) {
        let newOrderVC = NewOrderViewController(nibName: "NewOrderViewController", bundle: nil)
        newOrderVC.viewType = type
        newOrderVC.order = order
        self.navigationController?.pushViewController(newOrderVC, animated: true)
    }
    
    func gotoNewCommentView() {
        let newCommentVC = NewCommentViewController(nibName: "NewCommentViewController", bundle: nil)
        newCommentVC.viewType = .Create
        newCommentVC.receiverUserId = self.orderUser?.userId
        self.navigationController?.pushViewController(newCommentVC, animated: true)
    }
    
    //MARK: Action
    @objc func moreAction(_ sender: UIButton) {
        showMoreAlert(sender)
    }
    
    @objc func finishAction() {
        self.finishOrder()
    }
    
    @objc func commentAction() {
        gotoNewCommentView()
    }
}

//MARK: UITableViewDelegate
extension OrderDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = HeaderCell
        //1 = LUNTitleTextViewCell(Order Info)
        //2 = LUNTitleTextViewCell(Deal Type)
        //3 = UserCell + LUNTitleTextViewCell(User Info)
        //4 = OrderUserCell
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return sectionData[1]?.count ?? 0
            
        case 2:
            return sectionData[2]?.count ?? 0
            
        case 3:
            return 1 + (sectionData[3]?.count ?? 0)
            
        case 4:
            return 1
        
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        switch section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductDetailHeaderCell", for: indexPath) as! ProductDetailHeaderCell
            
            cell.priceLbl.isHidden = true
            if let product = self.order?.product {
                cell.configure(product: product)
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTitleTextViewCell", for: indexPath) as! LUNTitleTextViewCell
            
            if let data = self.sectionData[1]?[row] {
                cell.configure(data: data)
            }
            //Amount
            if row == 4 {
                cell.textview.textColor = .red
                cell.textview.font = UIFont.preferredFont(forTextStyle: .headline)
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTitleTextViewCell", for: indexPath) as! LUNTitleTextViewCell
            
            if let data = self.sectionData[2]?[row] {
                cell.configure(data: data)
            }
            return cell
            
        case 3:
            if row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProductUserCell", for: indexPath) as! ProductUserCell
                cell.statusLbl.isHidden = true
                cell.imageHeight.constant = 50
                cell.imageview.cornerRadius = 25
                if let user = self.user {
                    cell.configure(user: user)
                }else {
                    cell.contentView.isHidden = true
                }
                return cell
                
            }else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTitleTextViewCell", for: indexPath) as! LUNTitleTextViewCell
                
                if let data = self.sectionData[3]?[row - 1] {
                    cell.configure(data: data)
                }
                return cell
            }
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderUserCell", for: indexPath) as! OrderUserCell

            if let user = self.orderUser {
                cell.configure(user: user, star: nil)
                cell.commentBtn.addTarget(self, action: #selector(commentAction), for: .touchUpInside)
            }
            if let status = OrderStatus(rawValue: self.order?.status ?? 0) {
                cell.configureMasK(status: status, isOwner: self.isOrderOwner)
                cell.finishBtn.addTarget(self, action: #selector(finishAction), for: .touchUpInside)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.zero
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        switch (section, row) {
        case (0, 0):
            guard let product = self.order?.product else { return }
            self.showProductDetailView(type: .Watch, product: product, productUser: product.user)
            
        case (3, 0):
            guard let user = self.user else { return }
            self.showCustomUserView(user)
            
        case (4, 0):
            guard let user = self.orderUser else { return }
            self.showCustomUserView(user)
            
        default:
            break
        }
    }
}

//MARK: Server
extension OrderDetailViewController {
    func getOrder() {
        guard let orderId = self.order?.orderId else { return }
        self.showActivityIndicator()
        OrderService.shared.getOrder(orderId: orderId) { data in
            self.hideActivityIndicator()
            if let order = data {
                self.order = order
                self.setOrder()
                self.tableview.reloadData()
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized()) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func updateOrder() {
        ///檢查更新訂單資格
        ///`Owner`: 0~99 (order status) 可以更新
        ///`User`: 0~90 (order status) 可以更新
        var isQualified = true
        var message = ""
        guard let orderStatus = self.order?.status,
              let status = OrderStatus(rawValue: orderStatus) else { return }
        if isOrderOwner {
            print("All status can be updated...")
      
        }else {
            if status == .CANCELED || status == .COMPLETED {
                isQualified = false
                message = String(format: "Update order error".localized(), orderStatus.convertOrderStatus() ?? "")
            }
        }
        
        if isQualified {
            guard let order = self.order else { return }
            gotoNewOrderView(type: .Update, order: order)
            
        }else {
            showAlert(title: nil, message: message)
        }
    }
    
    func cancelOrder() {
        ///檢查取消訂單資格
        ///`Owner`: 0~90 (order status) 可以取消
        ///`User`: 0~90 (order status) 可以取消
        var isQualified = true
        var message = ""
        guard let orderStatus = self.order?.status,
              let status = OrderStatus(rawValue: orderStatus) else { return }
        
        if status == .CANCELED || status == .COMPLETED {
            isQualified = false
            message = String(format: "Cancel order error".localized(), orderStatus.convertOrderStatus() ?? "")
        }
        
        if isQualified {
            showAlert(title: nil, message: "Confirm cancel?".localized(), showCancel: true) {
                guard let orderId = self.order?.orderId else { return }
                self.showActivityIndicator()
                OrderService.shared.cancelOrder(orderId: orderId) {
                    
                    NotificationCenter.default.post(name: .updateOrderCompleted, object: nil, userInfo: nil)
                    self.hideActivityIndicator()
                    self.showAlert(title: nil, message: "Cancel successfully".localized())
                }
            }
            
        }else {
            showAlert(title: nil, message: message)
        }
    }
    
    func deleteOrder() {
        ///檢查刪除訂單資格
        ///`Owner`:  0~98 (order status) 可以更新
        ///`User`: 沒有刪除Button
        var isQualified = true
        var message = ""
        guard let orderStatus = self.order?.status,
              let status = OrderStatus(rawValue: orderStatus) else { return }
        if isOrderOwner {
            if status == .COMPLETED {
                isQualified = false
                message = String(format: "Delete order error".localized(), orderStatus.convertOrderStatus() ?? "")
            }
        }
        
        if isQualified {
            showAlert(title: nil, message: "Confirm delete?".localized(), showCancel: true) {
                guard let orderId = self.order?.orderId else { return }
                self.showActivityIndicator()
                OrderService.shared.deleteOrder(orderId: orderId) {
                    
                    NotificationCenter.default.post(name: .updateOrderCompleted, object: nil, userInfo: nil)
                    self.hideActivityIndicator()
                    self.showAlert(title: nil, message: "Delete successfully".localized()) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
            
        }else {
            showAlert(title: nil, message: message)
        }
    }
    
    func finishOrder() {
        ///檢查完成訂單資格
        ///`Owner`: 90 (order status) 可以完成
        ///`User`: 沒有完成Button
        var isQualified = true
        var message = ""
        guard let orderStatus = self.order?.status,
              let status = OrderStatus(rawValue: orderStatus) else { return }
        if isOrderOwner {
            if status != .PROCESSING {
                isQualified = false
                message = String(format: "Finish order error".localized(), orderStatus.convertOrderStatus() ?? "")
            }
        }
        
        if isQualified {
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                guard let orderId = self.order?.orderId else { return }
                self.showActivityIndicator()
                OrderService.shared.finishOrder(orderId: orderId) {
                    
                    NotificationCenter.default.post(name: .updateOrderCompleted, object: nil, userInfo: nil)
                    self.hideActivityIndicator()
                    self.showAlert(title: nil, message: "Update successfully".localized())
                }
            }
            
        }else {
            showAlert(title: nil, message: message)
        }
    }
}
