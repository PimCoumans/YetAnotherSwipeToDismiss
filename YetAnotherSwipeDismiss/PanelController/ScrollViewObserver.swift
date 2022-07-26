//
//  ScrollViewObserver.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 26/07/2022.
//

import UIKit

class ScrollViewObserver {
    var scrollView: UIScrollView? { didSet {
        updateObservers()
    }}
    
    var didUpdate: ((UIScrollView) -> Void)?
    
    private var scrollContentSizeObserver: NSKeyValueObservation?
    private var scrollFrameObserver: NSKeyValueObservation?
    private var scrollContentOffsetObserver: NSKeyValueObservation?
}

private extension ScrollViewObserver {
    func updateObservers() {
        scrollContentSizeObserver = scrollView?.observe(\.contentSize, options: [.old, .new]) { [weak self] scrollView, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.didUpdate?(scrollView)
        }
        
        scrollFrameObserver = scrollView?.observe(\.frame, options: [.old, .new]) { [weak self] scrollView, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.didUpdate?(scrollView)
        }
        
        scrollContentOffsetObserver = scrollView?.observe(\.contentOffset, options: [.old, .new]) { [weak self] scrollView, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.didUpdate?(scrollView)
        }
    }
}
