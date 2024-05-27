//
//  CustomUserViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/21.
//

import UIKit

class CustomUserViewController: UIViewController {
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var emptyNoteBtn: UIButton!
    
    //Configuration
    var userId: Int?
    private var user: User? {
        didSet {
            getProducts()
            getComments()
        }
    }
    
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

        setupBarButton()
        setupLayout()
        getUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        showNavigationBar()
        hideTabBar()
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
    
    func setupBarButton() {
        let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(moreAction(_:)))
        navigationItem.rightBarButtonItem = moreBtn
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
    
    func showMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let report = UIAlertAction(title: "Report".localized(), style: .default) { action in
            guard let receiverUserId = self.user?.userId else { return }
            self.showReportView(receiverUserId)
        }
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(report)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
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
    
    func gotoChatView(_ conv: Conversation) {
        let chatVC = ChatViewController(conversation: conv, product: nil)
        chatVC.isAddToChat = false
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    //MARK: Action
    @objc func moreAction(_ sender: UIButton) {
        showMoreAlert(sender)
    }
    
    @objc func chatAction() {
        //檢查是否為Current User
        if UserService.shared.currentUser?.userId == self.user?.userId {
            self.showConversationsView()
            
        }else {
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
    
    @objc func moveWishAction() {
        self.navigationController?.popToRootViewController(animated: true)
        self.tabBarController?.selectedIndex = 1
    }
    
    @objc func moveBuyAction() {
        self.navigationController?.popToRootViewController(animated: true)
        self.tabBarController?.selectedIndex = 0
    }
}

//MARK: UICollectionViewDelegate
extension CustomUserViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
            if let user = self.user {
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
            self.showProductDetailView(type: .Watch, product: product, productUser: self.user)
            
        }else if let comment = activeData[indexPath.row] as? Comment {
            gotoNewCommentView(comment: comment)
        }
    }
}

//MARK: Server
extension CustomUserViewController {
    func getUser() {
        guard let userId = self.userId else { return }
        
        self.showActivityIndicator()
        UserService.shared.getUser(userId: userId) { data in
            
            self.hideActivityIndicator()
            if let data = data {
                self.user = data
                
            }else {
                self.showAlert(title: nil, message: "Unable".localized()) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func getProducts() {
        guard let userId = self.user?.userId else { return }
        
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
        guard let userId = self.user?.userId else { return }
        
        self.showActivityIndicator()
        CommentService.shared.getComments(userId: userId) { datas in
            
            self.hideActivityIndicator()
            self.comments = datas
            self.reloadCollectionView()
        }
    }
    
    func checkConversationExistence() {
        guard let userId = self.user?.userId else { return }
        self.showActivityIndicator()
        ConversationService.shared.getConversation(userId: userId) { data in
            
            self.hideActivityIndicator()
            if let conv = data {
                self.gotoChatView(conv)
                
            }else {
                guard let user = self.user else { return }
                let fakeConv = Conversation(users: [user])
                self.gotoChatView(fakeConv)
            }
        }
    }
}
