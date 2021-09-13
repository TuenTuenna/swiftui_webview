//
//  String+Ext.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/13.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation

extension String {
    
    // mime type 을 가져오는 메소드
    func getReadableMimeType() -> String {
        print("String - getReadableMimeType()")
        if let mimeType = mimeTypes.first(where: { (key: String, value: String) in
            value == self
        }) {
            return mimeType.key
        } else {
            return "unknown"
        }
    }
}
