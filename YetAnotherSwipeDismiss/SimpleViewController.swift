//
//  SimpleViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit

class SimpleViewController: UIViewController, PanelPresentable {
	
	let panelController = PanelController()
	
	init() {
		super.init(nibName: nil, bundle: nil)
		panelController.viewController = self
	}
	
	private lazy var simpleView: UIView = {
		let view = UIView()
		view.backgroundColor = .systemMint.withAlphaComponent(0.25)
		return view
	}()
	
	private lazy var cancelButton: UIButton = {
		var configuration = UIButton.Configuration.plain()
		configuration.title = "Cancel"
		let button = UIButton(configuration: configuration)
		button.addAction(UIAction { [unowned self] _ in
			self.presentingViewController?.dismiss(animated: true)
		}, for: .touchUpInside)
		return button
	}()
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		contentView.addSubview(simpleView)
		simpleView.extendToSuperview()
		simpleView.heightAnchor.constraint(equalToConstant: 400).isActive = true
		
		headerContentView.addSubview(cancelButton)
		cancelButton.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.leadingAnchor)
			$0.centerYAnchor.constraint(equalTo: headerContentView.layoutMarginsGuide.centerYAnchor)
		}
	}
}
