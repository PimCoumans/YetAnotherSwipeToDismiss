//
//  SimpleViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit

class SimpleViewController: UIViewController, PanelPresentable {
    
    let panelController = PanelController()
    
    private lazy var simpleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemMint
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addAction(UIAction { [unowned self] _ in
            self.presentingViewController?.dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        panelController.viewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .black
        
        contentView.addSubview(simpleView)
        simpleView.extendToSuperview()
        simpleView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        topContentView.addSubview(cancelButton)
        cancelButton.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.leadingAnchor)
            $0.centerYAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.centerYAnchor)
        }
    }
}
