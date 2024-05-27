//
//  LUNWebViewController.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2019/6/13.
//  Copyright © 2019 LunYuChang. All rights reserved.
//

import UIKit
import WebKit

class LUNWebViewController: UIViewController {
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var closeBtnView: UIView!
    
    //Configuration
    var url: URL?
    var contentType: String?        //讀檔案
    var isEbpay = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
        loadAddress()
    }
    
    func setupLayout() {
        webview.navigationDelegate = self
        closeBtnView.isHidden = self.navigationController == nil ? false : true
    }
    
    func loadAddress() {
        guard let url = self.url else { return }
        
        //讀檔案
        if let mimeType = self.contentType {
            do {
                let data = try Data(contentsOf: url)
                self.webview.load(data, mimeType: mimeType, characterEncodingName: "UTF-8", baseURL: url)
            
            }catch {
                print("URL Data Error: \(error.localizedDescription)")
            }
        
        //付款金流Web
        }else if isEbpay {
            var request = URLRequest(url: url)
            if let headers = APIManager().headers {
                request.headers = headers
            }
            webview.load(request)
            
        }else {
            let request = URLRequest(url: url)
            webview.load(request)
        }
    }

    //MARK: Action
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: WKNavigationDelegate
extension LUNWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        //載入失敗，失敗原因
        print("didFail: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start to load...")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finish to load...")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        //知道返回內容之後，是否允許載入，允許載入
        if let url = navigationResponse.response.url?.absoluteString {
            print("navigation url: \(url)")
            //藍新金流URL: 信用卡交易成功
//            if url.contains("mpg_gateway/mpg_return_url?Status=SUCCESS") {
//
//            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        //跳轉到其他的伺服器
        print("didReceiveServerRedirect: \(webView.url)")
    }
}
