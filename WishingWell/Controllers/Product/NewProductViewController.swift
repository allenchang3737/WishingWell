//
//  NewProductViewController.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/5/30.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import YPImagePicker
import SKCountryPicker

class NewProductViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var buttonview: LUNButtonView!
    @IBOutlet var datepicker: UIDatePicker!
    var toolBar = UIToolbar()
    
    //Configuration
    var viewType: ViewType = .Create
    var productType: ProductType = .WISH
    var product: Product?
    
    //Data
    private var newProduct = Product()
    //Images
    private var maxCount = 10
    private var imageData: [ImageFileData] = []
    private var deleteImageData: [ImageFileData] = []
    
    private var activeTextField: UITextField?
    private var activeIndexPath: IndexPath? {
        didSet {
            //If active text field is hidden by keyboard, scroll to text field
            DispatchQueue.main.async {
                if let indexpath = self.activeIndexPath {
                    self.tableview.scrollToRow(at: indexpath, at: .middle, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch self.productType {
        case .WISH:
            navigationItem.title = "Wish".localized()
        
        case .BUY:
            navigationItem.title = "Buy".localized()
        }
        
        switch self.viewType {
        case .Create:
            self.newProduct.productType = self.productType.rawValue

        case .Update:
            guard let product = self.product else { return }
            self.newProduct = product
            
            //Images
            let files = product.files?.filter({ $0.type == FileType.PRODUCT.rawValue }) ?? []
            self.showActivityIndicator()
            
            let dispatchGroup = DispatchGroup()
            for file in files {
                dispatchGroup.enter()
                FileService.shared.getImage(fileId: file.fileId) { image in
                    let data = ImageFileData(image: image,
                                             file: file)
                    self.imageData.append(data)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.tableview.reloadData()
                self.hideActivityIndicator()
            }
            
        default:
            break
        }
        
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotifications()
        showNavigationBar(isLarge: true)
        hideTabBar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
    }

    func setupLayout() {
        //Table View
        tableview.register(UINib(nibName: "LUNImagesCell", bundle: nil), forCellReuseIdentifier: "LUNImagesCell")
        tableview.register(UINib(nibName: "LUNTextFieldCell", bundle: nil), forCellReuseIdentifier: "LUNTextFieldCell")
        tableview.register(UINib(nibName: "LUNShareMapViewCell", bundle: nil), forCellReuseIdentifier: "LUNShareMapViewCell")
        tableview.register(UINib(nibName: "LUNTwoTextFieldCell", bundle: nil), forCellReuseIdentifier: "LUNTwoTextFieldCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableview.sectionHeaderTopPadding = 0.0
        }
        
        datepicker.date = Date()
        datepicker.minimumDate = Date()
        datepicker.datePickerMode = .date
        datepicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
        toolBar.frame = CGRect(x: 0, y: self.datepicker.frame.height, width: self.view.frame.width, height: 44)
        toolBar.toolbarPicker(target: self, selector: #selector(timeConfirm),
                              targetClear: self, selectorClear:  #selector(timeClear))
        
        //Button View
        switch self.viewType {
        case .Create:
            buttonview.button.setTitle("Create".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(createAction), for: .touchUpInside)
            
        case .Update:
            buttonview.button.setTitle("Update".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
            
        default:
            break
        }
    }
    
    func getProductCountry() -> Country? {
        guard let code = self.newProduct.countryCode else {
            return nil
        }
        //檢查第三方套件'SKCountryPicker': mapping不到countryCode閃退
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? "")
        guard let localisedCountryName = locale.localizedString(forRegionCode: code) else {
            return nil
        }
        
        return Country(countryCode: code)
    }
    
    func validateProduct() -> Bool {
        //Images
        if self.imageData.isEmpty {
            self.tableview.scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: true)
            showAlert(title: nil, message: "Input images".localized())
            return false
        }
        
        //Title
        if isEmptyValid(self.newProduct.title) {
            self.tableview.scrollToRow(at: IndexPath(row: 0, section: 1), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 0, section: 1)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input product title".localized())
                }
            }
            return false
        }
        
        //Intro
        if isEmptyValid(self.newProduct.intro) {
            self.tableview.scrollToRow(at: IndexPath(row: 1, section: 1), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 1, section: 1)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input product intro".localized())
                }
            }
            return false
        }
        
        print("--------------------------------------------------")
        print("New product: \(self.newProduct)")
        print("--------------------------------------------------")
        return true
    }
    
    func gotoLUNTextView(indexPath: IndexPath) {
        let lunTextVC = LUNTextViewController(nibName: "LUNTextViewController", bundle: nil)
        lunTextVC.configure(indexPath: indexPath,
                            titleText: "Product intro".localized(),
                            placeholder: "Input product intro".localized(),
                            textLimit: 1000)
        lunTextVC.resultText = self.newProduct.intro
        lunTextVC.completionHandler = { (indexPath, text) in
            guard let indexPath = indexPath,
                  let text = text else { return }
            self.newProduct.intro = text
            self.tableview.reloadRows(at: [indexPath], with: .automatic)
        }
        self.navigationController?.pushViewController(lunTextVC, animated: true)
    }
    
    func gotoShareMapView() {
        let shareMapVC = ShareMapViewController(nibName: "ShareMapViewController", bundle: nil)
        shareMapVC.viewType = self.viewType
        shareMapVC.product = self.newProduct
        print("newProduct coordinate: [\(self.newProduct.latitude), \(self.newProduct.longitude)]")
        shareMapVC.completionHandler = { (address, latitude, longitude) in
            self.newProduct.latitude = latitude
            self.newProduct.longitude = longitude
            self.tableview.reloadRows(at: [IndexPath(row: 1, section: 2)], with: .automatic)
            print("newProduct coordinate: [\(self.newProduct.latitude), \(self.newProduct.longitude)]")
        }
        shareMapVC.modalPresentationStyle = .overCurrentContext
        self.present(shareMapVC, animated: true, completion: nil)
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
            self.newProduct.countryCode = country.countryCode
            print("newProduct countryCode: \(country.countryCode)")
            self.tableview.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .automatic)
        }
    }
    
    //MARK: Action
    @objc func timeChanged(_ sender: UITextField) {
        //tag=111 開始時間
        //tag=222 結束時間
        guard let tag = self.activeTextField?.tag else { return }
        self.activeTextField?.text = datepicker.date.convertString(format: .yyyyMMdd)
        
        if tag == 111 {
            self.newProduct.startDate = datepicker.date.convertString(format: .Server)
            
        }else if tag == 222 {
            self.newProduct.endDate = datepicker.date.convertString(format: .Server)
        }
    }
    
    @objc func timeConfirm() {
        //tag=111 開始時間
        //tag=222 結束時間
        guard let tag = self.activeTextField?.tag else { return }
        self.activeTextField?.text = datepicker.date.convertString(format: .yyyyMMdd)
        
        if tag == 111 {
            self.newProduct.startDate = datepicker.date.convertString(format: .Server)
            
        }else if tag == 222 {
            self.newProduct.endDate = datepicker.date.convertString(format: .Server)
        }
        self.view.endEditing(true)
    }
    
    @objc func timeClear() {
        //tag=111 開始時間
        //tag=222 結束時間
        guard let tag = self.activeTextField?.tag else { return }
        self.activeTextField?.text = nil
        
        if tag == 111 {
            self.newProduct.startDate = nil
            
        }else if tag == 222 {
            self.newProduct.endDate = nil
        }
        self.view.endEditing(true)
    }
    
    @objc func createAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateProduct() {
            //建立資料
            //上傳圖片
            showAlert(title: nil, message: "Confirm create?".localized(), showCancel: true) {
                self.showActivityIndicator()
                ProductService.shared.createProduct(product: self.newProduct) { productId in
                    print("createProduct successfully...")
                    let dispatchGroup = DispatchGroup()
                    
                    //Upload Images
                    if !self.imageData.isEmpty {
                        let file = File(customId: productId, type: .PRODUCT)
                        let images = self.imageData.compactMap({ $0.image })
                        dispatchGroup.enter()
                        FileService.shared.uploadImages(file: file, images: images, completionHandler: {
                            print("uploadImages Successfully...")
                            dispatchGroup.leave()
                        })
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        NotificationCenter.default.post(name: .updateProductCompleted, object: nil, userInfo: nil)
                        self.hideActivityIndicator()
                        self.showAlert(title: "Congratulation".localized(), message: "Create successfully".localized()) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    @objc func updateAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateProduct() {
            //更新資料
            //上傳圖片
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                let dispatchGroup = DispatchGroup()
                self.showActivityIndicator()
                
                dispatchGroup.enter()
                ProductService.shared.updateProduct(product: self.newProduct) {
                    print("updateProduct successfully...")
                    dispatchGroup.leave()
                }
                
                //Delete Image Files
                let fileIds = self.imageData.compactMap({ $0.file }).map({ $0.fileId })
                let deleteIds = self.deleteImageData.compactMap({ $0.file }).map({ $0.fileId })
                if !fileIds.isEmpty || !deleteIds.isEmpty {
                    dispatchGroup.enter()
                    FileService.shared.deleteFiles(fileIds: fileIds + deleteIds) {
                        print("deleteFiles successfully...")
                        dispatchGroup.leave()
                    }
                }
                
                //Upload Images
                if !self.imageData.isEmpty {
                    let file = File(customId: self.newProduct.productId, type: .PRODUCT)
                    let images = self.imageData.compactMap({ $0.image })
                    dispatchGroup.enter()
                    FileService.shared.uploadImages(file: file, images: images) {
                        print("uploadImages successfully...")
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    NotificationCenter.default.post(name: .updateProductCompleted, object: nil, userInfo: nil)
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(), message: "Update successfully".localized()) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

//MARK: Keyboard
extension NewProductViewController {
    func registerKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWasShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let duration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
            let padding: CGFloat = getPadding()
            
            UIView.animate(withDuration: duration) {
                self.tableview.contentInset = UIEdgeInsets(top: self.tableview.contentInset.top, left: 0, bottom: keyboardFrame.size.height + padding, right: 0)
                
                // If active text field is hidden by keyboard, scroll it so it's visible
                // Your app might not need or want this behavior.
                var aRect = self.tableview.frame
                aRect.size.height -= keyboardFrame.size.height
                if let textField = self.activeTextField {
                    if !aRect.contains(textField.frame.origin) {
                        self.tableview.scrollRectToVisible(textField.frame, animated: true)
                    }
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        self.tableview.contentInset = contentInsets
        self.tableview.scrollIndicatorInsets = contentInsets
    }
    
    func removeKeyboardNotifications() {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIWindow.keyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
    }
}

//MARK: UITableViewDelegate
extension NewProductViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = images
        //1 = title, intro
        //2 = countryCode, coordinate
        //3 = date, url
        //4 = price
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        
        case 1:
            return 2
        
        case 2:
            return 2
            
        case 3:
            return 2
            
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNImagesCell", for: indexPath) as! LUNImagesCell
            cell.configure(data: self.imageData,
                           max: self.maxCount)
            cell.delegate = self
            return cell
            
        case 1:
            switch row {
            case 0: //Title
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Product title".localized()
                cell.textField.text = self.newProduct.title
                cell.textField.placeholder = "Product title".localized()
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                return cell
                
            case 1: //Intro
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Product intro".localized()
                cell.textField.text = self.newProduct.intro
                cell.textField.placeholder = "Product intro".localized()
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                return cell
                
            default:
                break
            }
            return UITableViewCell()
            
        case 2:
            switch row {
            case 0: //Country
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Product country code".localized() + "(Optional)".localized()
                let country = getProductCountry()
                cell.textField.text = country?.countryName
                cell.leftImage = country?.flag
                
                cell.textField.placeholder = "Product country code".localized() + "(Optional)".localized()
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = false
                cell.tipMessage = "Product country code tip".localized()
                return cell
                
            case 1: //Coordinate
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNShareMapViewCell", for: indexPath) as! LUNShareMapViewCell
                print("newProduct coordinate: [\(self.newProduct.latitude), \(self.newProduct.longitude)]")
                cell.configure(countryCode: nil,
                               latitude: self.newProduct.latitude,
                               longitude: self.newProduct.longitude,
                               meters: 3000)
                cell.noteLbl.text = "Product coordinate".localized() + "(Optional)".localized()
                return cell
                
            default:
                break
            }
            return UITableViewCell()
            
        case 3:
            switch row {
            case 0: //Date
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTwoTextFieldCell", for: indexPath) as! LUNTwoTextFieldCell
                let title = self.productType == .WISH ? "Wish date".localized() : "Buy date".localized()
                cell.titleLbl.text = title + "(Optional)".localized()
                cell.questionBtn.isHidden = false
                cell.tipMessage = "Product date tip".localized()
                
                //Start date
                cell.oneTextField.text = self.newProduct.startDate?.convertString(origin: .Server, result: .yyyyMMdd)
                cell.oneTextField.placeholder = "Start".localized()
                cell.oneTextField.delegate = self
                cell.oneTextField.section = section
                cell.oneTextField.row = row
                cell.oneTextField.tag = 111
                cell.oneTextField.inputView = datepicker
                cell.oneTextField.inputAccessoryView = toolBar
            
                //End date
                cell.twoTextField.text = self.newProduct.endDate?.convertString(origin: .Server, result: .yyyyMMdd)
                cell.twoTextField.placeholder = "End".localized()
                cell.twoTextField.delegate = self
                cell.twoTextField.section = section
                cell.twoTextField.row = row
                cell.twoTextField.tag = 222
                cell.twoTextField.inputView = datepicker
                cell.twoTextField.inputAccessoryView = toolBar
                return cell
                
            case 1: //Web URL
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Product webUrl".localized() + "(Optional)".localized()
                cell.textField.text = self.newProduct.webUrl
                cell.textField.placeholder = "Product webUrl".localized() + "(Optional)".localized()
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = false
                cell.tipMessage = "Product webUrl tip".localized()
                return cell
                
            default:
                break
            }
            return UITableViewCell()
            
        case 4:
            //Price
            let cell = tableview.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
            cell.titleLbl.text = "Product price".localized() + "(Optional)".localized()
            if let price = self.newProduct.price,
               price != 0 {
                cell.textField.text = "$ \(price.priceFormatting())"
            }else {
                cell.textField.text = nil
            }
            cell.textField.placeholder = "Product price".localized() + "(Optional)".localized()
            cell.textField.keyboardType = .numberPad
            cell.textField.returnKeyType = .done
            cell.textField.delegate = self
            cell.textField.section = section
            cell.textField.row = row
            cell.questionBtn.isHidden = false
            cell.tipMessage = "Product price tip".localized()
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
        case (2, 1):
            gotoShareMapView()
        
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        let row = indexPath.row
        
        switch (section, row) {
        case (0, 0):
            return 300
            
        case (2, 1):
            return 150
            
        default:
            break
        }
        return UITableView.automaticDimension
    }
}

//MARK: LUNImagesCellDelegate
extension NewProductViewController: LUNImagesCellDelegate {
    func didSelectImages(data: [ImageFileData]) {
        self.imageData = data
        DispatchQueue.main.async {
            self.tableview.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
    
    func didDeleteImage(index: Int) {
        let data = self.imageData[index]
        self.deleteImageData.append(data)
        self.imageData.remove(at: index)
        DispatchQueue.main.async {
            self.tableview.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }
}

//MARK: UITextFieldDelegate
extension NewProductViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let section = textField.section
        let row = textField.row
        switch (section, row) {
        case (1, 1):
            gotoLUNTextView(indexPath: IndexPath(row: row, section: section))
            return false
            
        case (2, 0):
            gotoCountryPickerView()
            return false
            
        default:
            break
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let section = textField.section
        let row = textField.row
        activeTextField = textField
        activeIndexPath = IndexPath(row: row, section: section)
        
        switch (section, row) {
        case (4, 0):
            //price: 有加"$"必須重新輸入
            textField.text = nil
            
        default:
            break
        }
        
        //TextField inactive
        if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTextFieldCell {
            cell.inactive()
            
        }else if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTwoTextFieldCell {
            let index = textField.tag == 111 ? 1 : 2
            cell.inactive(index: index)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let section = textField.section
        let row = textField.row
        activeTextField = nil
        activeIndexPath = nil
        
        guard let text = textField.text else { return }
        switch (section, row) {
        case (1, 0): //"Title"
            self.newProduct.title = text
            
        case (3, 1): //"WebUrl"
            self.newProduct.webUrl = text
            
        case (4, 0): //"Price"
            if let price = Double(text) {
                textField.text = "$ \(price.priceFormatting())"
                self.newProduct.price = price
                
            }else {
                textField.text = nil
                self.newProduct.price = nil
            }
            
        default:
            break
        }
        
        //TextField deactive
        if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTextFieldCell {
            cell.deactive()
            
        }else if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTwoTextFieldCell {
            let index = textField.tag == 111 ? 1 : 2
            cell.deactive(index: index)
        }
    }
}
