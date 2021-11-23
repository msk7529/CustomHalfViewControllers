//
//  HalfViewWithKeyboardViewController.swift
//  HalfVCTest
//
//  Created by on 2021/06/02.
//

import Combine
import UIKit

protocol HalfViewWithKeyboardViewControllerDelegate: AnyObject {
    func HalfVCButtonDidTap()
}

final class HalfViewWithKeyboardViewController: UIViewController {
        
    private let titleLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.text = "하프뷰 타이틀"
        label.textColor = .black
        label.font = .systemFont(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField: UITextField = .init(frame: .zero)
        textField.attributedPlaceholder = NSAttributedString(string: "플레이스 홀더", attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.lightGray])
        textField.delegate = self
        textField.font = .systemFont(ofSize: 17)
        textField.enablesReturnKeyAutomatically = true
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.becomeFirstResponder()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let textFieldBottomLine: UIView = {
        let view: UIView = .init(frame: .zero)
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let textLengthLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.text = "0/0"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override var shouldAutorotate: Bool {
        // 팬제스처 동작중 회전 방지 처리
        return isPanGestureActivated ? false : true
    }
    
    private var titleLengthPublisher: CurrentValueSubject<Int, Never> = .init(0)
    private let maxTitleLength: Int = 30
    
    // panGesture
    var isPanGestureActivated: Bool = false
    var originY: CGFloat = 0
    
    // ModalWithKeyboardPresentable
    var keyboardHeightOnPortrait: CGFloat = 0
    var keyboardHeightOnLandscape: CGFloat = 0
    var keyboardAnimationDuration: Double = 0.4
    var keyboardObserver: NSObjectProtocol?
    
    var cancellables: Set<AnyCancellable> = .init()
    
    weak var delegate: HalfViewWithKeyboardViewControllerDelegate?
    
    deinit {
        removeKeyboardObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(textField)
        view.addSubview(textFieldBottomLine)
        view.addSubview(textLengthLabel)
        
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 18).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16.5).isActive = true
        textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 41).isActive = true
        
        textFieldBottomLine.topAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        textFieldBottomLine.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        textFieldBottomLine.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        textFieldBottomLine.heightAnchor.constraint(equalToConstant: 2).isActive = true
        
        textLengthLabel.topAnchor.constraint(equalTo: textFieldBottomLine.bottomAnchor, constant: 3).isActive = true
        textLengthLabel.trailingAnchor.constraint(equalTo: textFieldBottomLine.trailingAnchor).isActive = true
        
        addKeyboardObserver()
        
        titleLengthPublisher
            .sink { [weak self] length in
                guard let `self` = self else { return }
                self.textLengthLabel.text = "\(length)/\(self.maxTitleLength)"
            }.store(in: &cancellables)
        
        addPanGesture()
    }
    
    override func viewWillLayoutSubviews() {
        self.view.add(roundedCorners: [.topLeft, .topRight], with: CGSize(width: 12, height: 12))
    }
        
    @objc private func buttonDidTap() {
        delegate?.HalfVCButtonDidTap()
        dismiss(animated: true, completion: nil)
    }
}

extension HalfViewWithKeyboardViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return false  }
        let newLength = text.count + string.count - range.length
        if newLength <= maxTitleLength {
            titleLengthPublisher.value = newLength
        }
        return newLength <= maxTitleLength
    }
}

extension HalfViewWithKeyboardViewController: ModalWithKeyboardPresentable {
    var isPanGestureEnable: Bool {
        return true
    }
    
    var keyboardDisAppearPosY: CGFloat {
        return 120
    }
    
    var heightInPortrait: CGFloat {
        return 198.5
    }
    
    var heightInLandScape: CGFloat {
        return 198.5
    }
    
    /*
    @objc override func didPanGesture(_ sender: UIPanGestureRecognizer) {
        // 별도의 작업이 필요한 경우 뷰컨에서 override 한다.
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
                self.textField.resignFirstResponder()
            }
        case .ended:
            self.isPanGestureActivated = false
            
            if self.originY..<self.originY + self.keyboardDisAppearPosY ~= view.frame.origin.y {
                UIView.animate(withDuration: self.keyboardAnimationDuration) {
                    self.view.frame.origin.y = self.originY
                    self.textField.becomeFirstResponder()
                }
            } else {
                dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
    */
}
