//
//  CustomCollectionViewCell.swift
//  HalfVCTest
//
//  Created by on 2021/06/06.
//

import UIKit

final class CustomCollectionViewCell: UICollectionViewCell {
    static let identifier: String = "CustomCollectionViewCell"
    
    private let textLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.text = "text"
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var cellText: String = "" {
        didSet {
            textLabel.text = cellText
        }
    }
    
    private var trailingConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        contentView.addSubview(textLabel)
        
        trailingConstraint = textLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor)
        trailingConstraint?.isActive = true
        topConstraint = textLabel.topAnchor.constraint(equalTo: contentView.topAnchor)
        topConstraint?.isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(didChangeOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        initContraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initContraints() {
        if UIDevice.current.orientation == .landscapeRight {
            trailingConstraint?.constant = -16
        } else {
            trailingConstraint?.constant = 0
        }
        topConstraint?.constant = 10
    }
    
    @objc private func didChangeOrientation() {
        initContraints()
    }
}
