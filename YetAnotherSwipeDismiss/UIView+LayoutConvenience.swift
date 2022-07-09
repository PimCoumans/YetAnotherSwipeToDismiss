//
//  UIView+LayoutConvenience.swift
//  ModelView
//
//  Created by Pim on 08/07/2022.
//

import UIKit

extension NSLayoutConstraint {
    @resultBuilder struct ConstraintBuilder {
        static func buildBlock(_ components: NSLayoutConstraint...) -> [NSLayoutConstraint] {
            Array(components)
        }
        static func buildBlock(_ components: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
            Array(components)
        }
    }
    class func add(@ConstraintBuilder constraints: () -> [NSLayoutConstraint]) {
        activate(constraints())
    }
}

extension UIView {
    
    func applyConstraints(@NSLayoutConstraint.ConstraintBuilder constraints: () -> [NSLayoutConstraint]) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.add(constraints: constraints)
    }
    
    func withSuperview(_ handler: (UIView) -> Void) {
        guard let superview = superview else {
            print("No superview to constraint to")
            return
        }
        handler(superview)
    }
    
    func extend(to view: UIView) {
        applyConstraints {
            leadingAnchor.constraint(equalTo: view.leadingAnchor)
            trailingAnchor.constraint(equalTo: view.trailingAnchor)
            topAnchor.constraint(equalTo: view.topAnchor)
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        }
    }
    
    func extend(to layoutGuide: UILayoutGuide) {
        applyConstraints {
            leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor)
            trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor)
            topAnchor.constraint(equalTo: layoutGuide.topAnchor)
            bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
        }
    }
    
    func center(in view: UIView) {
        applyConstraints {
            centerXAnchor.constraint(equalTo: view.centerXAnchor)
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        }
    }
    
    func extendToSuperview() {
        withSuperview { superview in
            extend(to: superview)
        }
    }
    
    
    func extendToSuperviewSafeArea() {
        withSuperview { superview in
            extend(to: superview.safeAreaLayoutGuide)
        }
    }
    
    func centerInSuperview() {
        withSuperview { superview in
            center(in: superview)
        }
    }
}
