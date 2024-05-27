//
//  NewCommentViewController.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2020/6/29.
//  Copyright © 2020 LunYuChang. All rights reserved.
//

import UIKit

class NewCommentViewController: UIViewController {
    @IBOutlet weak var scrollview: UIScrollView!
    
    @IBOutlet weak var userStackView: UIStackView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var accountLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    
    @IBOutlet weak var titleLbl: UILabel!
    
    @IBOutlet weak var starview: LUNRatingStarView!
    @IBOutlet weak var textview: UITextView!
    
    @IBOutlet weak var buttonview: LUNButtonView!
    @IBOutlet var accessoryview: UIView!
    @IBOutlet weak var accessoryBtn: UIButton!
    
    //Configuration
    var viewType: ViewType = .Create
    var receiverUserId: Int?
    var senderUserId: Int? = UserService.shared.currentUser?.userId
    
    //Data
    var newComment = Comment()
    private var placeholder = "Write comment".localized()
    
    ///`state`: 0 = create, 1 = update, 2 = delete
    var completionHandler: ((_ newComment: Comment,_ state: Int) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Comment".localized()
        
        hideKeyboardWhenTappedAround(scrollview)
        setupBarButton()
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
    
    func setupBarButton() {
        //檢查Comment是否可以編輯
        if UserService.shared.currentUser?.userId == self.newComment.senderUserId {
            let moreBtn = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(moreAction(_:)))
            navigationItem.rightBarButtonItem = moreBtn
        }
    }
    
    func setupLayout() {
        //User
        if self.viewType == .Watch {
            guard let user = self.newComment.senderUser else { return }
            userStackView.isHidden = false
            let tap = UITapGestureRecognizer(target: self, action: #selector(userAction))
            userStackView.addGestureRecognizer(tap)
            
            accountLbl.text = user.account
            dateLbl.text = self.newComment.createDate.convertString(origin: .Server, result: .yyyyMMddHHmm)
            if let fileId = user.files?.filter({ $0.type == FileType.USER.rawValue }).first?.fileId {
                FileService.shared.getImage(fileId: fileId) { image in
                    self.userImageView.image = image
                }
            }
            
        }else {
            userStackView.isHidden = true
        }
        
        //Title
        titleLbl.text = "Comment title".localized()
        titleLbl.isHidden = self.viewType == .Watch ? true : false
        
        //Star View
        starview.backgroundColor = UIColor.clear
        starview.type = .halfRatings
        starview.emptyImage = UIImage(systemName: "star")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        starview.fullImage = UIImage(systemName: "star.fill")?.withTintColor(.label, renderingMode: .alwaysOriginal)
        starview.maxRating = 5
        starview.rating = self.newComment.star
        if self.viewType == .Watch {
            starview.editable = false
            
        }else {
            starview.editable = true
            starview.delegate = self
        }
        
        //Text View
        textview.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        if self.viewType == .Watch {
            textview.text = self.newComment.text
            textview.textColor = .label
            textview.isEditable = false
            
        }else {
            textview.delegate = self
            textview.inputAccessoryView = accessoryview
            textview.isEditable = true
            if self.newComment.text == nil {
                textview.text = placeholder
                textview.textColor = .systemGray
                
            }else {
                textview.text = self.newComment.text
                textview.textColor = .label
            }
        }
        
        //Button View
        //Clear target for reload
        accessoryBtn.removeTarget(nil, action: nil, for: .allEvents)
        buttonview.button.removeTarget(nil, action: nil, for: .allEvents)
        buttonview.isHidden = false
        switch self.viewType {
        case .Create:
            accessoryBtn.setTitle("Confirm".localized(), for: .normal)
            accessoryBtn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
            buttonview.button.setTitle("Confirm".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
            
        case .Update:
            accessoryBtn.setTitle("Update".localized(), for: .normal)
            accessoryBtn.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
            buttonview.button.setTitle("Update".localized(), for: .normal)
            buttonview.button.addTarget(self, action: #selector(updateAction), for: .touchUpInside)
            
        case .Watch:
            buttonview.isHidden = true
        }
    }
    
    func validateComment() -> Bool {
        if self.newComment.star == 0.0 {
            self.showAlert(title: nil, message: "Input comment star".localized())
            return false
        }
        
//        if self.newComment.text.isEmpty {
//            self.showAlert(title: nil, message: "Input comment text".localized())
//            return false
//        }
        
        if self.viewType == .Create {
            guard let senderUserId = self.senderUserId,
                  let receiverUserId = self.receiverUserId else { return false }
            self.newComment.senderUserId = senderUserId
            self.newComment.receiverUserId = receiverUserId
        }
        print("---------------------------------------------")
        print("New Comment: \(self.newComment)")
        print("---------------------------------------------")
        return true
    }
    
    func showMoreAlert(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let update = UIAlertAction(title: "Update".localized() + "Comment".localized(), style: .default) { action in
            self.viewType = .Update
            self.setupLayout()
        }
        let delete = UIAlertAction(title: "Delete".localized() + "Comment".localized(), style: .destructive) { action in
            self.deleteComment()
        }
        let cancel = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addAction(update)
        alert.addAction(delete)
        alert.addAction(cancel)
        
        //For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Action
    @objc func moreAction(_ sender: UIButton) {
        showMoreAlert(sender)
    }
    
    @objc private func userAction() {
        guard let user = self.newComment.senderUser else { return }
        self.showCustomUserView(user)
    }
    
    @objc func confirmAction() {
        self.view.endEditing(true)
        guard checkRechability() else {
            showAlert(title: nil, message: "Internet connect error".localized())
            return
        }
        
        if validateComment() {
            showAlert(title: nil, message: "Confirm create?".localized(), showCancel: true) {
                self.showActivityIndicator()
                CommentService.shared.createComment(comment: self.newComment) { commentId in
                    self.newComment.commentId = commentId
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(),
                                   message: "Create successfully".localized()) {
                        self.completionHandler?(self.newComment, 0)
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
        
        if validateComment() {
            showAlert(title: nil, message: "Confirm update?".localized(), showCancel: true) {
                self.showActivityIndicator()
                CommentService.shared.updateComment(comment: self.newComment) {
                    self.hideActivityIndicator()
                    self.showAlert(title: "Congratulation".localized(),
                                   message: "Update successfully".localized()) {
                        self.completionHandler?(self.newComment, 1)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

//MARK: Keyboard
extension NewCommentViewController {
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
        if let userInfo = notification.userInfo {
            let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
            let duration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double

            UIView.animate(withDuration: duration) {
                self.scrollview.contentInset = UIEdgeInsets(top: self.scrollview.contentInset.top, left: 0, bottom: keyboardFrame.size.height, right: 0)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollview.contentInset = contentInsets
        scrollview.scrollIndicatorInsets = contentInsets
    }
}

//MARK: UITextViewDelegate
extension NewCommentViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == self.placeholder {
            textView.text = nil
            textView.textColor = .label
            self.newComment.text = nil
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text,
           !text.isEmpty {
            self.newComment.text = text
    
        }else {
            textView.text = placeholder
            textView.textColor = .systemGray
            self.newComment.text = nil
        }
    }
}

//MARK: LUNRatingStarViewDelegate
extension NewCommentViewController: LUNRatingStarViewDelegate {
    func floatRatingView(_ ratingView: LUNRatingStarView, didUpdate rating: Double) {
        print("Rating: \(rating)")
        self.newComment.star = rating
    }
}

//MARK: Server
extension NewCommentViewController {
    func deleteComment() {
        let commentId = self.newComment.commentId
        
        showAlert(title: nil, message: "Confirm delete?".localized(), showCancel: true) {
            self.showActivityIndicator()
            CommentService.shared.deleteComment(commentId: commentId) {
                self.hideActivityIndicator()
                self.showAlert(title: nil, message: "Delete successfully".localized()) {
                    self.completionHandler?(self.newComment, 2)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}
