//
//  ConversationsViewController.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/25.
//

import UIKit

class ConversationsViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var searchbar: UISearchBar!
    
    //Data
    var allConvs: [Conversation] = []
    var activeConvs: [Conversation] = []
    
    var searchText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        getConversations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        registerNotifications()
        showNavigationBar()
        hideTabBar()
        
        ChatWebSocket.shared.setWebSocket(type: .CONVERSATION)
        ChatWebSocket.shared.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ChatWebSocket.shared.disconnect()
    }
    
    deinit {
        removeNotifications()
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLatestMessageHandler(notification:)), name: .updateLatestMessage, object: nil)
    }
    
    func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .updateLatestMessage, object: nil)
    }
    
    @objc func updateLatestMessageHandler(notification: Notification) {
        guard var msg = notification.userInfo?[MyKey.UserInfo.latestMessage] as? Message else { return }
        msg.isRead = true
        
        if let index = self.allConvs.firstIndex(where: { $0.conversationId == msg.conversationId }) {
            self.allConvs[index].latestMessage = msg
            setActiveConversations()
        }
    }
    
    func setupLayout() {
        tableview.register(UINib(nibName: "ConversationCell", bundle: nil), forCellReuseIdentifier: "ConversationCell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = UITableView.automaticDimension
        tableview.tableFooterView = UIView()
        
        //Set Search Bar
        searchbar.placeholder = "Search".localized()
        searchbar.delegate = self
        definesPresentationContext = true
    }
    
    func setActiveConversations() {
        //內部搜尋
        if let text = self.searchText,
           !text.isEmpty {
            self.activeConvs = self.allConvs.filter({ conv in
                let account = conv.users?.first?.account ?? ""
                return account.containsIgnoringCase(find: text)
            })
            
        }else {
            self.activeConvs = self.allConvs
        }
        
        DispatchQueue.main.async {
            self.tableview.reloadData()
        }
    }
    
    func gotoChatView(_ conv: Conversation) {
        let chatVC = ChatViewController(conversation: conv, product: nil)
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}

//MARK: URLSessionWebSocketDelegate
extension ConversationsViewController: ChatWebSocketDelegate {
    func didConnect() {
        print("didConnect...")
    }
    
    func didReceive(chat: Chat) {
        guard var conv = chat.conversation,
              let msg = chat.message,
              let senderUser = msg.senderUser else { return }
        //更新聊天室裡的User: 若有群組聊天需調整
        conv.users = [senderUser]
        
        //更新聊天室最新訊息
        conv.latestMessage = msg
        
        //更新
        if let index = self.allConvs.firstIndex(where: { $0.conversationId == conv.conversationId }) {
            self.allConvs[index] = conv
            setActiveConversations()
            
        //新增
        }else {
            self.allConvs.insert(conv, at: 0)
            setActiveConversations()
        }
    }
}

//MARK: UISearchBarDelegate
extension ConversationsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchText = searchBar.text
        setActiveConversations()
        
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        setActiveConversations()
    }
}

//MARK: UITableViewDelegate
extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activeConvs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        
        let conv = self.activeConvs[row]
        cell.configure(conv: conv)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let conv = self.activeConvs[row]
        
        gotoChatView(conv)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let row = indexPath.row
            let convId = self.activeConvs[row].conversationId
            deleteConversation(convId)
        }
    }
}

//MARK: Server
extension ConversationsViewController {
    func getConversations() {
        self.showActivityIndicator()
        ConversationService.shared.getConversations { data in
            self.allConvs = data
            self.setActiveConversations()
            self.hideActivityIndicator()
        }
    }
    
    func deleteConversation(_ convId: Int) {
        showAlert(title: nil, message: "Confirm delete?".localized(), showCancel: true) {
            self.showActivityIndicator()
            ConversationService.shared.deleteUserConversation(conversationId: convId) {
                if let index = self.allConvs.firstIndex(where: { $0.conversationId == convId }) {
                    self.allConvs.remove(at: index)
                    self.setActiveConversations()
                }
                self.hideActivityIndicator()
            }
        }
    }
}
