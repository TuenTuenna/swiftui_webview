//
//  WebViewModel.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/11.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation
import Combine

typealias WEB_NAVIGATION = WebViewModel.NAVIGATION

class WebViewModel: ObservableObject {
    
    enum NAVIGATION {
        case BACK, FORWARD, REFRESH
    }
    
    enum URL_TYPE {
        case NAVER
        case GOOGLE
        case DEV_JEONG_DAE_RI
        var url : URL? {
            switch self {
            case .NAVER:            return URL(string: "https://www.naver.com")
            case .GOOGLE:           return URL(string: "https://www.google.com")
            case .DEV_JEONG_DAE_RI: return URL(string: "https://tuentuenna.github.io/simple_js_alert/")
            }
        }
    }
    
    // 웹뷰의 url 이 변경되었을 때 이벤트
    var changedUrlSubject = PassthroughSubject<WebViewModel.URL_TYPE, Never>()
    
    // 웹뷰 네비게이션 액션에 대한 이벤트
    var webNavigationSubject = PassthroughSubject<WEB_NAVIGATION, Never>()
    
    // 웹사이트 타이블 이벤트
    var webSiteTitleSubject = PassthroughSubject<String, Never>()
    
    // iOS -> JS 함수 호출
    var nativeToJsEvent = PassthroughSubject<String, Never>()
    
    // 자바스크립트 alert 이 들어오면 이벤트 보내기
    var jsAlertEvent = PassthroughSubject<JsAlert, Never>()
    
    // 로딩 여부 이벤트
    var shouldShowIndicator = PassthroughSubject<Bool, Never>()
    
}
