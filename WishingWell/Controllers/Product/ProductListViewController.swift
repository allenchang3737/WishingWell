//
//  ProductListViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/29.
//

import UIKit

class ProductListViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    @IBOutlet weak var noteStackView: UIStackView!
    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var noteLbl: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    
    //Data
    var products: [Product] = [] {
        didSet {
            noteStackView.isHidden = !products.isEmpty
        }
    }
    
    var completionHandler: ((_ product: Product) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        getProducts()
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateProductCompletedHandler(notification:)), name: .updateProductCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateProductCompleted, object: nil)
    }
    
    @objc func updateProductCompletedHandler(notification: Notification) {
        getProducts()
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "OrderListCell", bundle: nil), forCellReuseIdentifier: "OrderListCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        //Empty note
        noteImageView.image = UIImage(systemName: "plus.message")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal)
        noteLbl.text = "No product".localized()
        let attributeString = NSMutableAttributedString(
            string: "Go to add".localized(),
            attributes:  [
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        addBtn.setAttributedTitle(attributeString, for: .normal)
        addBtn.addTarget(self, action: #selector(addAction), for: .touchUpInside)
    }
    
    func gotoNewProductView() {
        let newProductVC = NewProductViewController(nibName: "NewProductViewController", bundle: nil)
        newProductVC.viewType = .Create
        newProductVC.productType = .BUY
        self.navigationController?.pushViewController(newProductVC, animated: true)
    }
    
    //MARK: Action
    @objc func addAction() {
        gotoNewProductView()
    }
}

//MARK: UITableViewDelegate
extension ProductListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderListCell", for: indexPath) as! OrderListCell
        
        let product = products[row]
        cell.configure(product: product)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let product = products[row]
        completionHandler?(product)
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

//MARK: Server
extension ProductListViewController {
    func getProducts() {
        guard let userId = UserService.shared.currentUser?.userId else { return }
        
        self.showActivityIndicator()
        ProductService.shared.getProducts(userId: userId) { data in
            self.products = data.filter({ $0.productType == ProductType.BUY.rawValue })
            self.hideActivityIndicator()
            self.tableview.reloadData()
        }
    }
}
