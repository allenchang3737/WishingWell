//
//  NewOrderViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/26.
//

import UIKit

protocol NewOrderViewControllerDelegate {
    func didCreate(order: Order)
    func didUpdate(order: Order)
}

class NewOrderViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var buttonview: LUNButtonView!
    @IBOutlet var datepicker: UIDatePicker!
    @IBOutlet var typepicker: UIPickerView!
    var dateToolBar = UIToolbar()
    var typeToolBar = UIToolbar()
    private var dealTypes: [DealType] = [.FACETOFACE, .PLATFORM_7ELEVEN, .PLATFORM_FAMILYMART, .PLATFORM_HILIFE]
    
    //Configuration
    var viewType: ViewType = .Create
    var order: Order?
    var orderProduct: Product?
    
    //Data
    private var newOrder = Order()
    private var productImage: UIImage? {
        didSet {
            DispatchQueue.main.async {
                self.tableview.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            }
        }
    }
    private var isOrderOwner: Bool {
        get {
            let currentUserId = UserService.shared.currentUser?.userId
            if currentUserId == self.newOrder.orderUserId {
                return true
            }else {
                return false
            }
        }
    }
    
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
    
    var delegate: NewOrderViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        switch self.viewType {
        case .Create:
            self.newOrder.orderUserId = UserService.shared.currentUser?.userId ?? 0
            self.newOrder.product = self.orderProduct
            self.newOrder.productId = self.orderProduct?.productId ?? 0
            
        case .Update:
            guard let order = self.order else { return }
            print("--------------------------------------------------")
            print("Update order: \(order)")
            print("--------------------------------------------------")
            self.newOrder = order
            
        default:
            break
        }
        
        setupLayout()
        setProductImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotifications()
        showNavigationBar()
        hideTabBar()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
    }

    func setupLayout() {
        //Table View
        tableview.register(UINib(nibName: "LUNTextFieldCell", bundle: nil), forCellReuseIdentifier: "LUNTextFieldCell")
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            tableview.sectionHeaderTopPadding = 0.0
        }
        
        //Date picker
        datepicker.date = Date()
        datepicker.minimumDate = Date()
        datepicker.datePickerMode = .date
        datepicker.addTarget(self, action: #selector(timeChanged), for: .valueChanged)
        dateToolBar.frame = CGRect(x: 0, y: self.datepicker.frame.height, width: self.view.frame.width, height: 44)
        dateToolBar.toolbarPicker(target: self, selector: #selector(timeConfirm),
                                  targetClear: self, selectorClear:  #selector(timeClear))
        
        //Type picker
        typepicker.dataSource = self
        typepicker.delegate = self
        typeToolBar.frame = CGRect(x: 0, y: self.typepicker.frame.height, width: self.view.frame.width, height: 44)
        typeToolBar.toolbarPicker(target: self, selector: #selector(typeConfirm))
        
        //Button View
        switch self.viewType {
        case .Create:
            navigationItem.title = "Create".localized() + "Order".localized()
            buttonview.button.setTitle("Create".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(createAction), for: .touchUpInside)
            
        case .Update:
            if isOrderOwner {
                buttonview.button.setTitle("Update".localized(), for: .normal)
                buttonview.button.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
                
            }else {
                //訂購人：一開始是接受訂單，同意後可以更新訂單
                let status = OrderStatus(rawValue: self.newOrder.status)
                if status == .DISCUSSING {
                    navigationItem.title = "Accept".localized() + "Order".localized()
                    buttonview.button.setTitle("Accept".localized(), for: .normal)
                    buttonview.button.addTarget(self, action: #selector(acceptAction), for: .touchUpInside)
                    
                }else {
                    navigationItem.title = "Update".localized() + "Order".localized()
                    buttonview.button.setTitle("Update".localized(), for: .normal)
                    buttonview.button.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
                }
            }
            
        default:
            break
        }
    }
    
    func setProductImage() {
        if let fileId = self.newOrder.product?.files?.filter({ $0.type == FileType.PRODUCT.rawValue }).first?.fileId {
            FileService.shared.getImage(fileId: fileId) { image in
                self.productImage = image
            }
            
        }else {
            self.productImage = nil
        }
    }
    
    func validateOrder() -> Bool {
        //初始值
        //Order User Id
        if self.newOrder.orderUserId == 0 {
            self.tableview.scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 0, section: 0)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Error".localized())
                }
            }
            return false
        }
        
        //Product ID
        if self.newOrder.productId == 0 {
            self.tableview.scrollToRow(at: IndexPath(row: 0, section: 0), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 0, section: 0)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input order product".localized())
                }
            }
            return false
        }
        //Order Note
        if isEmptyValid(self.newOrder.orderNote) {
            self.tableview.scrollToRow(at: IndexPath(row: 1, section: 0), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 1, section: 0)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input order note".localized())
                }
            }
            return false
        }
        //Amount
        if self.newOrder.amount == 0 {
            self.tableview.scrollToRow(at: IndexPath(row: 2, section: 0), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 2, section: 0)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input order amount".localized())
                }
            }
            return false
        }
        //Deal Date
        if isEmptyValid(self.newOrder.dealDate) {
            self.tableview.scrollToRow(at: IndexPath(row: 3, section: 0), at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let cell = self.tableview.cellForRow(at: IndexPath(row: 3, section: 0)) as? LUNTextFieldCell {
                    cell.showErrorMessage(message: "Input order deal date".localized())
                }
            }
            return false
        }
        
        //Deal Type: 交易方式(雙方都可以編輯)
        if isOrderOwner {
            print("deal type: Optional...")
        }else {
            let type = DealType(rawValue: self.newOrder.dealType ?? 0)
            if type == nil {
                self.tableview.scrollToRow(at: IndexPath(row: 0, section: 1), at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    if let cell = self.tableview.cellForRow(at: IndexPath(row: 0, section: 1)) as? LUNTextFieldCell {
                        cell.showErrorMessage(message: "Input order deal type".localized())
                    }
                }
                return false
            }
        }
        
        if !isOrderOwner {
            //User Id
            self.newOrder.userId = UserService.shared.currentUser?.userId
            
            //User Name
            if isEmptyValid(self.newOrder.userName) {
                self.tableview.scrollToRow(at: IndexPath(row: 0, section: 2), at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    if let cell = self.tableview.cellForRow(at: IndexPath(row: 0, section: 2)) as? LUNTextFieldCell {
                        cell.showErrorMessage(message: "Input order user name".localized())
                    }
                }
                return false
            }
            //User Phone
            if !isPhoneValid(self.newOrder.userPhone) {
                self.tableview.scrollToRow(at: IndexPath(row: 1, section: 2), at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    if let cell = self.tableview.cellForRow(at: IndexPath(row: 1, section: 2)) as? LUNTextFieldCell {
                        cell.showErrorMessage(message: "Input order user phone".localized())
                    }
                }
                return false
            }
            //User Email
            if !isEmailValid(self.newOrder.userEmail) {
                self.tableview.scrollToRow(at: IndexPath(row: 2, section: 2), at: .middle, animated: true)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    if let cell = self.tableview.cellForRow(at: IndexPath(row: 2, section: 2)) as? LUNTextFieldCell {
                        cell.showErrorMessage(message: "Input order user email".localized())
                    }
                }
                return false
            }
        }
        print("--------------------------------------------------")
        print("New order: \(self.newOrder)")
        print("--------------------------------------------------")
        return true
    }
    
    func gotoLUNTextView(indexPath: IndexPath) {
        let lunTextVC = LUNTextViewController(nibName: "LUNTextViewController", bundle: nil)
        lunTextVC.configure(indexPath: indexPath,
                            titleText: "Order note".localized(),
                            placeholder: "Input order note".localized(),
                            textLimit: 1000)
        lunTextVC.resultText = self.newOrder.orderNote
        lunTextVC.completionHandler = { (indexPath, text) in
            guard let indexPath = indexPath,
                  let text = text else { return }
            self.newOrder.orderNote = text
            self.tableview.reloadRows(at: [indexPath], with: .automatic)
        }
        self.navigationController?.pushViewController(lunTextVC, animated: true)
    }
    
    func gotoProductListView() {
        let productListVC = ProductListViewController(nibName: "ProductListViewController", bundle: nil)
        productListVC.completionHandler = { product in
            self.newOrder.productId = product.productId
            self.newOrder.product = product
            self.setProductImage()
        }
        self.navigationController?.pushViewController(productListVC, animated: true)
    }
    
    //MARK: Action
    @objc func timeChanged(_ sender: UITextField) {
        self.activeTextField?.text = datepicker.date.convertString(format: .yyyyMMdd)
        self.newOrder.dealDate = datepicker.date.convertString(format: .Server)
    }
    
    @objc func timeConfirm() {
        self.activeTextField?.text = datepicker.date.convertString(format: .yyyyMMdd)
        self.newOrder.dealDate = datepicker.date.convertString(format: .Server)
        
        self.view.endEditing(true)
    }
    
    @objc func timeClear() {
        self.activeTextField?.text = nil
        self.newOrder.dealDate = ""
        
        self.view.endEditing(true)
    }
    
    @objc func typeConfirm() {
        let index = typepicker.selectedRow(inComponent: 0)
        let selected = self.dealTypes[index]
        self.activeTextField?.text = selected.rawValue.convertDealType()
        self.newOrder.dealType = selected.rawValue
        
        self.view.endEditing(true)
    }
    
    @objc func createAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateOrder() {
            //建立資料
            showAlert(title: nil, message: "Confirm create?".localized(), showCancel: true) {
                self.showActivityIndicator()
                OrderService.shared.createOrder(order: self.newOrder) { orderId in
                    self.hideActivityIndicator()
                    self.newOrder.orderId = orderId
                    self.showAlert(title: "Congratulation".localized(), message: "Create successfully".localized()) {
                        self.delegate?.didCreate(order: self.newOrder)
                        self.navigationController?.popViewController(animated: true)
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
        
        if validateOrder() {
            //更新資料
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                self.showActivityIndicator()
                OrderService.shared.updateOrder(order: self.newOrder) {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(), message: "Update successfully".localized()) {
                        NotificationCenter.default.post(name: .updateOrderCompleted, object: nil, userInfo: nil)
                        self.delegate?.didUpdate(order: self.newOrder)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    @objc func acceptAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateOrder() {
            //接受訂單
            showAlert(title: nil, message: "Confirm accept?".localized(), showCancel: true) {
                self.showActivityIndicator()
                OrderService.shared.acceptOrder(order: self.newOrder) {
                    self.hideActivityIndicator()
                    self.newOrder.status = OrderStatus.PROCESSING.rawValue
                    self.showAlert(title: "Congratulation".localized(), message: "Update successfully".localized()) {
                        NotificationCenter.default.post(name: .updateOrderCompleted, object: nil, userInfo: nil)
                        self.delegate?.didUpdate(order: self.newOrder)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

//MARK: Keyboard
extension NewOrderViewController {
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
extension NewOrderViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        //0 = productId, orderNote, amount, dealDate
        //1 = dealType
        //2 = userName, userPhone, userEmail
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        
        case 1:
            return 1
        
        case 2:
            return 3
        
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        switch section {
        case 0:
            switch row {
            case 0: //productId
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order product".localized()
                cell.textField.text = self.newOrder.product?.title
                cell.leftImage = self.productImage
                
                cell.textField.placeholder = "Order product".localized()
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                cell.textField.isEnabled = isOrderOwner
                return cell
                
            case 1: //orderNote
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order note".localized()
                cell.textField.text = self.newOrder.orderNote
                cell.textField.placeholder = "Order note".localized()
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                cell.textField.isEnabled = isOrderOwner
                return cell
                
            case 2: //amount
                let cell = tableview.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order amount".localized()
                if self.newOrder.amount != 0 {
                    cell.textField.text = "$ \(self.newOrder.amount.priceFormatting())"
                }else {
                    cell.textField.text = nil
                }
                cell.textField.placeholder = "Order amount".localized()
                cell.textField.keyboardType = .numberPad
                cell.textField.returnKeyType = .done
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                cell.textField.isEnabled = isOrderOwner
                return cell
                
            case 3: //dealDate
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order deal date".localized()
                cell.textField.text = self.newOrder.dealDate.convertString(origin: .Server, result: .yyyyMMdd)
                cell.textField.placeholder = "Order deal date".localized()
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.textField.inputView = datepicker
                cell.textField.inputAccessoryView = dateToolBar
                cell.questionBtn.isHidden = true
                cell.textField.isEnabled = isOrderOwner
                return cell
                
            default:
                break
            }
            
        case 1: //dealType
            let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
            cell.titleLbl.text = "Order deal type".localized() + (isOrderOwner ? "(Optional)".localized() : "")
            cell.textField.text = self.newOrder.dealType?.convertDealType()
            cell.textField.placeholder = "Order deal type".localized() + (isOrderOwner ? "(Optional)".localized() : "")
            cell.textField.delegate = self
            cell.textField.section = section
            cell.textField.row = row
            cell.textField.inputView = typepicker
            cell.textField.inputAccessoryView = typeToolBar
            cell.questionBtn.isHidden = true
            return cell
            
        case 2:
            switch row {
            case 0: //userName
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order user name".localized()
                cell.textField.text = self.newOrder.userName
                cell.textField.placeholder = "Order user name".localized()
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                return cell
                
            case 1: //userPhone
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order user phone".localized()
                cell.textField.text = self.newOrder.userPhone
                cell.textField.placeholder = "Order user phone".localized()
                cell.textField.keyboardType = .numberPad
                cell.textField.returnKeyType = .next
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                return cell
                
            case 2: //userEmail
                let cell = tableView.dequeueReusableCell(withIdentifier: "LUNTextFieldCell", for: indexPath) as! LUNTextFieldCell
                cell.titleLbl.text = "Order user email".localized()
                cell.textField.text = self.newOrder.userEmail
                cell.textField.placeholder = "Order user email".localized()
                cell.textField.keyboardType = .emailAddress
                cell.textField.returnKeyType = .done
                cell.textField.delegate = self
                cell.textField.section = section
                cell.textField.row = row
                cell.questionBtn.isHidden = true
                return cell
                
            default:
                break
            }
            
        default:
            break
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section
        //建立訂單不需要輸入用戶資訊
        if self.viewType == .Create,
           isOrderOwner,
           section == 2 {
            return 0
            
        }else {
            return UITableView.automaticDimension
        }
    }
}

//MARK: UITextFieldDelegate
extension NewOrderViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let section = textField.section
        let row = textField.row
        switch (section, row) {
        case (0, 0):
            gotoProductListView()
            return false
            
        case (0, 1):
            gotoLUNTextView(indexPath: IndexPath(row: row, section: section))
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
        case (0, 2):
            //amount: 有加"$"必須重新輸入
            textField.text = nil
            
        default:
            break
        }
        
        //TextField inactive
        if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTextFieldCell {
            cell.inactive()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let section = textField.section
        let row = textField.row
        activeTextField = nil
        activeIndexPath = nil
        
        guard let text = textField.text else { return }
        switch (section, row) {
        case (0, 2): //Amount
            if let amount = Double(text) {
                textField.text = "$ \(amount.priceFormatting())"
                self.newOrder.amount = amount
                
            }else {
                textField.text = nil
                self.newOrder.amount = 0
            }
            
        case (2, 0): //userName
            self.newOrder.userName = text
            
        case (2, 1): //userPhone
            self.newOrder.userPhone = text
            
        case (2, 2): //userEmail
            self.newOrder.userEmail = text
            
        default:
            break
        }
        
        //TextField deactive
        if let cell = self.tableview.cellForRow(at: IndexPath(row: row, section: section)) as? LUNTextFieldCell {
            cell.deactive()
        }
    }
}

//MARK: UIPickerViewDelegate
extension NewOrderViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dealTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dealTypes[row].rawValue.convertDealType()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selected = self.dealTypes[row]
        self.newOrder.dealType = selected.rawValue
        self.activeTextField?.text = selected.rawValue.convertDealType()
        self.view.endEditing(true)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
}
