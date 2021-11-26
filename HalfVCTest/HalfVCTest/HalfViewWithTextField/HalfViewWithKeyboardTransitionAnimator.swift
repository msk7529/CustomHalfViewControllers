//
//  HalfViewWithKeyboardTransitionAnimator.swift
//
//  Created by on 2021/06/02.
//

import UIKit


final class ModalWithKeyboardTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    // 뷰컨이 present됨과 동시에 키보드가 노출되어야 하는 화면(텍스트뷰 또는 텍스트필드가 존재)에서 사용한다.
    
    public static var `default`: ModalWithKeyboardTransitionDelegate = {
        return ModalWithKeyboardTransitionDelegate()
    }()
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalWithKeyboardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalWithKeyboardTransitionAnimator(isPresent: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalWithKeyboardTransitionAnimator(isPresent: false)
    }
}

final class ModalWithKeyboardPresentationController: UIPresentationController {
    private let dimmedView: UIView = {
        let view: UIView = .init()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var interfaceOrientation: UIInterfaceOrientation  {
        if let orientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            return orientation
        }
        return .portrait
    }
    
    private var isKeyboardShowing: Bool {
        guard let vc = presentedViewController as? (UIViewController & ModalWithKeyboardPresentable) else {
            return false
        }
        return vc.isKeyboardShowing
    }
    
    private var keyboardHeight: CGFloat {
        guard let vc = presentedViewController as? (UIViewController & ModalWithKeyboardPresentable) else {
            return 0
        }
        return interfaceOrientation == .portrait ? vc.keyboardHeightOnPortrait : vc.keyboardHeightOnLandscape
    }
    
    private var heightInPortrait: CGFloat {
        guard let vc = presentedViewController as? (UIViewController & ModalWithKeyboardPresentable) else {
            return 0
        }
        return vc.heightInPortrait
    }
    
    private var heightInLandScape: CGFloat {
        guard let vc = presentedViewController as? (UIViewController & ModalWithKeyboardPresentable) else {
            return 0
        }
        return vc.heightInLandScape
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        if interfaceOrientation != .portrait {
            //가로모드에서 양옆의 여백을 주고싶으면 여기에 코드를 추가한다.(ex: frame.origin.x = 40)
        }
        frame.origin.y = containerView.frame.height - frame.size.height
        return frame
    }
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        let recognizer: UITapGestureRecognizer = .init(target: self, action: #selector(dismissPresentingVC))
        dimmedView.addGestureRecognizer(recognizer)
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        
        containerView.insertSubview(dimmedView, at: 0)
                
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmedView.alpha = 1.0
            }, completion: nil)
        } else {
            self.dimmedView.alpha = 1.0
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmedView.alpha = 0.0
            }, completion: nil)
        } else {
            self.dimmedView.alpha = 0.0
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard let containerView = containerView, let presentedView = presentedView else {
            return
        }
        super.containerViewWillLayoutSubviews()
        
        presentedView.frame = frameOfPresentedViewInContainerView
        presentedView.add(roundedCorners: [.topLeft, .topRight], with: CGSize(width: 12, height: 12))
        dimmedView.frame = containerView.frame
    }
    
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let additionalHeight = isKeyboardShowing ? keyboardHeight : presentedViewController.view.safeAreaInsets.bottom
        if interfaceOrientation == .portrait {
            return CGSize(width: parentSize.width, height: heightInPortrait + additionalHeight)
        } else {
            return CGSize(width: parentSize.width, height: heightInLandScape + additionalHeight)
        }
    }
    
    @objc private func dismissPresentingVC() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}

final class ModalWithKeyboardTransitionAnimator: NSObject {
    var isPresent: Bool
    
    init(isPresent: Bool) {
        self.isPresent = isPresent
        super.init()
    }
}

extension ModalWithKeyboardTransitionAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3  // 이 값은 사용되지 않는다.
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresent ? .to : .from

        guard let controller = transitionContext.viewController(forKey: key) else { return}

        let keyboardAnimationDuration = max(((controller as? ModalWithKeyboardPresentable)?.keyboardAnimationDuration ?? 0.4) - 0.1, 0.2)   // 키보드 애니메이션과 VC present 애니메이션이 최대한 자연스럽도록 조정
        
        if isPresent {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentFrame: CGRect = transitionContext.finalFrame(for: controller)
        var dismissFrame: CGRect = presentFrame
        dismissFrame.origin.y += presentFrame.height


        let initialFrame: CGRect = isPresent ? dismissFrame : presentFrame
        let finalFrame: CGRect = isPresent ? presentFrame : dismissFrame

        controller.view.frame = initialFrame

//        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
        UIView.animate(withDuration: keyboardAnimationDuration, animations: {
            controller.view.frame = finalFrame
        }) { finished in
            if !self.isPresent {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        }
    }
}

public extension UIView {
    func add(roundedCorners: UIRectCorner, with radii: CGSize) {
        layer.mask = mask(for: roundedCorners, with: radii)
    }
    
    func mask(for roundedCorners: UIRectCorner, with radii: CGSize) -> CALayer {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.path = UIBezierPath(roundedRect: maskLayer.bounds, byRoundingCorners: roundedCorners, cornerRadii: radii).cgPath
        return maskLayer
    }
}
