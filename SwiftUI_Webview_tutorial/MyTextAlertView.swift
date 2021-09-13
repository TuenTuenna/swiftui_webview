//
//  MyTextAlertView.swift
//  SwiftUI_Webview_tutorial
//
//  Created by Jeff Jeong on 2021/09/11.
//  Copyright © 2021 Tuentuenna. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct MyTextAlertView: UIViewControllerRepresentable {
    
    @EnvironmentObject var webVM: WebViewModel
    
    @Binding var textString: String
    @Binding var showAlert: Bool
    
    var title: String
    var message: String
    
    // 처음
    func makeUIViewController(context: UIViewControllerRepresentableContext<MyTextAlertView>) -> UIViewController {
        return UIViewController()
    }
    
    // 값이 변경이 될때
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MyTextAlertView>) {
        
        // uiAlertController 가 없을때만 띄우겠다.
        guard context.coordinator.uiAlertController == nil else { return }
        
        // showAlert 이 트루라면
        if self.showAlert {
            
            // alert 컨트롤러를 띄우다
            
            let uiAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            uiAlertController.addTextField(configurationHandler: { textField in
                textField.placeholder = "전달할 값을 입력하세요"
                textField.text = self.textString
            })
            
            uiAlertController.addAction(UIAlertAction(title: "취소", style: .destructive, handler: { _ in
                    print("취소가 클릭되었다.")
                    self.textString = ""
            }))
            
            uiAlertController.addAction(UIAlertAction(title: "보내기", style: .default, handler: { _ in
                    print("취소가 클릭되었다.")
                
                if let textField = uiAlertController.textFields?.first,
                   let inputText = textField.text {
                    self.textString = inputText
                }
                
                uiAlertController.dismiss(animated: true, completion: {
                    print("보내기 버튼 클릭")
                    self.webVM.nativeToJsEvent.send(textString)
                    self.textString = ""
                    self.showAlert = false
                })
            }))
            
            DispatchQueue.main.async {
                uiViewController.present(uiAlertController, animated: true, completion: {
                    self.showAlert = false
                    context.coordinator.uiAlertController = nil
                })
            }
            
        }
        
        
        
    }
    
    
    func makeCoordinator() -> MyTextAlertView.Coordinator {
        
        MyTextAlertView.Coordinator(self)
        
    }
    
    // 중간의 매개체 UIKit 의 델리겟 등의 이벤트를 받아주는 역할
    class Coordinator : NSObject {
        
        var uiAlertController: UIAlertController? // UIKit 뷰
        
        var myTextAlertView: MyTextAlertView // SwiftUi 뷰
        
        init(_ myTextAlertView : MyTextAlertView) {
            self.myTextAlertView = myTextAlertView
        }
        
    }
    
    
}

extension MyTextAlertView.Coordinator : UITextFieldDelegate {
    
    // 글자가 입력이 될때
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            self.myTextAlertView.textString = text.replacingCharacters(in: range, with: string)
        } else {
            self.myTextAlertView.textString = ""
        }
        return true
    }
}


