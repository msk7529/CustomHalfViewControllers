//
//  ModalWithKeyboardPresentable.swift
//  HalfVCTest
//
//  Created by kakao on 2021/11/22.
//

import Combine
import UIKit

public protocol ModalWithKeyboardPresentable: AnyObject {
    typealias ObjectType = UIViewController & ModalWithKeyboardPresentable
    
    var heightInPortrait: CGFloat { get } // 키보드를 제외한 뷰컨의 높이(세로모드)
    var heightInLandScape: CGFloat { get } // 키보드를 제외한 뷰컨의 높이(가로모드)
    
    var orientation: UIInterfaceOrientation { get }
    var isKeyboardShowing: Bool { get set }     // 하드웨어 키보드를 사용하는 경우 present시에 키보드가 바로 안 올라오기 때문에 safeArea만큼 뷰컨의 높이를 높이기 위함
    var keyboardHeightOnPortrait: CGFloat { get set }
    var keyboardHeightOnLandscape: CGFloat { get set }
    var keyboardAnimationDuration: Double  { get set }
    //var cancellables: Set<AnyCancellable> { get set }
    var keyboardObserver: NSObjectProtocol? { get set }
    var keyboardObserver2: NSObjectProtocol? { get set }
    
    func addKeyboardObserver()      // viewDidLaod에서 텍스트필드 또는 텍스트뷰 becomeFirstResponder 호출후, 호출해주어야 한다.
    func removeKeyboardObserver()   // 옵저버 제거
    
    /// 팬제스처 지원을 위한 프로퍼티, 메서드
    var isPanGestureEnable: Bool { get }
    var originY: CGFloat { get set }
    var keyboardDisAppearPosY: CGFloat { get }      // 팬제스처 도중 키보드가 특정 시점을 기준으로 키보드를 내리고자 한다면 세팅한다.
    var isPanGestureActivated: Bool { get set }     // 팬제스처 도중에 회전을 막기 위함
    func addPanGesture()                            // 팬제스처 지원을 하고자 한다면 viewDidLoad에서 호출한다.
}

public extension ModalWithKeyboardPresentable where Self: UIViewController {
    var orientation: UIInterfaceOrientation  {
        if let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            return orientation
        }
        return .portrait
    }
    
    var isPanGestureEnable: Bool {
        return true
    }
    
    var keyboardDisAppearPosY: CGFloat {
        return 50
    }
    
    var heightInPortrait: CGFloat {
        return 198.5
    }
    
    var heightInLandScape: CGFloat {
        return 198.5
    }
    
//    func addKeyboardNotification() {
//        NotificationCenter.default
//            .publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
//            .sink { [weak self] noti in
//                guard let `self` = self, let userInfo = noti.userInfo,
//                      let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
//                      let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
//                          return
//                      }
//                if self.orientation == .portrait {
//                    self.keyboardHeightOnPortrait = keyboardHeight
//                } else {
//                    self.keyboardHeightOnLandscape = keyboardHeight
//                }
//                self.keyboardAnimationDuration = keyboardAnimationDuration
//            }.store(in: &cancellables)
//    }
    
    func addKeyboardObserver() {
        // 반드시 show, change 두 개의 옵저버를 등록해야 한다. change는 키보드 위에 나타나는 QuickType Bar가 나타났을때 높이를 재조정하기 위함.
        keyboardObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main, using: { [weak self] noti in
            guard let `self` = self, let userInfo = noti.userInfo,
                  let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
                  let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                      return
                  }
            self.isKeyboardShowing = true
            if self.orientation == .portrait {
                self.keyboardHeightOnPortrait = keyboardHeight
            } else {
                self.keyboardHeightOnLandscape = keyboardHeight
            }
            self.keyboardAnimationDuration = keyboardAnimationDuration
        })
        
        keyboardObserver2 = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidChangeFrameNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.presentationController?.containerViewWillLayoutSubviews()
        })
    }
    
    func removeKeyboardObserver() {
        if let keyboardObserver = keyboardObserver {
            NotificationCenter.default.removeObserver(keyboardObserver)
        }
        if let keyboardObserver2 = keyboardObserver2 {
            NotificationCenter.default.removeObserver(keyboardObserver2)
        }
    }
    
    func addPanGesture() {
        if isPanGestureEnable {
            view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPanGesture(_:))))
        }
    }
}

public extension UIViewController {
    private var textView: UIControl? {
        return view.subviews.first(where: { $0 is UITextView || $0 is UITextField }) as? UIControl
    }
    
    @objc func didPanGesture(_ sender: UIPanGestureRecognizer) {
        // 별도의 작업이 필요한 경우 뷰컨에서 override 한다.
        guard let self = self as? (UIViewController & ModalWithKeyboardPresentable), self.isPanGestureEnable else {
            return
        }
        
        let viewTranslation = sender.translation(in: view)
 
        switch sender.state {
        case .began:
            self.originY = view.frame.origin.y
            self.isPanGestureActivated = true
        case .changed:
            let newOriginY = viewTranslation.y + self.originY
            if self.originY < newOriginY {
                // 위쪽으로의 팬제스처는 막는다.
                view.frame.origin.y = max(self.originY, viewTranslation.y + self.originY)
            }
            if self.originY + self.keyboardDisAppearPosY <= newOriginY {
                // 특정시점을 기준으로 키보드를 내린다.
                self.textView?.resignFirstResponder()
            }
        case .ended:
            self.isPanGestureActivated = false
            
            if self.originY..<self.originY + self.keyboardDisAppearPosY ~= view.frame.origin.y {
                UIView.animate(withDuration: self.keyboardAnimationDuration) {
                    self.view.frame.origin.y = self.originY
                    self.textView?.becomeFirstResponder()
                }
            } else {
                dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
}
