//
//  WebViewRefreshControlHelper.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/12.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

class MyWebViewRefreshConrolHelper {
    
    //MARK: Properties
    var refreshControl : UIRefreshControl?
    var viewModel : WebViewModel?
    
    
    @objc func didRefresh(){
        print("MyWebViewRefreshConrolHelper - didRefresh() called")
        guard let refreshControl = refreshControl,
              let viewModel = viewModel else {
            print("refreshControl, viewModel 가 없습니다.")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
            print("리프레시가 되었습니다.")
            viewModel.webNavigationSubject.send(.REFRESH)
            refreshControl.endRefreshing()
        })
    }
    
}
