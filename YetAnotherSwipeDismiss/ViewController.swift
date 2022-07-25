//
//  ViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 08/07/2022.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentDismissViewController)))
        
        let viewControllers = [
            UIViewController(),
            SimpleViewController(),
            StackViewController(),
            TableViewController()
        ]
        
        viewControllers.first?.view.backgroundColor = .green
        
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
            configuration.title = "\(type(of: viewController))"
            let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
                present(viewController, animated: true)
            })
            stackView.addArrangedSubview(button)
        }
        //        present(emptyViewController, animated: true)
                
        //        let simpleViewController = SimpleViewController()
        //        present(simpleViewController, animated: true)
        //
//                let stackViewController = StackViewController()
//                present(stackViewController, animated: true)
                
        //        let tableViewController = TableViewController()
        //        present(tableViewController, animated: true)
        // TODO: Stack View with buttons for each view controller
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        presentDismissViewController()
    }
    
    @objc func presentDismissViewController() {
        
//        let emptyViewController = UIViewController()
//        present(emptyViewController, animated: true)
        
//        let simpleViewController = SimpleViewController()
//        present(simpleViewController, animated: true)
//
//        let stackViewController = StackViewController()
//        present(stackViewController, animated: true)
        
//        let tableViewController = TableViewController()
//        present(tableViewController, animated: true)
        
    }
}

