//
//  HalfViewWithKeyboardViewController.swift
//  HalfVCTest
//
//  Created by on 2021/06/02.
//

import Combine
import UIKit
import SnapKit

protocol HalfViewWithKeyboardViewControllerDelegate: AnyObject {
    func HalfVCButtonDidTap()
}

final class HalfViewWithKeyboardViewController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView: UIScrollView = .init(frame: .zero)
        scrollView.bounces = false
        scrollView.delegate = self
        return scrollView
    }()
    
    private let containerView: UIView = .init(frame: .zero)
    
    private let titleLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.text = "하프뷰 타이틀"
        label.textColor = .black
        label.font = .systemFont(ofSize: 15)
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
        textField.autocorrectionType = .no      // 키보드 추천영역 안뜨도록. 2줄을 모두 써주어야 15에서 정상
        textField.spellCheckingType = .no
        textField.becomeFirstResponder()
        return textField
    }()
    
    private let textFieldBottomLine: UIView = {
        let view: UIView = .init(frame: .zero)
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let textLengthLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.text = "0/0"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 13)
        return label
    }()
    
    private let confirmButton: UIButton = {
        let button: UIButton = .init(frame: .zero)
        button.setTitle("확인", for: .normal)
        button.backgroundColor = .systemYellow
        return button
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
    var isKeyboardShowing: Bool = false
    var keyboardHeightOnPortrait: CGFloat = 0
    var keyboardHeightOnLandscape: CGFloat = 0
    var keyboardAnimationDuration: Double = 0.4
    var keyboardObserver: NSObjectProtocol?
    var keyboardObserver2: NSObjectProtocol?

    
    var cancellables: Set<AnyCancellable> = .init()
    
    weak var delegate: HalfViewWithKeyboardViewControllerDelegate?
    
    deinit {
        removeKeyboardObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.centerX.equalToSuperview()
        }
        
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        scrollView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide.snp.top)
            make.left.equalTo(scrollView.contentLayoutGuide.snp.left)
            make.right.equalTo(scrollView.contentLayoutGuide.snp.right)
            make.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom)
            make.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }
        
        [textField, textFieldBottomLine, textLengthLabel, confirmButton].forEach {
            containerView.addSubview($0)
        }
        
        textField.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.top).offset(16.5)
            make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(15)
            make.right.equalTo(containerView.safeAreaLayoutGuide.snp.right).offset(-10)
            make.height.equalTo(41)
        }
        
        textFieldBottomLine.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom)
            make.left.right.equalTo(textField)
            make.height.equalTo(2)
        }

        textLengthLabel.snp.makeConstraints { make in
            make.top.equalTo(textFieldBottomLine.snp.bottom).offset(3)
            make.right.equalTo(textFieldBottomLine)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(textFieldBottomLine.snp.bottom).offset(31.5)
            make.left.right.equalTo(textFieldBottomLine)
            make.height.equalTo(45)
            make.bottom.equalTo(containerView)
        }
        
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if orientation != .portrait {
            textField.resignFirstResponder()
        }
        return true
        //return orientation == .portrait ? false : true
    }
}

extension HalfViewWithKeyboardViewController: UIScrollViewDelegate { }

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
    
    var containerViewOfScrollView: UIView? {
        return containerView
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
