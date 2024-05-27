//
//  MyCustomCell.swift
//  TheWayToBasketball
//
//  Created by Lun Yu Chang on 2024/3/12.
//  Copyright © 2024 LunYuChang. All rights reserved.
//

import UIKit
import MessageKit

class MyCustomCell: MessageContentCell {
    var orderMessageView = OrderMessageView()
    
    open override func setupSubviews() {
        super.setupSubviews()
        
        messageContainerView.addSubview(orderMessageView)
        messageContainerView.isUserInteractionEnabled = true
        setupConstraints()
    }
    
    open func setupConstraints() {
        orderMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            orderMessageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            orderMessageView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor),
            orderMessageView.topAnchor.constraint(equalTo: messageContainerView.topAnchor),
            orderMessageView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor)
        ])
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        
        self.orderMessageView.acceptBtn.removeTarget(nil, action: nil, for: .allEvents)
        self.orderMessageView.lookBtn.removeTarget(nil, action: nil, for: .allEvents)
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        if let data = message as? MessageData {
            switch data.kind {
            case .custom(let custom):
                if let item = custom as? OrderItem {
                    self.orderMessageView.configure(item: item)
                }
                
            default:
                break
            }
        }
    }
}

open class CustomMessageSizeCalculator: MessageSizeCalculator {
    open override func messageContainerSize(for message: MessageType) -> CGSize {
    // Customize this function implementation to size your content appropriately. This example simply returns a constant size
    // Refer to the default MessageKit cell implementations, and the Example App to see how to size a custom cell dynamically
        return CGSize(width: 300, height: 400)
    }
}

open class MyCustomMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy open var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)

    override open func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        //before checking the messages check if section is reserved for typing otherwise it will cause IndexOutOfBounds error
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath);
    }
}
