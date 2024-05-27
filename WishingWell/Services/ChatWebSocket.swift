//
//  ChatWebSocket.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/4/10.
//

import Foundation
import Starscream

protocol ChatWebSocketDelegate {
    func didReceive(chat: Chat)
    func didConnect()
}

class ChatWebSocket: NSObject {
    static let shared: ChatWebSocket = ChatWebSocket()
    
    private override init() {
        print("ChatWebSocket init..")
    }
    
    var delegate: ChatWebSocketDelegate?
    
    var socket: WebSocket?
    var isConnected = false
    
    //WebSocket: Starscream
    func setWebSocket(type: ChatType) {
        let path = APIManager().getBaseURL() + "/chat/\(type.rawValue)"
        guard let url = URL(string: path) else {
            print("Error: can not create URL")
            return
        }
        var request = URLRequest(url: url)
        if let headers = APIManager().headers {
            request.headers = headers
        }
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
}

// MARK: - WebSocketDelegate
extension ChatWebSocket: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocketClient) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
            delegate?.didConnect()
            
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            
        case .text(let string):
            guard let chat = try? Chat(decoding: string) else { return }
            print("--------------------------------------------------")
            print("Receive chat: \(chat)")
            print("--------------------------------------------------")
            delegate?.didReceive(chat: chat)
            
        case .binary(let data):
            print("Received data: \(data.count)")
            
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .peerClosed:
            break
            
        case .cancelled:
            isConnected = false
            
        case .error(let error):
            isConnected = false
            print("error: \(error?.localizedDescription ?? "")")
        }
    }
}
