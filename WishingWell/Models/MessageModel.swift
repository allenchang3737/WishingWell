//
//  MessageModel.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import MessageKit
import CoreLocation
import SwiftyJSON

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        case .linkPreview(_):
            return "linkPreview"
        }
    }
}

//MARK: Server
struct Message: Codable {
    var messageId: Int = 0
    var createDate: String = ""
    var conversationId: Int = 0
    var content: String = ""
    var isRead: Bool = false
    var senderUserId: Int
    var type: String
    var productId: Int?                 //訊息是在討論哪個產品
    var orderId: Int?                   //訊息是在討論哪個訂單
    
    //Response & Send message
    var senderUser: User?
    
    //From app to server
    init(conversationId: Int, data: MessageData) {
        self.conversationId = conversationId
        self.senderUserId = Int(data.sender.senderId) ?? 0
        self.type = data.kind.messageKindString
        self.productId = data.productId
        self.orderId = data.orderId
        
        if let sender = data.sender as? Sender {
            self.senderUser = sender.user
        }
        
        switch data.kind {
        case .text(let text):
            self.content = text
            
        case .photo(let item):
            self.content = item.url?.absoluteString ?? ""
            
        case .video(let item):
            self.content = item.url?.absoluteString ?? ""
            
        case .location(let location):
            let longitude = location.location.coordinate.longitude
            let latitude = location.location.coordinate.latitude
            setLocation(longitude: longitude, latitude: latitude)
           
        case .linkPreview(let link):
            self.content = link.text ?? ""
            
        case .custom(let custom):
            if let item = custom as? OrderItem {
                self.content = item.toString() ?? ""
            }
            
        default:
            break
        }
    }
    
    //寫入經緯度
    mutating func setLocation(longitude: Double, latitude: Double) {
        var c = self.content
        if !c.isEmpty {
            c += "&"
        }
        c += "LOCATION=\(longitude),\(latitude)"
        self.content = c
    }
    
    func getLocation() -> String? {
        let c = self.content
        let infos = c.components(separatedBy: "&")
        if let info = infos.filter({ $0.contains("LOCATION") }).first {
            let values = info.components(separatedBy: "=")
            return values.last
        }
        return nil
    }
}

//MARK: Local
struct MessageData: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    //暫存
    var productId: Int?
    var orderId: Int?
    
    init(sender: SenderType, kind: MessageKind, productId: Int?, orderId: Int?) {
        self.sender = sender
        self.messageId = ""
        self.sentDate = Date()
        self.kind = kind
        self.productId = productId
        self.orderId = orderId
    }
    
    //From server to app
    init(msg: Message) {
        //Default error
        self.sender = Sender(senderId: "", displayName: "", user: nil)
        self.messageId = ""
        self.sentDate = Date()
        self.kind = .text("error")
        
        guard let user = msg.senderUser else { return }
        self.sender = Sender(senderId: "\(user.userId)", displayName: user.account, user: user)
        self.messageId = "\(msg.messageId)"
        self.sentDate = msg.createDate.convertDate(format: .Server) ?? Date()
        self.productId = msg.productId
        self.orderId = msg.orderId
        
        switch msg.type {
        case "photo":
            guard let imageUrl = URL(string: msg.content),
                  let placeholder = UIImage(systemName: "photo") else { return }
            let media = Media(url: imageUrl,
                              image: nil,
                              placeholderImage: placeholder,
                              size: CGSize(width: 300, height: 240))
            self.kind = .photo(media)
            
        case "video":
            guard let videoUrl = URL(string: msg.content),
                  let placeholder = UIImage(systemName: "photo") else { return }
            let media = Media(url: videoUrl,
                              image: nil,
                              placeholderImage: placeholder,
                              size: CGSize(width: 300, height: 240))
            self.kind = .video(media)
            
        case "location":
            guard let components = msg.getLocation()?.components(separatedBy: ","),
                  components.count == 2,
                  let longitude = Double(components[0]),
                  let latitude = Double(components[1]) else { return }
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: CGSize(width: 300, height: 240))
            self.kind = .location(location)
            
        case "custom":
            if msg.orderId != nil {
                do { //content string -> orderItem
                    let item = try OrderItem(decoding: msg.content)
                    self.kind = .custom(item)
                    
                }catch {
                    print("decoding Error: \(error.localizedDescription)")
                }
            }
            
        case "linkPreview":
            guard let extractURL = msg.content.extractURLs().first,
                  let url = URL(string: extractURL),
                  let image = UIImage(systemName: "macwindow")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
            let link = Link(text: msg.content,
                            url: url,
                            teaser: url.absoluteString,
                            thumbnailImage: image)
            self.kind = .linkPreview(link)
            
        default:
            self.kind = .text(msg.content)
        }
    }
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
    
    //Response
    var user: User?
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

struct Link: LinkItem {
    var text: String?
    var attributedText: NSAttributedString?
    var url: URL
    var title: String?
    var teaser: String
    var thumbnailImage: UIImage
}

//Order Item
struct OrderItem: Codable {
    //Product Info
    var productTitle: String
    var productFileId: Int?
    
    //Order Info
    var orderUserId: Int
    var orderContent: String
    var orderStatus: Int
    
    //From order
    init(order: Order) {
        self.productTitle = order.product?.title ?? ""
        self.productFileId = order.product?.files?.first?.fileId
        self.orderUserId = order.orderUserId
        self.orderContent = order.getOrderContent()
        self.orderStatus = order.status
    }
    
    //From server message content
    init(decoding content: String) throws {
        let data = Data(content.utf8)
        let json = try JSON(data).rawData()
        let decoder = JSONDecoder()
        self = try decoder.decode(OrderItem.self, from: json)
    }
    
    func toString() -> String? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            let jsonString = String(data: jsonData, encoding: .utf8)
            print("------------------------------------------------------------")
            print("OrderItem jsonString: \(jsonString ?? "")")
            print("------------------------------------------------------------")
            return jsonString
       
        }catch {
            print("toString Error: \(error.localizedDescription)")
            return nil
        }
    }
}
