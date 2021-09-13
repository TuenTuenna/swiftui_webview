//
//  MyWebview.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2020/07/02.
//  Copyright © 2020 Tuentuenna. All rights reserved.
//

import SwiftUI
import WebKit
import Combine

// uikit 의 uiview 를 사용할수 있도록 한다.
// UIViewControllerRepresentable

struct MyWebview: UIViewRepresentable {
   
    @EnvironmentObject var viewModel : WebViewModel
    
    var urlToLoad: String
    
    // 리프레시 컨트롤 헬퍼 클래스 만들기
    let refreshHelper = MyWebViewRefreshConrolHelper()
    
    // 코디네이터 만들기
    func makeCoordinator() -> MyWebview.Coordinator {
        return MyWebview.Coordinator(self)
    }
    
    // ui view 만들기
    func makeUIView(context: Context) -> WKWebView {
        
        // unwrapping
        guard let url = URL(string: self.urlToLoad) else {
            return WKWebView()
        }
        
        // 웹뷰 인스턴스 생성
        let webview = WKWebView(frame: .zero, configuration: creatWKWebConfig())
        
        // wkwebview 의 델리겟 연결을 위한 코디네이터 설정
        webview.uiDelegate = context.coordinator
        webview.navigationDelegate = context.coordinator
        webview.allowsBackForwardNavigationGestures = true // 가로 스와이프 뒤로가기 설정
        
        // 리프레시 컨트롤을 달아준다.
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.tintColor = UIColor.blue
        refreshHelper.viewModel = viewModel
        refreshHelper.refreshControl = myRefreshControl
        
        myRefreshControl.addTarget(refreshHelper, action: #selector(MyWebViewRefreshConrolHelper.didRefresh), for: .valueChanged)
        
        webview.scrollView.refreshControl = myRefreshControl
        webview.scrollView.bounces = true // 바운싱 여부 설정
        
        
        // 웹뷰를 로드한다.
        webview.load(URLRequest(url: url))
        
        return webview
        
    }
    
    // 업데이트 ui view
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MyWebview>) {
           
    }
    
    func creatWKWebConfig() -> WKWebViewConfiguration {
        // 웹뷰 설정
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        
        let wkWebConfig = WKWebViewConfiguration()
        
        // 웹뷰 유저 컨트롤러
        let userContentController = WKUserContentController()
        userContentController.add(self.makeCoordinator(), name: "callbackHandler")
        wkWebConfig.userContentController = userContentController
        wkWebConfig.preferences = preferences
        return wkWebConfig
    }
    
    
    class Coordinator: NSObject {
        
        var myWebView : MyWebview // SwiftUi View
        
        var subscriptions = Set<AnyCancellable>()
        
        init(_ myWebView: MyWebview) {
            self.myWebView = myWebView
        }
        
    }
    
}

//MARK: - UIDelegate 관련
extension MyWebview.Coordinator : WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.jsAlertEvent.send(JsAlert(message, .JS_ALERT))
        completionHandler()
    }
    
}

//MARK: - WKNavigationDelegate 관련 링크이동 관련
extension MyWebview.Coordinator : WKNavigationDelegate {
    
    // 네비게이션 액션 들어올때
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // 리퀘스트 url 이 없으면 리턴
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        switch url.scheme {
        case "tel", "mailto": // 전화번호, 이메일
            // 외부로 열기
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        default:
            // 특정 도메인을 제외한 도메인을 연결하지 못하게 할 수 있다.
            print("들어온 도메인 url.host: \(String(describing: url.host)) ")
            switch url.host {
                case "www.youtube.com":
                    print("유튜브로 이동 못합니다!")
                    myWebView.viewModel.jsAlertEvent.send(JsAlert(url.host, .BLOCKED_SITE))
                    decisionHandler(.cancel)
                default:
                    decisionHandler(.allow)
            }
        }
    }
    
    // 웹뷰 검색 시작
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webView didStartProvisionalNavigation")
        
        // 로딩중 알리기
        myWebView.viewModel.shouldShowIndicator.send(true)
        
        myWebView
            .viewModel
            .webNavigationSubject
            .sink{ (action: WEB_NAVIGATION) in
                print("들어온 네비게이션 액션: \(action)")
                switch action {
                case .BACK:
                    if webView.canGoBack {
                        webView.goBack()
                    }
                case .FORWARD:
                    if webView.canGoForward {
                        webView.goForward()
                    }
                case .REFRESH:
                    webView.reload()
                }
            }.store(in: &subscriptions)
            
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("webView - didCommit")
        // 로딩중 알리기
        myWebView.viewModel.shouldShowIndicator.send(true)
    }
    
    // 웹뷰 검색 완료
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish")
        
        webView.evaluateJavaScript("document.title") { (response, error) in
            if error != nil {
                print("타이틀 에러때문에 못가져옴")
            }
            if let title = response as? String {
                self.myWebView.viewModel.webSiteTitleSubject.send(title)
            }
        }
        
        myWebView
            .viewModel
            .nativeToJsEvent
            .sink{ message in
                print("didFinish() called / nativeToJsEvent 이벤트 들어옴 / message: \(message)")
                webView.evaluateJavaScript("nativeToJsEventCall('\(message)');", completionHandler: { (result, error) in
                    if let result = result {
                        print("nativeToJs result 성공 : \(result)")
                    }
                    if let error = error {
                        print("nativeToJs result 실패 : \(error.localizedDescription)")
                    }
                })
            }.store(in: &subscriptions)
        
        myWebView
            .viewModel
            .changedUrlSubject
            .compactMap{ $0.url }
            .sink{ changedUrl in
                print("변경된 url: \(changedUrl)")
                webView.load(URLRequest(url: changedUrl))
            }.store(in: &subscriptions)
        
        // 로딩 끝났다고 알리기
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("webViewWebContentProcessDidTerminate")
        // 로딩 끝났다고 알리기
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("webView didFail")
        // 로딩 끝났다고 알리기
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("webView didFailProvisionalNavigation")
        // 로딩 끝났다고 알리기
        self.myWebView.viewModel.shouldShowIndicator.send(false)
    }
    
}

//MARK: - UIDelegate 관련
extension MyWebview.Coordinator : WKScriptMessageHandler {
    
    // 웹뷰 js 에서 ios 네이티브를 호출하는 메소드 들이 이쪽을 탄다
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKWebViewCoordinator - userContentController / message: \(message)")
        
        if message.name == "callbackHandler" {
            print("JSON 데이터가 웹으로부터 옴: \(message.body)")
            if let receivedData : [String: String] = message.body as? Dictionary {
                print("receivedData: \(receivedData)")
                myWebView.viewModel.jsAlertEvent.send(JsAlert(receivedData["message"], .JS_BRIDGE))
            }
        }
        
    }
    
    
}


struct MyWebview_Previews: PreviewProvider {
    static var previews: some View {
        MyWebview(urlToLoad: "https://www.naver.com")
    }
}
