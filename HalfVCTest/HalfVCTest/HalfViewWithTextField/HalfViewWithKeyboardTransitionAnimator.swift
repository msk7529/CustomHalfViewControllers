//
//  HalfViewWithKeyboardTransitionAnimator.swift
//
//  Created by on 2021/06/02.
//

import UIKit


final class HalfViewWithKeyboardTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfViewWithKeyboardPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HalfViewWithKeyboardTransitionAnimator(isPresent: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return HalfViewWithKeyboardTransitionAnimator(isPresent: false)
    }
}

final class HalfViewWithKeyboardPresentationController: UIPresentationController {
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
    
    private var keyboardHeight: CGFloat {
        if let halfVC = presentedViewController as? HalfViewWithKeyboardViewController {
            return interfaceOrientation == .portrait ? halfVC.keyboardHeightOnPortrait : halfVC.keyboardHeightOnLandscape
        }
        return 0
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        if interfaceOrientation != .portrait {
            //frame.origin.x = 40
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
        //presentedView.add(roundedCorners: [.topLeft, .topRight], with: CGSize(width: 12, height: 12))
        dimmedView.frame = containerView.frame
    }
    
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if interfaceOrientation == .portrait {
            return CGSize(width: parentSize.width, height: 198.5 + keyboardHeight)
        } else {
            return CGSize(width: parentSize.width, height: 198.5 + keyboardHeight)
        }
    }
    
    @objc private func dismissPresentingVC() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}

final class HalfViewWithKeyboardTransitionAnimator: NSObject {
    var isPresent: Bool
    
    init(isPresent: Bool) {
        self.isPresent = isPresent
        super.init()
    }
}

extension HalfViewWithKeyboardTransitionAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key: UITransitionContextViewControllerKey = isPresent ? .to : .from

        guard let controller = transitionContext.viewController(forKey: key) else { return}

        let keyboardAnimationDuration = max(((controller as? HalfViewWithKeyboardViewController)?.keyboardAnimationDuration ?? 0.4) - 0.1, 0.2)   // 키보드 애니메이션과 VC present 애니메이션이 최대한 자연스럽도록 조정
        
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
