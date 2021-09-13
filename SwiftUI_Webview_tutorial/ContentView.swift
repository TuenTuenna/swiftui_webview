//
//  ContentView.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2020/07/02.
//  Copyright © 2020 Tuentuenna. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var myWebVM : WebViewModel
    
    @State var jsAlert : JsAlert?
    
    @State var textString = ""
    @State var shouldShowAlert = false
    
    @State var isLoading : Bool = false
    
    @State var webTitle : String = ""
    
    var body: some View {
        NavigationView{
            ZStack{
                VStack{
                    MyWebview(urlToLoad: "https://tuentuenna.github.io/simple_js_alert/")
                    webViewBottomTabbar
                }
                .navigationBarTitle(Text(webTitle), displayMode: .inline)
                .navigationBarItems(
                    leading: siteMenu,
                    trailing: Button("iOS -> Js") {
                        print("iOS -> Js 버튼 클릭")
                        self.shouldShowAlert.toggle()
                    }
                )
                .alert(item: $jsAlert, content: { alert in
                    createAlert(alert)
                })
                if self.shouldShowAlert{ createTextAlert() }
                if self.isLoading{ LoadingScreenView() }

            }// ZStack
            .onReceive(myWebVM.webSiteTitleSubject, perform: { receivedWebTitle in
                print("ContentView - receivedWebTitle: ", receivedWebTitle)
                self.webTitle = receivedWebTitle
            })
            .onReceive(myWebVM.jsAlertEvent, perform: { jsAlert in
                print("ContentView - jsAlert: ", jsAlert)
                self.jsAlert = jsAlert
            })
            .onReceive(myWebVM.shouldShowIndicator, perform: { isLoading in
                print("ContentView - isLoading: ", isLoading)
                self.isLoading = isLoading
            })
            .onReceive(myWebVM.downloadEvent, perform: { fileUrl in
                print("ContentView - fileUrl: ", fileUrl)
                // 다운로드된 파일을 공유한다.
                shareSheet(url: fileUrl)
            })
        } // NavigationView
    }// body
    
    // 사이트 메뉴
    var siteMenu: some View {
        Text("사이트 이동")
            .foregroundColor(.blue)
            .contextMenu(ContextMenu(menuItems: {
                Button(action: {
                    print("정대리 웹뷰 이동")
                    self.myWebVM.changedUrlSubject.send(.DEV_JEONG_DAE_RI)
                }, label: {
                    Text("정대리 웹뷰 이동")
                    Image("dev_jeong_dae_ri")
                })
                Button(action: {
                    print("네이버로 이동")
                    self.myWebVM.changedUrlSubject.send(.NAVER)
                }, label: {
                    Text("네이버 이동")
                    Image("naver")
                })
                Button(action: {
                    print("구글로 이동")
                    self.myWebVM.changedUrlSubject.send(.GOOGLE)
                }, label: {
                    Text("구글 이동")
                    Image("google")
                })
                
            }))
    }
    
    // 웹뷰 바텀 탭바
    var webViewBottomTabbar : some View {
        VStack{
            Divider()
            HStack{
                Spacer()
                Button(action: {
                    print("뒤로가기")
                    self.myWebVM.webNavigationSubject.send(.BACK)
                }, label: {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 20))
                })
                Group{
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    print("앞으로 가기")
                    self.myWebVM.webNavigationSubject.send(.FORWARD)
                }, label: {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 20))
                })
                Group{
                    Spacer()
                    Divider()
                    Spacer()
                }
                Button(action: {
                    print("새로고침")
                    self.myWebVM.webNavigationSubject.send(.REFRESH)
                }, label: {
                    Image(systemName: "goforward")
                        .font(.system(size: 20))
                })
                Spacer()
            }.frame(height: 45)
            Divider()
        }
    }
    
}


extension ContentView {
    
    // 공유창 띄우기
    func shareSheet(url: URL) {
        print("ContentView - shareSheet() called")
        let uiActivityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(uiActivityVC, animated: true, completion: nil)
    }
    
    // 얼럿창 띄우기
    func createAlert(_ alert: JsAlert) -> Alert {
        Alert(title: Text(alert.type.description),
              message: Text(alert.message),
              dismissButton: .default(Text("확인"), action: {
                print("알림창 확인 버튼이 클릭되었다.")
              }))
    }
    
    // 텍스트 입력 얼럿창
    func createTextAlert() -> MyTextAlertView {
        MyTextAlertView(textString: $textString, showAlert: $shouldShowAlert, title: "iOS->Js 보내기", message: "")
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
