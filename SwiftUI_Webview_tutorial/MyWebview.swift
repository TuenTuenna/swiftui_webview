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

//MARK: - 다운로드 관련
extension MyWebview.Coordinator {
    
    /// 다운로드 허용 여부
    /// - Parameters:
    ///   - availableTypes: 허용하는 파일 타입들  예) zip, pdf 만 다운로드 할꺼에요
    ///   - fileTypeToDownload: 다운로드 할려는 파일타입
    /// - Returns: 다운로드 가능한지 여부
    fileprivate func checkDownloadAvailable(availableTypes: [String], fileTypeToDownload: String) -> Bool {
        print("checkDownloadAvailable() called - availableTypes: \(availableTypes) / fileTypeToDownload: (fileTypeToDownload)")
        
        // 딕셔너리 가져오기
        let availableDictionaries = mimeTypes.filter { (key: String, value: String) in
            availableTypes.contains(key)
        }
        
        print("availableDictionaries: \(availableDictionaries)")
        
        return availableDictionaries.contains { (key: String, value: String) in
            value == fileTypeToDownload
        }
    }
    
    
    // 다운로드 받은 파일을 임시 저장경로에 옮기고 저장된 위치를 반환한다.
    fileprivate func moveDownloadedFile(url: URL, fileName: String) -> URL {
        // 임시 경로
        let tempDir = NSTemporaryDirectory()
        let destinationPath = tempDir + fileName
        let destinationFileURL = URL(fileURLWithPath: destinationPath)
        // 같은 경로에 아이템이 있으면 지워라
        try? FileManager.default.removeItem(at: destinationFileURL)
        // 해당 경로로 다운받은 아이템을 이동시켜라
        try? FileManager.default.moveItem(at: url, to: destinationFileURL)
        return destinationFileURL
    }
    
    // 파일 다운로드
    fileprivate func downloadFile(webView: WKWebView,
                                  url: URL,
                                  fileName: String,
                                  completion: @escaping (URL?) -> Void ){
        print("downloadFile() called")
        
        // 웹뷰 쿠키 가져오기
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ fetchedCookies in
            
            // urlSession
            let session = URLSession.shared
            // 가져온 쿠키로 urlSession 설정
            session.configuration.httpCookieStorage?.setCookies(fetchedCookies, for: url, mainDocumentURL: nil)
          
            // 다운로드 진행
            let downloadTask = session.downloadTask(with: url) { localUrl, urlResponse, error in
                print("다운로드 완료")
                
                // 다운로드 완료시
                if let localUrl = localUrl {
                    let finalDestinationUrl = self.moveDownloadedFile(url: localUrl, fileName: fileName)
                    completion(finalDestinationUrl)
                } else { // 다운로드 실패시
                    completion(nil)
                }
            }
            downloadTask.resume()
            
        })
        
    }// downloadFile
    
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
    
    // 네비게이션 응답이 들어왔을때
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("webView - decidePolicyFor navigationResponse")
        
        // 클릭된 url, 파일형태, 파일 이름
        guard let url = navigationResponse.response.url,
              let mimeType = navigationResponse.response.mimeType,
              let filename = navigationResponse.response.suggestedFilename else {
            decisionHandler(.cancel)
            return
        }
        
        print("webView 다운로드 테스트 - url: \(url)")
        print("webView 다운로드 테스트 - mimeType: \(mimeType)")
        print("webView 다운로드 테스트 - mimeType.getReadableMimeType(): \(mimeType.getReadableMimeType())")
        print("webView 다운로드 테스트 - filename: \(filename)")
        
        // 특정 파일 형태만 다운로드 가능하도록 하겠다.
        let downloadAvailableType = ["pdf", "zip"]
        
        // 사이트 일때
        if mimeType == "text/html" {
            decisionHandler(.allow)
        } else { // 다운로드 해야하는 링크 일때
            
            // 다운로드가능한 타입이 아니라면
            if !checkDownloadAvailable(availableTypes: downloadAvailableType, fileTypeToDownload: mimeType) {
                // 다운로드 가능한 파일이 아니라고 얼럿 띄우기
                self.myWebView.viewModel.jsAlertEvent.send(JsAlert(filename, .DOWNLOAD_NOT_AVAILABLE))
                // 웹뷰 로드 막기
                decisionHandler(.cancel)
                return
            }
            
            // 다운로드 시작
            downloadFile(webView: webView, url: url, fileName: filename, completion: { fileUrl in
                print("다운로드 받은 fileUrl: ", fileUrl)
                DispatchQueue.main.async {
                    if let fileUrl = fileUrl {
                        // 다운로드가 완료 되었다고 알린다
                        self.myWebView.viewModel.downloadEvent.send(fileUrl)
                    } else {
                        self.myWebView.viewModel.jsAlertEvent.send(JsAlert(filename, .DOWNLOAD_FAILED))
                    }
                }
            })
            
            decisionHandler(.cancel)
        }
        
        
        
    }
    
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
