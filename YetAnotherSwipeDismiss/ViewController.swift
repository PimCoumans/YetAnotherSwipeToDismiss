//
//  ViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 08/07/2022.
//

import UIKit

class ViewController: UIViewController {
    
    let viewControllers = [
        UIViewController(),
        SimpleViewController(),
        StackViewController(),
        TableViewController()
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        view.addSubview(stackView)
        
        stackView.applyConstraints {
            $0.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            $0.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        }
        
        viewControllers.forEach { viewController in
            var configuration = UIButton.Configuration.plain()
            configuration.title = "\(type(of: viewController.self))"
            let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
                let newViewController = type(of: viewController).init()
                if viewController == viewControllers.first {
                    newViewController.view.backgroundColor = .green
                }
                present(newViewController, animated: true)
            })
            stackView.addArrangedSubview(button)
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        present(viewControllers[2], animated: true)
    }
}

