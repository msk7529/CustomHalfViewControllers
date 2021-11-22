//
//  ModalWithKeyboardPresentable.swift
//  HalfVCTest
//
//  Created by kakao on 2021/11/22.
//

import Combine
import UIKit

public protocol ModalWithKeyboardPresentable: AnyObject {
    var cancellables: Set<AnyCancellable> { get set }
    var orientation: UIInterfaceOrientation { get }
    var keyboardHeightOnPortrait: CGFloat { get set }
    var keyboardHeightOnLandscape: CGFloat { get set }
    var keyboardAnimationDuration: Double  { get set }
    func addKeyboardNotification()  // viewDidLaod에서 텍스트필드 또는 텍스트뷰 becomeFirstResponder 호출후, 호출해주어야 한다.
}

public extension ModalWithKeyboardPresentable where Self: UIViewController {
    var orientation: UIInterfaceOrientation  {
        if let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            return orientation
        }
        return .portrait
    }
    
    func addKeyboardNotification() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { [weak self] noti in
                guard let `self` = self, let userInfo = noti.userInfo,
                      let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
                      let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                          return
                      }
                if self.orientation == .portrait {
                    self.keyboardHeightOnPortrait = keyboardHeight
                } else {
                    self.keyboardHeightOnLandscape = keyboardHeight
                }
                self.keyboardAnimationDuration = keyboardAnimationDuration
            }.store(in: &cancellables)
    }
}
