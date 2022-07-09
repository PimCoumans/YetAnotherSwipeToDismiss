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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentDismissViewController()
    }
    
    @objc func presentDismissViewController() {
        
        let viewController = StackViewController()
        present(viewController, animated: true)
        
    }
}

