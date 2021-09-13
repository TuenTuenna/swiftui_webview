//
//  LoadingScreenView.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/11.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation
import SwiftUI

// 로딩 스크린뷰
struct LoadingScreenView: View {
    var body: some View{
        ZStack(alignment: .center, content: {
            Color.black
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            LoadingIndicatorView()
        })
    }
}
