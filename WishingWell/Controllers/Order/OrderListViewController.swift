//
//  OrderListViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/26.
//

import UIKit

class OrderListViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    @IBOutlet weak var noteStackView: UIStackView!
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var noteLbl: UILabel!
    
    //Data
    var ownerOrders: [Order] = [] {
        didSet {
            if ownerOrders.isEmpty,
               userOrders.isEmpty {
                noteStackView.isHidden = false
            }else {
                noteStackView.isHidden = true
            }
        }
    }
    var userOrders: [Order] = [] {
        didSet {
            if ownerOrders.isEmpty,
               userOrders.isEmpty {
                noteStackView.isHidden = false
            }else {
                noteStackView.isHidden = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "My order".localized()
        setupLayout()
        getOrders()
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrdereCompletedHandler(notification:)), name: .updateOrderCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateOrderCompleted, object: nil)
    }
    
    @objc func updateOrdereCompletedHandler(notification: Notification) {
        getOrders()
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "OrderListCell", bundle: nil), forCellReuseIdentifier: "OrderListCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        if #available(iOS 15.0, *) {
            tableview.sectionHeaderTopPadding = 0.0
        }
        
        //Empty note
        noteImageView.image = UIImage(systemName: "plus.message")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        noteLbl.text = "No order".localized()
    }
}

//MARK: UITableViewDelegate
extension OrderListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = Owner Orders
        //1 = User Orders
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return ownerOrders.count
            
        case 1:
            return userOrders.count
            
        default:
            break
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderListCell", for: indexPath) as! OrderListCell
        
        switch section {
        case 0:
            let order = ownerOrders[row]
            cell.configure(order: order)
            
        case 1:
            let order = userOrders[row]
            cell.configure(order: order)
            
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            let order = ownerOrders[row]
            self.getOrder(orderId: order.orderId)
            
        case 1:
            let order = userOrders[row]
            self.getOrder(orderId: order.orderId)
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

//MARK: Server
extension OrderListViewController {
    func getOrders() {
        guard let userId = UserService.shared.currentUser?.userId else { return }
        
        self.showActivityIndicator()
        OrderService.shared.getOrders { data in
            self.ownerOrders = data.filter({ $0.orderUserId == userId })
            self.userOrders = data.filter({ $0.userId == userId })
            self.hideActivityIndicator()
            self.tableview.reloadData()
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
