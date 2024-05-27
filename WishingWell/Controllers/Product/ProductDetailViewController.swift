//
//  ProductDetailViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/22.
//

import UIKit

//MARK: View
enum ViewType {
    case Create                 //新增
    case Update                 //更新
    case Watch                  //觀看
}

class ProductDetailViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var buttonview: LUNButtonView!
    
    //Configuration
    var viewType: ViewType = .Watch
    var product: Product? {
        didSet {
            setProduct()
        }
    }
    var productUser: User?
    
    //Data
    private var sectionData: [TitleTextViewData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setProduct()
        setupBarButton()
        setupLayout()
        
        if self.productUser == nil {
            getUser()
        }
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateProductCompletedHandler(notification:)), name: .updateProductCompleted, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateProductCompleted, object: nil)
    }
    
    @objc func updateProductCompletedHandler(notification: Notification) {
        getProduct()
    }
    
    func setProduct() {
        self.sectionData.removeAll()
        
        guard let product = self.product else { return }
        let type = ProductType(rawValue: product.productType)
        //Product Type
        switch type {
        case .WISH:
            navigationItem.title = "Wish".localized()
        
        case .BUY:
            navigationItem.title = "Buy".localized()
       
        default:
            break
        }
        
        //Product Intro
        let introData = TitleTextViewData(title: "Product intro".localized(),
                                          text: product.intro)
        self.sectionData.append(introData)
        
        //Product Date
        let start = product.startDate?.convertString(origin: .Server, result: .yyyyMMdd)
        let end = product.endDate?.convertString(origin: .Server, result: .yyyyMMdd)
        var text = ""
        if start == nil,
           end == nil {
            text = "Unlimited".localized()
            
        }else {
            text = "\(start ?? "Now".localized()) - \(end ?? "Unlimited".localized())"
        }
        let title = type == .WISH ? "Wish date".localized() : "Buy date".localized()
        let dateData = TitleTextViewData(title: title,
                                         text: text)
        self.sectionData.append(dateData)
        
        //Product webUrl
        if let webUrl = product.webUrl,
           !webUrl.isEmpty {
            let urldata = TitleTextViewData(title: "Product webUrl".localized(),
                                            text: webUrl)
            self.sectionData.append(urldata)
        }
    }
    
    func setupBarButton() {
        let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(moreAction(_:)))
        navigationItem.rightBarButtonItem = moreBtn
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "ProductDetailHeaderCell", bundle: nil), forCellReuseIdentifier: "ProductDetailHeaderCell")
        tableview.register(UINib(nibName: "LUNShareMapViewCell", bundle: nil), forCellReuseIdentifier: "LUNShareMapViewCell")
        tableview.register(UINib(nibName: "LUNTitleTextViewCell", bundle: nil), forCellReuseIdentifier: "LUNTitleTextViewCell")
        tableview.register(UINib(nibName: "ProductUserCell", bundle: nil), forCellReuseIdentifier: "ProductUserCell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        switch self.viewType {
        case .Create, .Update:
            buttonview.isHidden = true
            
        case .Watch:
            buttonview.isHidden = false
            
            guard let status = ProductStatus(rawValue: self.product?.status ?? 0) else { return }
            switch status {
            case .NOTDEPLOYED, .EXPIRED, .SUSPENDED, .TERMINATED:
                let title = self.product?.status.convertProductStatus()
                buttonview.button.setTitle(title, for: .normal)
                buttonview.button.isEnabled = false
                
            case .DEPLOYED, .PROCESSING:
                buttonview.button.setTitle("Chat".localized(), for: .normal)
                buttonview.button.addTarget(self, action: #selector(chatAction), for: .touchUpInside)
                buttonview.button.isEnabled = true
            }
        }
    }
    
    func showWatchMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let report = UIAlertAction(title: "Report".localized(), style: .default) { action in
            guard let receiverUserId = self.product?.user?.userId else { return }
            self.showReportView(receiverUserId)
        }
        let share = UIAlertAction(title: "Share".localized(), style: .default) { action in
            self.shareAction(sender)
        }
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(report)
        alert.addAction(share)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func showUpdateMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //Update
        let update = UIAlertAction(title: "Update".localized(), style: .default) { action in
            self.gotoNewProductView()
        }
        
        //Suspend
        let title = self.product?.status == ProductStatus.SUSPENDED.rawValue ? "Cancel suspend".localized() : "Suspend".localized()
        let suspend = UIAlertAction(title: title, style: .default) { action in
            self.suspendProduct()
        }
        
        //Delete
        let delete = UIAlertAction(title: "Delete".localized(), style: .destructive) { action in
            self.deleteProduct()
        }
        
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(update)
        alert.addAction(suspend)
        alert.addAction(delete)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func shareAction(_ sender: UIButton) {
        guard let product = self.product else { return }
        var items: [Any] = [product.title]
        
        DispatchQueue(label: "serialQueue").async {
            if let fileId = product.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId {
                FileService.shared.getImage(fileId: fileId) { image in
                    items.append(image)
                    
                    DispatchQueue.main.async {
                        OpenManager.shared.shareItems(activityItems: items, sender: sender)
                    }
                }
            }
        }
    }
    
    func gotoShareMapView() {
        guard let _ = self.product?.latitude,
           let _ = self.product?.longitude else { return }
        let shareMapVC = ShareMapViewController(nibName: "ShareMapViewController", bundle: nil)
        shareMapVC.product = self.product
        shareMapVC.modalPresentationStyle = .overCurrentContext
        self.present(shareMapVC, animated: true, completion: nil)
    }
    
    func gotoNewProductView() {
        let newProductVC = NewProductViewController(nibName: "NewProductViewController", bundle: nil)
        newProductVC.viewType = .Update
        if let type = ProductType(rawValue: self.product?.productType ?? 0) {
            newProductVC.productType = type
        }
        newProductVC.product = self.product
        self.navigationController?.pushViewController(newProductVC, animated: true)
    }
    
    func gotoChatView(_ conv: Conversation) {
        let chatVC = ChatViewController(conversation: conv, product: self.product)
        chatVC.isAddToChat = true
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //MARK: Action
    @objc func moreAction(_ sender: UIButton) {
        switch self.viewType {
        case .Create, .Update:
            self.showUpdateMoreAlert(sender)
            
        case .Watch:
            self.showWatchMoreAlert(sender)
        }
    }
    
    @objc func chatAction() {
        //檢查登入
        if !checkLogin() {
            self.showLoginView { success in
                if success {
                    self.checkConversationExistence()
                }
            }
            
        }else {
            self.checkConversationExistence()
        }
    }
}

//MARK: UITableViewDelegate
extension ProductDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = HeaderCell
        //1 = LUNShareMapViewCell
        //2 = LUNTitleTextViewCell
        //3 = ProductUserCell
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return 1
            
        case 2:
            return sectionData.count
            
        case 3:
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
            
            if let product = self.product {
                cell.configure(product: product)
            }
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNShareMapViewCell", for: indexPath) as! LUNShareMapViewCell
           
            cell.configure(countryCode: self.product?.countryCode,
                           latitude: self.product?.latitude,
                           longitude: self.product?.longitude,
                           meters: 1000000)
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTitleTextViewCell", for: indexPath) as! LUNTitleTextViewCell
            
            let data = self.sectionData[row]
            cell.configure(data: data)
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductUserCell", for: indexPath) as! ProductUserCell
    
            if let user = self.productUser {
                cell.configure(user: user)
            }
            return cell
        
        default:
            break
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        switch section {
        case 1:
            return 200
            
        case 3:
            //隱藏 User cell
            switch self.viewType {
            case .Create, .Update:
                return 0
                
            case .Watch:
                return UITableView.automaticDimension
            }
            
        default:
            break
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.zero
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        switch section {
        case 1:
            self.gotoShareMapView()
            
        case 3:
            guard let user = self.productUser else { return }
            self.showCustomUserView(user)
            
        default:
            break
        }
    }
}

//MARK: Server
extension ProductDetailViewController {
    func getUser() {
        guard let userId = self.product?.userId else { return }
        
        self.showActivityIndicator()
        UserService.shared.getUser(userId: userId) { data in
            self.hideActivityIndicator()
            if let user = data {
                self.productUser = user
                self.tableview.reloadSections(IndexSet(integer: 3), with: .automatic)
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized()) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func getProduct() {
        guard let productId = self.product?.productId else { return }
        self.showActivityIndicator()
        ProductService.shared.getProduct(productId: productId) { data in
            self.hideActivityIndicator()
            if let data = data {
                self.product = data
                self.tableview.reloadData()
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized())
            }
        }
    }
    
    func suspendProduct() {
        guard let productId = self.product?.productId,
              let status = ProductStatus(rawValue: self.product?.status ?? 0) else { return }
        var title = ""
        var message = ""
        //取消暫停
        if status == .SUSPENDED {
            title = "Cancel suspend".localized()
            message = "Cancel suspend alert".localized()

        //暫停競賽
        }else {
            title = "Suspend".localized()
            message = "Suspend alert".localized()
        }
        
        showAlert(title: title, message: message, showCancel: true) {
            self.showActivityIndicator()
            ProductService.shared.suspendProduct(productId: productId) {
                NotificationCenter.default.post(name: .updateProductCompleted, object: nil, userInfo: nil)
                self.hideActivityIndicator()
                self.showAlert(title: nil, message: "Update successfully".localized())
            }
        }
    }
    
    func deleteProduct() {
        guard let productId = self.product?.productId else { return }
        
        showAlert(title: "Delete".localized(), message: "Delete alert".localized(), showCancel: true) {
            self.showActivityIndicator()
            ProductService.shared.deleteProduct(productId: productId) {
                NotificationCenter.default.post(name: .updateProductCompleted, object: nil, userInfo: nil)
                self.hideActivityIndicator()
                self.showAlert(title: nil, message: "Delete successfully".localized()) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func checkConversationExistence() {
        guard let userId = self.product?.userId else { return }
        self.showActivityIndicator()
        ConversationService.shared.getConversation(userId: userId) { data in
            self.hideActivityIndicator()
            if let conv = data {
                self.gotoChatView(conv)
                
            }else {
                guard let user = self.productUser else { return }
                let fakeConv = Conversation(users: [user])
                self.gotoChatView(fakeConv)
            }
        }
    }
}
