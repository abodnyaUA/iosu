//
//  MainMenuButton.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/15/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import Cartography

class MainMenuButton: UIControl {
    
    private lazy var container: UIView = { [unowned self] in
        let container = UIView()
        container.layer.cornerRadius = 4.0
        container.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        container.layer.shadowOpacity = 0.4
        container.layer.shadowOffset = CGSize(width: 4.0, height: 4.0)
        container.backgroundColor = #colorLiteral(red: 0.9098039216, green: 0.3215686275, blue: 0.5921568627, alpha: 1)
        
        [self.titleLabel, self.subtitleLabel, self.iconView].forEach { (view) in
            container.addSubview(view)
        }
        
        constrain(self.titleLabel, self.subtitleLabel, self.iconView, container) { (title, subtitle, icon, parent) in
            title.left == parent.left + 100.0
            title.top == parent.top + 8.0
            title.right == icon.left
            subtitle.left == title.left
            subtitle.right == title.right
            subtitle.top == title.bottom
            subtitle.bottom <= parent.bottom - 4.0
            icon.right == parent.right
            icon.top == parent.top + 8.0
            icon.width == icon.height
            icon.bottom == parent.bottom - 8.0
        }
        return container
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 34.0, weight: .semibold)
        label.textColor = .white
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11.0, weight: .regular)
        label.textColor = .white
        return label
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        finishInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInit()
    }
    
    private func finishInit() {
        backgroundColor = .clear
        addSubview(container)
        constrain(container, self) { (container, parent) in
            container.edges == parent.edges
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            container.backgroundColor = isHighlighted ? #colorLiteral(red: 0.9098039216, green: 0.5405347823, blue: 0.7549304779, alpha: 1) : #colorLiteral(red: 0.9098039216, green: 0.3215686275, blue: 0.5921568627, alpha: 1)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.contains(point) ? self : super.hitTest(point, with: event)
    }
}
