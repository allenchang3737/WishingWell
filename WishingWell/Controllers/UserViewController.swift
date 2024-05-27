//
//  UserViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/18.
//

import UIKit

class UserViewController: UIViewController {
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var emptyNoteBtn: UIButton!
    
    var refreshControl: UIRefreshControl!
    let planeBtn = LUNBadgeButton()
    
    //Configuration
    var currentUser: User?
    
    //Data
    var wishProducts: [Product] = []
    var buyProducts: [Product] = []
    var comments: [Comment] = []
    
    //Product
    var activeType: UserThemeReusableType = .wish {
        didSet {
            reloadCollectionView(indexSet: IndexSet(integer: 1))
            checkEmptyNote()
        }
    }
    var activeData: [Any] {
        get {
            switch activeType {
            case .wish:
                return wishProducts
            case .buy:
                return buyProducts
            case .comment:
                return comments
            }
        }
    }
    
    var cellWidth: CGFloat = 200
    var cellHeight: CGFloat = 320
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerNotifications()
        setupBarButton()
        setupLayout()
        checkCurrentUser()
        updateNoticeBadgeCompletedHandler()
        
        AppManager.shared.showStoreKit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showNavigationBar()
        showTabBar()
        
        if !checkLogin() {
            self.showLoginView { success in
                if !success {
                    self.tabBarController?.selectedIndex = 0
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        //bug: 翻轉畫面未初始化 collectionview 閃退修正
        if self.collectionview != nil {
            reloadCollectionView(delay: 1)
        }
    }
    
    func reloadCollectionView(delay: Double = 0.0, indexSet: IndexSet? = nil) {
        //畫面需延遲，因為轉向完成才能reloadData，不然會失真
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            switch self.activeType {
            case .wish, .buy:
                self.cellWidth = self.collectionview.bounds.width / 2 - 1
                self.cellHeight = 320
            
            case .comment:
                self.cellWidth = self.collectionview.bounds.width - 1
                self.cellHeight = 125
            }
            
            if let index = indexSet {
                self.collectionview.reloadSections(index)
            }else {
                self.collectionview.reloadData()
            }
            self.collectionview.collectionViewLayout.invalidateLayout()
        }
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(currentUserCompletedHandler(notification:)), name: .currentUserCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateNoticeBadgeCompletedHandler), name: .updateNoticeBadgeCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProductCompletedHandler(notification:)), name: .updateProductCompleted, object: nil)
    }
    
    func setupBarButton() {
        let image = UIImage(systemName: "paperplane", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.label, renderingMode: .alwaysOriginal)
        planeBtn.setImage(image, for: .normal)
        planeBtn.addTarget(self, action: #selector(planeAction), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: planeBtn)
    }
    
    func setupLayout() {
        collectionview.register(UINib(nibName: "UserHeaderReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UserHeaderReusableView")
        collectionview.register(UINib(nibName: "UserThemeReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UserThemeReusableView")
        collectionview.register(UINib(nibName: "ProductCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ProductCollectionCell")
        collectionview.register(UINib(nibName: "UserCommentCell", bundle: nil), forCellWithReuseIdentifier: "UserCommentCell")
        collectionview.dataSource = self
        collectionview.delegate = self
        if let flowLayout = collectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        //RefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        collectionview.alwaysBounceVertical = true
        collectionview.addSubview(refreshControl)
    }
    
    func checkCurrentUser() {
        if let user = UserService.shared.currentUser {
            self.currentUser = user
            getProducts()
            getComments()
            
            self.refreshControl.endRefreshing()
            
        }else {
            guard AppManager.shared.accessToken != nil else { return }
            UserService.shared.getCurrentUser()
        }
    }
    
    func getUserHeaderReusableType() -> UserHeaderReusableType? {
        if self.wishProducts.contains(where: {
            $0.status == ProductStatus.DEPLOYED.rawValue ||
            $0.status == ProductStatus.PROCESSING.rawValue }) {
            return .wishing
       
        }else if self.buyProducts.contains(where: {
            $0.status == ProductStatus.DEPLOYED.rawValue ||
            $0.status == ProductStatus.PROCESSING.rawValue }) {
            return .buying
            
        }else {
            return nil
        }
    }
    
    func checkEmptyNote() {
        emptyNoteBtn.isHidden = !self.activeData.isEmpty
        emptyNoteBtn.removeTarget(nil, action: nil, for: .allEvents)
        
        switch self.activeType {
        case .wish:
            let attributeString = NSMutableAttributedString(
                string: "No wish data".localized(),
                attributes:  [
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            emptyNoteBtn.setAttributedTitle(attributeString, for: .normal)
            emptyNoteBtn.addTarget(self, action: #selector(moveWishAction), for: .touchUpInside)
            
        case .buy:
            let attributeString = NSMutableAttributedString(
                string: "No buy data".localized(),
                attributes:  [
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            emptyNoteBtn.setAttributedTitle(attributeString, for: .normal)
            emptyNoteBtn.addTarget(self, action: #selector(moveBuyAction), for: .touchUpInside)
            
        case .comment:
            let attributeString = NSMutableAttributedString(
                string: "No comment".localized(),
                attributes:  [
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            )
            emptyNoteBtn.setAttributedTitle(attributeString, for: .normal)
        }
    }
    
    func gotoPushNoticeView() {
        let pushNoticeVC = PushNoticeViewController(nibName: "PushNoticeViewController", bundle: nil)
        self.navigationController?.pushViewController(pushNoticeVC, animated: true)
    }
    
    func gotoMenuView() {
        let menuVC = MenuViewController(nibName: "MenuViewController", bundle: nil)
        self.navigationController?.pushViewController(menuVC, animated: true)
    }
    
    func gotoNewCommentView(comment: Comment) {
        let newCommentVC = NewCommentViewController(nibName: "NewCommentViewController", bundle: nil)
        newCommentVC.viewType = .Watch
        newCommentVC.newComment = comment
        newCommentVC.completionHandler = { new, state in
            switch state {
            case 1: //Update
                if let index = self.comments.firstIndex(where: { $0.commentId == new.commentId }) {
                    self.comments[index] = new
                    self.reloadCollectionView(indexSet: IndexSet(integer: 1))
                }
            
            case 2: //Delete
                if let index = self.comments.firstIndex(where: { $0.commentId == new.commentId }) {
                    self.comments.remove(at: index)
                    self.reloadCollectionView(indexSet: IndexSet(integer: 1))
                }
            
            default:
                break
            }
        }
        self.navigationController?.pushViewController(newCommentVC, animated: true)
    }
    
    //MARK: Notification
    @objc func currentUserCompletedHandler(notification: Notification) {
        checkCurrentUser()
    }
    
    @objc func updateNoticeBadgeCompletedHandler() {
        let count = PushNoticeService.shared.findAllUnreadCount()
        planeBtn.setBadge(count: count, padding: -10)
    }
    
    @objc func updateProductCompletedHandler(notification: Notification) {
        getProducts()
    }
    
    //MARK: Action
    @IBAction func menuAction(_ sender: Any) {
        gotoMenuView()
    }
    
    @objc func planeAction() {
        gotoPushNoticeView()
    }
    
    @objc func refreshAction() {
        checkCurrentUser()
    }
    
    @objc func chatAction() {
        self.showConversationsView()
    }
    
    @objc func moveWishAction() {
        self.tabBarController?.selectedIndex = 1
    }
    
    @objc func moveBuyAction() {
        self.tabBarController?.selectedIndex = 0
    }
}

//MARK: UICollectionViewDelegate
extension UserViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //0 = User Information
        //1 = Product Information
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 0
            
        case 1:
            return self.activeData.count
       
        default:
            break
        }
        return 0
    }
    
    //Header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        switch section {
        case 0:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UserHeaderReusableView", for: indexPath) as! UserHeaderReusableView
            if let user = self.currentUser {
                header.configure(user: user,
                                 type: getUserHeaderReusableType())
                header.chatBtn.addTarget(self, action: #selector(chatAction), for: .touchUpInside)
            }
            return header
            
        case 1:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "UserThemeReusableView", for: indexPath) as! UserThemeReusableView
            header.configure(wish: self.wishProducts.count,
                             buy: self.buyProducts.count,
                             comment: self.comments.count)
            header.selectedType = self.activeType
            header.completionHandler = { type in
                self.activeType = type
            }
            return header
            
        default:
            break
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 1:
            return CGSize(width: 320, height: 65)
        
        default:
            let indexPath = IndexPath(row: 0, section: section)
            let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
            
            return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        }
    }
    
    //Cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 1:
            if let product = activeData[row] as? Product {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCollectionCell", for: indexPath) as! ProductCollectionCell
                cell.configure(product: product,
                               width: self.cellWidth,
                               height: self.cellHeight,
                               isShowUser: false)
                return cell
                
            }else if let comment = activeData[row] as? Comment {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCommentCell", for: indexPath) as! UserCommentCell
                cell.configure(comment: comment, width: self.cellWidth)
                return cell
            }
            
        default:
            break
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let product = activeData[indexPath.row] as? Product {
            self.showProductDetailView(type: .Update, product: product, productUser: UserService.shared.currentUser)
            
        }else if let comment = activeData[indexPath.row] as? Comment {
            gotoNewCommentView(comment: comment)
        }
    }
}

//MARK: Server
extension UserViewController {
    func getProducts() {
        guard let userId = self.currentUser?.userId else { return }
        
        self.showActivityIndicator()
        ProductService.shared.getProducts(userId: userId) { datas in
            
            self.hideActivityIndicator()
            self.wishProducts = datas.filter({ $0.productType == ProductType.WISH.rawValue })
            self.buyProducts = datas.filter({ $0.productType == ProductType.BUY.rawValue })
            self.reloadCollectionView()
            self.checkEmptyNote()
        }
    }
    
    func getComments() {
        guard let userId = self.currentUser?.userId else { return }
        
        self.showActivityIndicator()
        CommentService.shared.getComments(userId: userId) { datas in
            
            self.hideActivityIndicator()
            self.comments = datas
            self.reloadCollectionView()
        }
    }
}
