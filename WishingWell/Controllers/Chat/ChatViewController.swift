//
//  ChatViewController.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2023/12/20.
//  Copyright © 2023 LunYuChang. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import AVFoundation
import AVKit
import CoreLocation
import YPImagePicker

internal class ChatViewController: MessagesViewController {
    var headerView = ChatHeaderView()
    let addOrderBtn = InputBarButtonItem()
    
    //Configuration
    private var conversation: Conversation
    private var activeProduct: Product? {
        didSet {
            self.setActiveProductHeaderView()
            self.checkAddOrderBtn()
        }
    }
    var isAddToChat = false //從商品頁詢問：activeProduct初次不依message資料置換
    
    //Data
    private var messageData: [MessageData] = []
    private var selfSender: Sender? {
        guard let user = UserService.shared.currentUser else { return nil }
        return Sender(senderId: "\(user.userId)",
                      displayName: user.account,
                      user: user)
    }
    
    //建立訂單會有WebSocket連線問題，需建立連線後再送資料
    var sendOrderData: MessageData?
    
    init(conversation: Conversation, product: Product?) {
        self.conversation = conversation
        self.activeProduct = product
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: MyCustomMessagesFlowLayout())
        messagesCollectionView.register(MyCustomCell.self)
        super.viewDidLoad()
        
        navigationItem.title = "Chat".localized()
        setupLayout()
        setActiveProductHeaderView()
        checkAddOrderBtn()
        
        getMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerKeyboardNotifications()
        showNavigationBar()
        hideTabBar()
        
        ChatWebSocket.shared.setWebSocket(type: .MESSAGE)
        ChatWebSocket.shared.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeKeyboardNotifications()
        ChatWebSocket.shared.disconnect()
    }
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        //before checking the messages check if section is reserved for typing otherwise it will cause IndexOutOfBounds error
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
        
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        switch message.kind {
        case .custom(let custom):
            let cell = messagesCollectionView.dequeueReusableCell(MyCustomCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            
            cell.orderMessageView.lookBtn.section = indexPath.section
            cell.orderMessageView.lookBtn.row = indexPath.row
            cell.orderMessageView.lookBtn.setTitle("Look".localized(), for: .normal)
            cell.orderMessageView.lookBtn.addTarget(self, action: #selector(lookOrderAction(_:)), for: .touchUpInside)
            
            //檢查更新和接受Button: 建立訂單者可以修改訂單，非建立者接受
            if let item = custom as? OrderItem {
                cell.orderMessageView.acceptBtn.section = indexPath.section
                cell.orderMessageView.acceptBtn.row = indexPath.row
                cell.orderMessageView.acceptBtn.addTarget(self, action: #selector(updateOrderAction(_:)), for: .touchUpInside)
                
                //isOrderOwner = true
                let currentUserId = UserService.shared.currentUser?.userId
                if currentUserId == item.orderUserId {
                    cell.orderMessageView.acceptBtn.setTitle("Update".localized(), for: .normal)
                    
                //isOrderOwner = false
                //訂購人：一開始是接受訂單，同意後可以更新訂單
                }else {
                    let status = OrderStatus(rawValue: item.orderStatus)
                    if status == .DISCUSSING {
                        cell.orderMessageView.acceptBtn.setTitle("Accept".localized(), for: .normal)
                        
                    }else {
                        cell.orderMessageView.acceptBtn.setTitle("Update".localized(), for: .normal)
                    }
                }
            }
            return cell
            
        default:
            break
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    func setupLayout() {
        //Header View
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 92).isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapAction))
        headerView.addGestureRecognizer(tap)
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        //Set Message Input Bar
        setMessageInputBar()
    }
    
    func setActiveProductHeaderView() {
        if let product = self.activeProduct {
            messagesCollectionView.contentInset.top = 92
            headerView.configure(product: product)
            headerView.alpha = 1
            
        }else {
            messagesCollectionView.contentInset.top = 0
            headerView.alpha = 0
        }
    }
    
    func checkAddOrderBtn() {
        //檢查新增訂單Button: 只有代購人可以新增訂單
        let type = UserType(rawValue: UserService.shared.currentUser?.userType ?? 0)
        if type == .WISHER {
            addOrderBtn.tintColor = .lightGray
            
        }else {
            addOrderBtn.tintColor = .label
        }
    }
    
    func setMessageInputBar() {
        addOrderBtn.setSize(CGSize(width: 32, height: 32), animated: false)
        let addImg = UIImage(systemName: "doc.badge.plus", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withRenderingMode(.alwaysTemplate)
        addOrderBtn.setImage(addImg, for: .normal)
        addOrderBtn.imageView?.contentMode = .scaleAspectFit
        addOrderBtn.onTouchUpInside { [weak self] _ in
            let type = UserType(rawValue: UserService.shared.currentUser?.userType ?? 0)
            if type == .WISHER {
                self?.showAlert(title: nil, message: "Must become a buyer".localized(), showCancel: true, confirmTitle: "Move".localized()) {
                    self?.gotoBecomeBuyerView()
                }
                
            }else {
                self?.gotoNewOrderView(type: .Create, order: nil)
            }
        }
        
        let imgBtn = InputBarButtonItem()
        imgBtn.setSize(CGSize(width: 32, height: 32), animated: false)
        let photoImg = UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.label, renderingMode: .alwaysOriginal)
        imgBtn.setImage(photoImg, for: .normal)
        imgBtn.imageView?.contentMode = .scaleAspectFit
        imgBtn.onTouchUpInside { [weak self] _ in
            self?.messageInputBar.inputTextView.resignFirstResponder()
            self?.photoPickerAction()
        }
        
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        messageInputBar.inputTextView.layer.borderColor = UIColor.lightGray.cgColor
        messageInputBar.inputTextView.layer.borderWidth = 0.25
        messageInputBar.inputTextView.layer.cornerRadius = 16.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.setLeftStackViewWidthConstant(to: 80, animated: false)
        messageInputBar.setStackViewItems([addOrderBtn, InputBarButtonItem.fixedSpace(4), imgBtn, InputBarButtonItem.fixedSpace(4)],
                                          forStack: .left,
                                          animated: false)
        messageInputBar.shouldAnimateTextDidChangeLayout = false
        //leftStackView icons 對齊中間
        messageInputBar.leftStackView.alignment = .center
    }
    
    func openImagePicker() {
        var config = YPImagePickerConfiguration()
        config.onlySquareImagesFromCamera = false
        config.startOnScreen = YPPickerScreen.library
        
        let picker = YPImagePicker(configuration: config)
        //issue: YPImagePicker會導致NavigationBar跑版，必須設定modalPresentationStyle
        picker.modalPresentationStyle = .overFullScreen
        picker.didFinishPicking { [unowned picker] items, _ in
            if let image = items.singlePhoto?.image {
                //上傳圖片
                //Send Message
                let fileName = "photo_message_" + UUID().uuidString
                FileService.shared.uploadImage(fileName: fileName, image: image) { imageUrl in
                    guard let url = URL(string: imageUrl),
                          let placeholder = UIImage(systemName: "photo"),
                          let sender = self.selfSender else { return }
                    
                    let media = Media(url: url,
                                      image: image,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 240))
                    let data = MessageData(sender: sender,
                                           kind: .photo(media),
                                           productId: self.activeProduct?.productId,
                                           orderId: nil)
                    self.sendMessage(data)
                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func gotoNewOrderView(type: ViewType, order: Order?) {
        let newOrderVC = NewOrderViewController(nibName: "NewOrderViewController", bundle: nil)
        newOrderVC.viewType = type
        newOrderVC.order = order
        newOrderVC.delegate = self
        
        //檢查是不是Product Owner才能帶入
        if order?.product == nil,
           UserService.shared.currentUser?.userId == self.activeProduct?.userId {
            newOrderVC.orderProduct = self.activeProduct
        }
        
        self.navigationController?.pushViewController(newOrderVC, animated: true)
    }
    
    func gotoBecomeBuyerView() {
        let becomeBuyerVC = BecomeBuyerViewController(nibName: "BecomeBuyerViewController", bundle: nil)
        self.navigationController?.pushViewController(becomeBuyerVC, animated: true)
    }
    
    //MARK: Action
    func photoPickerAction() {
        let manager = PermissionsManager()
        manager.requestPermission(.photoLibrary) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.openImagePicker()
                
                }else {
                    self.showOpenSetting(title: nil, message: "Open camera permission".localized())
                }
            }
        }
    }
    
    @objc func headerTapAction() {
        guard let product = self.activeProduct else { return }
        self.showProductDetailView(type: .Watch, product: product, productUser: product.user)
    }
    
    @objc func lookOrderAction(_ sender: UIButton) {
        let indexPath = IndexPath(row: sender.row, section: sender.section)
        guard let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageData,
              let orderId = message.orderId else { return }
        self.showActivityIndicator()
        OrderService.shared.getOrder(orderId: orderId) { data in
            self.hideActivityIndicator()
            if let order = data {
                self.showOrderDetailView(type: .Watch, order: order)
            }
        }
    }
    
    @objc func updateOrderAction(_ sender: UIButton) {
        let indexPath = IndexPath(row: sender.row, section: sender.section)
        guard let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? MessageData,
              let orderId = message.orderId else { return }
        self.showActivityIndicator()
        OrderService.shared.getOrder(orderId: orderId) { data in
            self.hideActivityIndicator()
            if let order = data {
                self.gotoNewOrderView(type: .Update, order: order)
            }
        }
    }
}

//MARK: URLSessionWebSocketDelegate
extension ChatViewController: ChatWebSocketDelegate {
    func didConnect() {
        if let data = self.sendOrderData {
            self.sendOrderData = nil
            self.sendMessage(data)
        }
    }
    
    func didReceive(chat: Chat) {
        guard let msg = chat.message else { return }
        
        let data = MessageData(msg: msg)
        DispatchQueue.main.async {
            self.messageData.append(data)
            self.messagesCollectionView.reloadDataAndKeepOffset()
            
            NotificationCenter.default.post(name: .updateLatestMessage,
                                            object: nil,
                                            userInfo: [MyKey.UserInfo.latestMessage: msg])
        }
    }
}

//MARK: NewOrderViewControllerDelegate
extension ChatViewController: NewOrderViewControllerDelegate {
    func didCreate(order: Order) {
        guard let sender = self.selfSender else { return }
        let item = OrderItem(order: order)
        //建立訂單訊息：productId依訂單的productId為主
        let data = MessageData(sender: sender,
                               kind: .custom(item),
                               productId: order.productId,
                               orderId: order.orderId)
        self.sendOrderData = data
    }
    
    func didUpdate(order: Order) {
        guard let sender = self.selfSender else { return }
        let item = OrderItem(order: order)
        //建立訂單訊息：productId依訂單的productId為主
        let data = MessageData(sender: sender,
                               kind: .custom(item),
                               productId: order.productId,
                               orderId: order.orderId)
        self.sendOrderData = data
    }
}

//MARK: Keyboard
extension ChatViewController {
    func registerKeyboardNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWasShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func removeKeyboardNotifications () {
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShow(notification: NSNotification) {
        self.messagesCollectionView.scrollToLastItem()
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
    }
}

//MARK: InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let sender = self.selfSender else { return }
        
        //檢查是否有Link
        if let extractURL = text.extractURLs().first {
            guard let url = URL(string: extractURL),
                  let image = UIImage(systemName: "macwindow")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
            let link = Link(text: text,
                            url: url,
                            teaser: url.absoluteString,
                            thumbnailImage: image)
            let data = MessageData(sender: sender,
                                   kind: .linkPreview(link),
                                   productId: self.activeProduct?.productId,
                                   orderId: nil)
            self.sendMessage(data)
            
        }else {
            let data = MessageData(sender: sender,
                                   kind: .text(text),
                                   productId: self.activeProduct?.productId,
                                   orderId: nil)
            self.sendMessage(data)
        }
    }
}

//MARK: MessagesDataSource
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = self.selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil...")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageData[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageData.count
    }

    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url?.absoluteString else { return }
            imageView.image = nil
            FileService.shared.getImage(url: imageUrl) { image in
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
            
        default:
            break
        }
    }

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
            
        }else {
            return .secondarySystemBackground
        }
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let sender = message.sender as? Sender,
              let user = sender.user else { return }
        
        avatarView.image = nil
        guard let fileId = user.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId else { return }
        FileService.shared.getImage(fileId: fileId) { image in
            DispatchQueue.main.async {
                avatarView.image = image
            }
        }
    }
}

//MARK: MessageCellDelegate
extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let data = messageData[indexPath.section]

        switch data.kind {
        case .location(_):
            print("location view...")
            
        case .linkPreview(let link):
            OpenManager.shared.openURL(url: link.url.absoluteString)
            
        default:
            break
        }
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let data = messageData[indexPath.section]

        switch data.kind {
        case .photo(let media):
            guard let imageUrl = media.url?.absoluteString else { return }
            
            FileService.shared.getImage(url: imageUrl) { image in
                DispatchQueue.main.async {
                    self.showPhotoViewerView(images: [image])
                }
            }
            
        case .video(let media):
            guard let videoUrl = media.url else { return }

            let avPlayerVC = AVPlayerViewController()
            avPlayerVC.player = AVPlayer(url: videoUrl)
            present(avPlayerVC, animated: true)
            
        default:
            break
        }
    }
}

//MARK: Server
extension ChatViewController {
    func getMessages() {
        let conversationId = self.conversation.conversationId
        guard conversationId != 0 else { return }
        
        self.showActivityIndicator()
        MessageService.shared.getMessages(conversationId: conversationId) { data in
            let msgs: [MessageData] = data.compactMap { msg in
                return MessageData(msg: msg)
            }
            self.messageData = msgs
            
            self.hideActivityIndicator()
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem()
            
            if let msg = data.last {
                NotificationCenter.default.post(name: .updateLatestMessage,
                                                object: nil,
                                                userInfo: [MyKey.UserInfo.latestMessage: msg])
            }
        }
    }
    
    func sendMessage(_ messageData: MessageData) {
        print("sendMessage: \(messageData)")
        let msg = Message(conversationId: self.conversation.conversationId, data: messageData)
        let chat = Chat(conversation: self.conversation,
                        message: msg)
        
        guard let text = chat.toString() else { return }
        print("Write chat: \(text)")
        ChatWebSocket.shared.socket?.write(string: text, completion: {
            DispatchQueue.main.async {
                self.messageInputBar.inputTextView.text = nil
                
                self.messageData.append(messageData)
                self.messagesCollectionView.reloadDataAndKeepOffset()
                
                NotificationCenter.default.post(name: .updateLatestMessage,
                                                object: nil,
                                                userInfo: [MyKey.UserInfo.latestMessage: msg])
            }
        })
    }
}
