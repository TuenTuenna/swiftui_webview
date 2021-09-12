//
//  JsAlert.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/11.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation

// 자바스크립트 알림창 에러
struct JsAlert: Identifiable {
    
    enum TYPE: CustomStringConvertible {
        
        case JS_ALERT, JS_BRIDGE
        
        var description: String {
            switch self {
            case .JS_ALERT: return "JS_ALERT 타입"
            case .JS_BRIDGE: return "JS_BRIDGE 타입"
            }
        }
    }
    
    let id: UUID = UUID()
    var message: String = ""
    
    var type: TYPE
    
    init(_ message: String? = nil, _ type: TYPE) {
        self.message = message ?? "메세지 없음"
        self.type = type
    }
    
}
