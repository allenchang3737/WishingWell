//
//  BuyProductViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/19.
//

import UIKit
import SKCountryPicker

class BuyProductViewController: UIViewController {
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var filterBtn: LUNBadgeButton!
    @IBOutlet weak var chatBtn: LUNBadgeButton!
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var dragImageView: UIImageView!
    var refreshControl: UIRefreshControl!
    
    //Parameters
    var search: Search {
        get {
            return AppManager.shared.buySearch
        }
        set {
            AppManager.shared.buySearch = newValue
        }
    }
    fileprivate var isLoading = false
    
    //Data
    var products: [Product] = []
    
    var cellWidth: CGFloat = 200
    var cellHeight: CGFloat = 320
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        searchProducts()
        
        //是否存在click推播
        if PushNoticeService.shared.onclickNotice != nil {
            self.showPushNoticeView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showTabBar()
        hideNavigationBar()
        
        checkFilterBtn()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        //bug: 翻轉畫面未初始化 collectionview 閃退修正
        if self.collectionview != nil {
            reloadCollectionView(delay: 1)
        }
    }
    
    func reloadCollectionView(delay: Double = 0.0) {
        //畫面需延遲，因為轉向完成才能reloadData，不然會失真
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.cellWidth = self.collectionview.bounds.width / 2 - 1
            self.cellHeight = 320
            
            self.collectionview.reloadData()
            self.collectionview.collectionViewLayout.invalidateLayout()
        }
    }
    
    func setupLayout() {
        collectionview.register(UINib(nibName: "AnnouncementReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "AnnouncementReusableView")
        collectionview.register(UINib(nibName: "ProductCollectionCell", bundle: nil), forCellWithReuseIdentifier: "ProductCollectionCell")
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
        
        reloadCollectionView()
        
        //Set Search Bar
        searchbar.placeholder = "Input product title".localized()
        searchbar.delegate = self
        definesPresentationContext = true
        
        //Drag Image
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dragHandle))
        let tap = UITapGestureRecognizer(target: self, action: #selector(newBuyAction))
        dragImageView.addGestureRecognizer(pan)
        dragImageView.addGestureRecognizer(tap)
    }
    
    func checkFilterBtn() {
        if let code = self.search.countryCode {
            self.filterBtn.setDot(true)
            
            //Set Selected Country
            //檢查第三方套件'SKCountryPicker': mapping不到countryCode閃退
            let locale = Locale(identifier: Locale.preferredLanguages.first ?? "")
            guard let localisedCountryName = locale.localizedString(forRegionCode: code) else {
                return
            }
            CountryManager.shared.lastCountrySelected = Country(countryCode: code)

        }else {
            self.filterBtn.setDot(false)
            
            //Set Selected Country
            CountryManager.shared.lastCountrySelected = nil
        }
    }
    
    func resetParams() {
        self.products.removeAll()
        reloadCollectionView()
        self.search.page = 0
    }
    
    func gotoNewProductView() {
        let newProductVC = NewProductViewController(nibName: "NewProductViewController", bundle: nil)
        newProductVC.viewType = .Create
        newProductVC.productType = .BUY
        self.navigationController?.pushViewController(newProductVC, animated: true)
    }
    
    func gotoBecomeBuyerView() {
        let becomeBuyerVC = BecomeBuyerViewController(nibName: "BecomeBuyerViewController", bundle: nil)
        self.navigationController?.pushViewController(becomeBuyerVC, animated: true)
    }
    
    func gotoCountryPickerView() {
        CountryPickerWithSectionViewController.presentController(on: self, configuration: { countryController in
            countryController.configuration.flagStyle = .circular
            countryController.configuration.isCountryFlagHidden = false
            countryController.configuration.isCountryDialHidden = true
            countryController.favoriteCountriesLocaleIdentifiers = ["US", "JP", "KR", "SG", "TH",
                                                                    "CA", "AU", "GB", "HK", "TW"]
        }) { [weak self] country in
            guard let self = self else { return }
            self.search.countryCode = country.countryCode
            self.resetParams()
            self.checkFilterBtn()
            self.searchProducts()
        }
    }
    
    //MARK: Action
    @objc func dragHandle(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.view)
        guard let dragView = gesture.view else { return }
        let pending = dragView.frame.width / 2 + 8
        guard location.x > pending,
              location.x < self.view.layer.frame.width - pending,
              location.y > self.view.safeAreaInsets.top + pending,
              location.y < self.view.layer.frame.height - self.view.safeAreaInsets.bottom - pending else { return }
        dragView.center = location
        
        if gesture.state == .ended {
            if self.dragImageView.frame.midX >= self.view.layer.frame.width / 2 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.dragImageView.center.x = self.view.layer.frame.width - pending
                }, completion: nil)
            
            }else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.dragImageView.center.x = pending
                }, completion: nil)
            }
        }
    }
    
    @objc func newBuyAction() {
        let type = UserType(rawValue: UserService.shared.currentUser?.userType ?? 0)
        if type == .WISHER {
            self.showAlert(title: nil, message: "Must become a buyer".localized(), showCancel: true, confirmTitle: "Move".localized()) {
                self.gotoBecomeBuyerView()
            }
            
        }else {
            self.gotoNewProductView()
        }
    }
    
    @objc func refreshAction() {
        resetParams()
        searchProducts()
    }
    
    @IBAction func filterAction(_ sender: Any) {
        gotoCountryPickerView()
    }
    
    @IBAction func chatAction(_ sender: Any) {
        //檢查登入
        if !checkLogin() {
            self.showLoginView { success in
                if success {
                    self.showConversationsView()
                }
            }
            
        }else {
            self.showConversationsView()
        }
    }
}

//MARK: UISearchBarDelegate
extension BuyProductViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text,
              !text.isEmpty else { return }
        self.search.text = text
        resetParams()
        searchProducts()
        
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.search.text = nil
            resetParams()
            searchProducts()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}

//MARK: UICollectionViewDelegate
extension BuyProductViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        //0 = Product Information
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.products.count
    }
    
    //Header
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionHeaderView", for: indexPath) as! CollectionHeaderView
//        header.configure()
//        return header
//    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        let indexPath = IndexPath(row: 0, section: section)
//        let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)
//       
//        return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
//    }
    
    //Cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = indexPath.row
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCollectionCell", for: indexPath) as! ProductCollectionCell
        let product = self.products[row]
        cell.configure(product: product,
                       width: self.cellWidth,
                       height: self.cellHeight)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard self.isLoading == false else {
            print("isLoading...")
            return
        }
        //倒數最後第6個預載資料
        let lastCount = self.products.count - 10
        if lastCount == indexPath.row {
            searchProducts()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = self.products[indexPath.row]
        self.showProductDetailView(type: .Watch, product: product, productUser: product.user)
    }
}

//MARK: Server
extension BuyProductViewController {
    func searchProducts() {
        guard !self.isLoading else { return }
        
        self.showActivityIndicator()
        self.isLoading = true
        ProductService.shared.searchProducts(search: self.search) { datas in
            if datas.isEmpty {
                print("no data...")
                
            }else {
                self.collectionview.performBatchUpdates {
                    for data in datas {
                        self.products.append(data)
                        let indexPath = IndexPath(row: self.products.count - 1, section: 0)
                        self.collectionview.insertItems(at: [indexPath])
                    }
                }
                //Set Parameters
                self.search.page += 1
            }
            
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.hideActivityIndicator()
        }
    }
}
