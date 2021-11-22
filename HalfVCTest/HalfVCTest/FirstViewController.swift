//
//  ViewController.swift
//  HalfVCTest
//
//  Created on 2021/06/02.
//

import UIKit

class FirstViewController: UIViewController {

    private lazy var modalWithKeyboardTransitionDelegate: ModalWithKeyboardTransitionDelegate = {
        return .init(heightInPortrait: 198.5, heightInLandScape: 198.5)
    }()
    
    private lazy var button1: UIButton = {
        let button: UIButton = .init(type: .system)
        button.backgroundColor = .systemTeal
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("  present HalfVC with TextField  ", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(didTapButton1), for: .touchUpInside)
        return button
    }()
    
    private var originLayout: [NSLayoutConstraint] = []
    private var newLayout: [NSLayoutConstraint] = []
    
    private var isOriginLayout: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(button1)
        
        let aaa = button1.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 30)
        let bbb = button1.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 30)
        let ccc = button1.heightAnchor.constraint(equalToConstant: 30)
        
        self.originLayout = [aaa, bbb, ccc]
        NSLayoutConstraint.activate(originLayout)
        
        print(self.view.safeAreaInsets.bottom)
    }
    
    private func changeLayout() {
        if !isOriginLayout {
            NSLayoutConstraint.deactivate(newLayout)
            NSLayoutConstraint.activate(originLayout)
            isOriginLayout = true
        } else {
            NSLayoutConstraint.deactivate(originLayout)
            
            let aaa = button1.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 50)
            let bbb = button1.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50)
            let ccc = button1.heightAnchor.constraint(equalToConstant: 50)
            
            self.newLayout = [aaa, bbb, ccc]
            
            NSLayoutConstraint.activate(newLayout)
            isOriginLayout = false
        }
    }
    
    @objc func didTapButton1() {
        changeLayout()
        
        let nextVC: HalfViewWithKeyboardViewController = .init()
        nextVC.transitioningDelegate = self.modalWithKeyboardTransitionDelegate
        nextVC.delegate = self
        nextVC.modalPresentationStyle = .custom
        present(nextVC, animated: true, completion: nil)
    }
}

extension FirstViewController: HalfViewWithKeyboardViewControllerDelegate {
    func HalfVCButtonDidTap() {
        print("secondVC button did Tap")
    }
}
