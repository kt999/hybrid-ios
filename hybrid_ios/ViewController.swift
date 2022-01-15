//
//  ViewController.swift
//  gunban_ios_test
//
//  Created by kiteak99 on 2020/10/30.
//  Copyright © 2020 kiteak99. All rights reserved.
//

import WebKit
import SystemConfiguration
import SwiftUI


class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    @IBOutlet var topContraints: NSLayoutConstraint!
    @IBOutlet var webView: WKWebView!
    @IBOutlet var splash: UIView!
    
    ///window.open()으로 열리는 새창
    var createWebView: WKWebView?
    var popup_status = false
    
    var defaultHost = "10.20.190.172:3000";

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //네트워크 확인
        if(!isInternetAvailable()){
         
            //internet avilable
            showToast(message: "인터넷 연결상태를 확인해주세요.")
            
            //3초뒤 종료
            let time = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: time) {
                exit(0)
            }
        }
        
        
        self.swipeRecognizer()
        // 페이지 url 설정
        let defaultAddress = "http://\(defaultHost)/";
        self.request(url: defaultAddress)
        
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always

        
        // 상태바만큼 Top Constraint 설정
        topContraints.constant = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        
        // WebView Bounce, Indicator(스크롤 바) 제거
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        webView.navigationDelegate = self

        
        //3D 터치 비활성화
        webView.allowsLinkPreview = false
        
        //뒤로가기, 앞으로가기 제스쳐 사용 (default : false)
        webView.allowsBackForwardNavigationGestures = false

        
        //alert 및 자바스크립트 브릿지 설정관련
        webView.configuration.userContentController.add(self, name: "getVersionName")
        webView.configuration.preferences.javaScriptEnabled = true
        webView.uiDelegate = self
        
    }
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()

        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {

            return false

        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return (isReachable && !needsConnection)
    }
    
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height-100, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = true;
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }



    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            switch message.name {
                case "getVersionName":
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                    print(version)
                    
                    self.webView.evaluateJavaScript("set_ios_verson_name('\(version)')", completionHandler: {(result, error) in
                        if let result = result {
                                print(result)
                            }
                        }
                    )
                default:
                    break
            }
        }
    
    // 현재 webView에서 받아온 URL 페이지를 로드한다.
    func request(url: String) {
        self.webView.load(URLRequest(url: URL(string: url)!))
        
    }
    
    
    //뒤로가기 제스쳐 시작
    func swipeRecognizer() {
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture(_:)))
            swipeRight.direction = UISwipeGestureRecognizer.Direction.right
            self.view.addGestureRecognizer(swipeRight)

        }

    @objc func respondToSwipeGesture(_ gesture: UIGestureRecognizer){
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction{
            case UISwipeGestureRecognizer.Direction.right:
                // 스와이프 시, 원하는 기능 구현.
                
                //뒤로가기 함수 연동
                self.webView.evaluateJavaScript("webBackPress()", completionHandler: {(result, error) in
                    if let result = result {
                        print(result)
                            }
                    }
                )
                
                
                self.dismiss(animated: true, completion: nil)
            default: break
            }
        }
    }
    //뒤로가기 제스쳐 시작 끝


    
    //alert 관련 시작
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))

        present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))

        present(alertController, animated: true, completion: nil)
    }


    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)

        alertController.addTextField { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
    //alert 관련 끝
    
    
    //외부 앱
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        func isMatch(_ urlString: String, _ pattern: String) -> Bool {
            let regex = try! NSRegularExpression(pattern: pattern, options: [])
            let result = regex.matches(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count))
            return result.count > 0
        }
        
        func isItunesURL(_ urlString: String) -> Bool {
            return isMatch(urlString, "\\/\\/itunes\\.apple\\.com\\/")
        }
        
        func isItunesURL2(_ urlString: String) -> Bool {
            return isMatch(urlString, "\\/\\/apps\\.apple\\.com\\/")
        }
        
        if let url = navigationAction.request.url {
            if url.host?.hasPrefix(defaultHost) == true {
                decisionHandler(.allow)
            } else if(isItunesURL(url.absoluteString) || isItunesURL2(url.absoluteString)) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            } else if url.scheme != "http" && url.scheme != "https" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            } else {
                if navigationAction.navigationType == .linkActivated  {
                    if let url = navigationAction.request.url,
                       let host = url.host, !host.hasPrefix(defaultHost),
                       UIApplication.shared.canOpenURL(url) {
                        
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        print(url)
                        print("Redirected to browser. No need to open it locally")
                        decisionHandler(.cancel)
                    } else {
                        print("Open it locally")
                        decisionHandler(.allow)
                    }
                }
                else {
                    print("not a user click")
                    decisionHandler(.allow)
                }
            }
        } else {
            decisionHandler(.allow)
        }
        
    }
    
    
    //popup
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            
        popup_status = true
        
        //뷰를 생성하는 경우
        let frame = UIScreen.main.bounds
        
        //파라미터로 받은 configuration
        createWebView = WKWebView(frame: frame, configuration: configuration)
        
        //오토레이아웃 처리
        createWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
        createWebView?.navigationDelegate = self
        createWebView?.uiDelegate = self
        
        
        view.addSubview(createWebView!)
        
        return createWebView!
        
        /* 현재 창에서 열고 싶은 경우
        self.webView.load(navigationAction.request)
        return nil
        */
    }
        
    ///새창 닫기
    ///iOS9.0 이상
    func webViewDidClose(_ webView: WKWebView) {
        
        
        if webView == createWebView {
            
            popup_status = false

            
            
            createWebView?.removeFromSuperview()
            createWebView = nil
        }
    }


    
}
