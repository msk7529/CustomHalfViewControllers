//
//  UIViewController+PresentModalWithKeyboard.swift
//  HalfVCTest
//
//  Created by kakao on 2021/11/23.
//

import Foundation
import UIKit

public extension UIViewController {
    
    func presentModalWithKeyboard(_ viewControllerToPresent: ModalWithKeyboardPresentable.ObjectType, completion: (() -> Void)? = nil) {
        // 뷰컨이 present됨과 동시에 키보드가 노출되어야 하는 화면(텍스트뷰 또는 텍스트필드가 존재)에서 사용한다.
        
        viewControllerToPresent.modalPresentationStyle = .custom
        viewControllerToPresent.modalPresentationCapturesStatusBarAppearance = true
        viewControllerToPresent.transitioningDelegate = ModalWithKeyboardTransitionDelegate.default

        present(viewControllerToPresent, animated: true, completion: completion)
    }
}
