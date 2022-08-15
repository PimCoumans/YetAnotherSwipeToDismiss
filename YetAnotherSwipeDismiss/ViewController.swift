//
//  ViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 08/07/2022.
//

import UIKit

class ViewController: UIViewController {
	
	enum ViewControllerType: CaseIterable {
		case unsuspecting
		case simple
		case stack
		case smallTableView
		case bigTableView
	}
	
	let stackView = UIStackView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .white
		
		stackView.axis = .vertical
		stackView.alignment = .fill
		stackView.distribution = .fillEqually
		stackView.spacing = 8
		
		view.addSubview(stackView)
		
		stackView.applyConstraints {
			$0.centerXAnchor.constraint(equalTo: view.centerXAnchor)
			$0.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		}
		
		ViewControllerType.allCases.forEach { type in
			var configuration = UIButton.Configuration.borderedProminent()
			configuration.buttonSize = .large
			configuration.title = "Show \(type) panel"
			let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
				present(type: type)
			})
			stackView.addArrangedSubview(button)
		}
	}
	
	func present(type: ViewControllerType) {
		switch type {
		case .unsuspecting:
			let viewController = UnsuspectingViewController()
			let panelController = PanelController()
			panelController.viewController = viewController
			present(viewController, animated: true)
		case .simple: present(SimpleViewController(), animated: true)
		case .stack: present(StackViewController(), animated: true)
		case .smallTableView: present(TableViewController(), animated: true)
		case .bigTableView: present(TableViewController(cellCount: 86), animated: true)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		//		present(type: .stack)
	}
}

