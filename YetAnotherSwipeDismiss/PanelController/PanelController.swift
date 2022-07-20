//
//  DismissController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit

protocol PanelPresentable: UIViewController {
    var panelController: PanelController { get }
    var panelScrollView: UIScrollView { get }
}

extension PanelPresentable {
    var panelScrollView: UIScrollView { panelController.scrollView }
    
    var contentView: UIView { panelController.contentView }
    var headerContentView: UIView { panelController.headerContentView }
}

class PanelController: NSObject {
    
    weak var viewController: PanelPresentable? { didSet {
        setupViewController()
    }}
    
    var dimOpactity: CGFloat = 0.45 { didSet {
        dimmingView.backgroundColor = UIColor(white: 0, alpha: dimOpactity)
    }}
    
    var topShadowOpactity: CGFloat = 0.15 { didSet {
        topShadowView.backgroundColor = UIColor(white: 0, alpha: topShadowOpactity)
    }}
    
    let backgroundTopInset: CGFloat = 65
    let topShadowHeight: CGFloat = 3
    var backgroundTopConstraint: NSLayoutConstraint?
    
    let showColors: Bool = false
    
    private class PanelScrollView: UIScrollView { }
    private class PanelContrainerView: UIView { }
    private class PanelDimmingView: UIView { }
    private class PanelHeaderContentView: UIView { }
    private class PanelTopShadowView: UIView { }
    private class PanelBackgroundView: UIView { }
    
    private var viewObserver: NSKeyValueObservation?
    private var needsLayoutObserver: NSKeyValueObservation?
    
    private var scrollContentSizeObserver: NSKeyValueObservation?
    private var scrollFrameObserver: NSKeyValueObservation?
    private var scrollContentOffsetObserver: NSKeyValueObservation?
    
    
    private(set) lazy var containerView: UIView = PanelContrainerView()
    
    private var isScrollViewCustom: Bool {
        viewControllerScrollView is PanelScrollView == false
    }
    
    var contentView: UIView {
        scrollContentView
    }
    
    var headerContentView: UIView {
        headerView
    }
    
    var scrollView: UIScrollView {
        panelScrollView
    }
    
    private var viewControllerScrollView: UIScrollView {
        viewController?.panelScrollView ?? panelScrollView
    }
    
    func layoutIfNeeded() {
        viewController?.view.layoutIfNeeded()
        backgroundView.superview?.layoutIfNeeded()
    }
    
    private var startedGestureFromTopView: Bool = false
    private var dismissGestureVelocity: CGFloat = 0
    private var viewsToTranslate: [UIView] { [scrollView, backgroundView, headerView, topShadowView] }
    
    private lazy var dismissPanGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGestureRecognizer(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var dismissTapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDismissTapGestureRecognizer(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var scrollContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if showColors {
            view.backgroundColor = .black.withAlphaComponent(0.2)
        }
        return view
    }()
    
    private lazy var panelScrollView: UIScrollView = {
        let scrollView = PanelScrollView()
        scrollView.alwaysBounceVertical = true
        if showColors {
            scrollView.backgroundColor = .green.withAlphaComponent(0.2)
        }
        return scrollView
    }()
    
    private lazy var dimmingView: UIView = {
        let view = PanelDimmingView()
        view.backgroundColor = .black.withAlphaComponent(dimOpactity)
        return view
    }()
    
    private lazy var headerView: UIView = {
        let view = PanelHeaderContentView()
        
        view.translatesAutoresizingMaskIntoConstraints = false
        view.directionalLayoutMargins.leading = backgroundTopInset * 0.4
        view.directionalLayoutMargins.trailing = backgroundTopInset * 0.4
        
        if showColors {
            view.backgroundColor = .blue.withAlphaComponent(0.2)
        }
        return view
    }()
    
    private(set) lazy var topShadowView: UIView = {
        let view = PanelTopShadowView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        if showColors {
            view.backgroundColor = .red
        } else {
            view.backgroundColor = .black.withAlphaComponent(topShadowOpactity)
        }
        view.alpha = 0
        return view
    }()
    
    private(set) lazy var backgroundView: UIView = {
        let view = PanelBackgroundView(frame: .zero)
        view.backgroundColor = .white
        
        let cornerRadius = backgroundTopInset / 2
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        view.contentMode = .redraw
        return view
    }()
    
    override init() {
        super.init()
        
        setupViews()
    }
}

private extension PanelController {
    
    func ensureViewHierarchy() {
        guard containerView.superview == nil, let panelPresentable = viewController else {
            return
        }
        let viewController = panelPresentable as UIViewController
        if viewController.isViewLoaded == true {
            setupViewControllerView()
        } else if viewObserver != nil {
            viewObserver = viewController.observe(\.view, options: [.new], changeHandler: { viewController, change in
                self.ensureViewHierarchy()
                self.viewObserver = nil
            })
        }
    }
    
    func setupViews() {
        containerView.layoutMargins.top = backgroundTopInset
        
        scrollView.addSubview(scrollContentView)
        
        containerView.addSubview(scrollView)
        containerView.addSubview(headerView)
        containerView.addSubview(topShadowView)
    }
    
    func updateScrollViewInsets() {
        let scrollView = viewControllerScrollView
        // Set top inset so content is aligned to bottom
        let availableArea = scrollView.frame.inset(by: scrollView.safeAreaInsets).size
        scrollView.contentInset.top = max(0, availableArea.height - scrollView.contentSize.height)
        
        let relativeScrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        
        backgroundTopConstraint?.constant = scrollView.contentInset.top - relativeScrollOffset
        
        // Make top of scroll indicator never extend beyond top of content
        let topScrollOvershoot = min(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: scrollView.adjustedContentInset.top - topScrollOvershoot,
            left: 0,
            bottom: scrollView.contentInset.bottom,
            right: 0
        )
        
        let shadowAlpha: CGFloat = scrollView.contentOffset.y > 0 ? 1 : 0
        if topShadowView.alpha != shadowAlpha {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.topShadowView.alpha = shadowAlpha
            }
        }
    }
    
    func setupViewController() {
        viewController?.modalPresentationStyle = .custom
        viewController?.transitioningDelegate = self
        
        ensureViewHierarchy()
    }
    
    func setupViewControllerView() {
        guard let viewController = viewController else {
            return
        }
        if isScrollViewCustom {
            panelScrollView.removeFromSuperview()
            viewControllerScrollView.removeConstraints(viewControllerScrollView.constraints)
            viewController.view.insertSubview(containerView, belowSubview: viewControllerScrollView)
        } else {
            viewController.view.addSubview(containerView)
        }
        
        let scrollView = viewControllerScrollView
        scrollContentSizeObserver = scrollView.observe(\.contentSize, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.updateScrollViewInsets()
        }
        
        scrollFrameObserver = scrollView.observe(\.frame, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.updateScrollViewInsets()
        }
        
        scrollContentOffsetObserver = scrollView.observe(\.contentOffset, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue != change.newValue else {
                return
            }
            self?.updateScrollViewInsets()
        }
        
        setupViewConstraints()
        setupGestureRecognizers()
    }
    
    func setupViewConstraints() {
        containerView.extendToSuperview()
        
        let topHeight = backgroundTopInset
        let scrollView = viewControllerScrollView
        
        scrollView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            $0.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor)
        }
        
        if !isScrollViewCustom {
            scrollContentView.applyConstraints {
                $0.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor)
                $0.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor)
                $0.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
                $0.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
                $0.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
            }
        }
        
        headerView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
            $0.heightAnchor.constraint(equalToConstant: topHeight)
        }
        
        topShadowView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.heightAnchor.constraint(equalToConstant: topShadowHeight)
            $0.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        }
        updateScrollViewInsets()
    }
    
    func setupBackgroundViews(in containerView: UIView) {
        containerView.addSubview(dimmingView)
        containerView.addSubview(backgroundView)
    }
    
    func setupBackgroundViewConstraints() {
        dimmingView.extendToSuperview()
        
        let topInset = backgroundTopInset
        let scrollView = viewControllerScrollView
        
        
        backgroundView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.topAnchor.constraint(greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor)

            $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 300) // allow for initial bounce animation
        }
        
        backgroundTopConstraint = backgroundView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: topInset)
        backgroundTopConstraint?.priority = .defaultLow
        backgroundTopConstraint?.isActive = true
        
        headerView.applyConstraints {
            $0.topAnchor.constraint(equalTo: backgroundView.topAnchor)
        }
        updateScrollViewInsets()
    }
    
    func setupGestureRecognizers() {
        containerView.addGestureRecognizer(viewControllerScrollView.panGestureRecognizer)
        containerView.addGestureRecognizer(dismissTapGestureRecognizer)
        containerView.addGestureRecognizer(dismissPanGestureRecognizer)
    }
}

extension PanelController: UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    private func isGestureRecognizer(_ recognizer: UIGestureRecognizer, inView view: UIView) -> Bool {
        view.point(inside: recognizer.location(in: view), with: nil)
    }
    
    private var isScrollViewAtTop: Bool {
        scrollView.contentOffset.y + scrollView.adjustedContentInset.top < UIScreen.main.scale
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if isGestureRecognizer(gestureRecognizer, inView: headerView) {
            return false
        }
        return otherGestureRecognizer == scrollView.panGestureRecognizer
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let gestureInContent = isGestureRecognizer(gestureRecognizer, inView: scrollContentView)
        let gestureInTopView = isGestureRecognizer(gestureRecognizer, inView: headerView)
        
        if gestureRecognizer == dismissTapGestureRecognizer {
            return !gestureInContent && !gestureInTopView
        } else if gestureRecognizer == dismissPanGestureRecognizer {
            if gestureInTopView {
                startedGestureFromTopView = true
                return true
            }
            if gestureInContent {
                return isScrollViewAtTop
            }
        }
        
        return true
    }
    
    @objc func handleDismissTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
        animateDismissal(velocity: 0)
    }
    
    @objc func handleDismissGestureRecognizer(recognizer: UIPanGestureRecognizer) {
        
        if recognizer.state == .began {
            // Manually set translation when catching scrollview content while bouncing down
            let scrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            if scrollOffset < 0 {
                let translation = recognizer.translation(in: scrollContentView).y
                recognizer.setTranslation(CGPoint(x: 0, y: translation - scrollOffset), in: scrollContentView)
                scrollView.stopScrolling()
            }
        }
        
        let velocity = recognizer.velocity(in: containerView).y
        let offset = recognizer.translation(in: containerView).y
        
        // Only allow gesturing up when starting drag in top view
        var translation = startedGestureFromTopView ? offset : max(0, offset)
        if translation < 0 {
            // TODO: Proper rubber banding
            translation *= 0.5
        }
        
        let transform = CGAffineTransform(translationX: 0, y: translation)
        
        if recognizer.state == .ended {
            startedGestureFromTopView = false
            
            if velocity > 0 && offset > 0 {
                animateDismissal(velocity: velocity)
            } else {
                scrollView.bounces = true
                UIView.animate(
                    withDuration: 0.6, delay: 0,
                    usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
                    options: [.beginFromCurrentState, .allowUserInteraction]
                ) {
                    self.viewsToTranslate.forEach { $0.transform = .identity }
                }
            }
        } else {
            viewsToTranslate.forEach { $0.transform = transform }
            scrollView.bounces = offset <= 0 || startedGestureFromTopView
        }
    }
}

private extension PanelController {
    func animateDismissal(velocity: CGFloat = 0) {
        dismissGestureVelocity = velocity
        viewController?.presentingViewController?.dismiss(animated: true)
    }
}

extension PanelController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension PanelController: UIViewControllerAnimatedTransitioning {
    
    func isPresenting(using context: UIViewControllerContextTransitioning?) -> Bool {
        context?.viewController(forKey: .to)?.isBeingPresented == true
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isPresenting(using: transitionContext) {
            return 0.62
        } else {
            return 0.38
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let isPresenting = isPresenting(using: transitionContext)
        
        if isPresenting {
            setupBackgroundViews(in: transitionContext.containerView)
        }
        
        if let toView = transitionContext.view(forKey: .to) {
            transitionContext.containerView.addSubview(toView)
            toView.setNeedsLayout()
            toView.layoutIfNeeded()
            ensureViewHierarchy()
        }
        
        if isPresenting {
            setupBackgroundViewConstraints()
        }
        
        let fullOffset = scrollContentView.bounds.height + backgroundTopInset + containerView.safeAreaInsets.bottom
        let transform = CGAffineTransform(translationX: 0, y: fullOffset)
        let fullDuration = transitionDuration(using: transitionContext)
        let duration = max(0.15, fullDuration * ((fullOffset / containerView.bounds.height) * 0.75))
        
        
        if isPresenting {
            dimmingView.alpha = 0
            viewsToTranslate.forEach { $0.transform = transform }
            
            UIView.animate(withDuration: fullDuration * 0.35, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.dimmingView.alpha = 1
            }
            
            UIView.animate(
                withDuration: fullDuration, delay: 0,
                usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
                options: .allowUserInteraction
            ) {
                self.dimmingView.alpha = 1
                self.viewsToTranslate.forEach { $0.transform = .identity }
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            let options: UIView.AnimationOptions = dismissGestureVelocity > 5 ? .curveLinear : .curveEaseIn
            let untransformedOffset = scrollView.frame.applying(scrollView.transform.inverted()).minY
            let transformedOffset = scrollView.frame.minY
            let distanceToCover = fullOffset - (transformedOffset - untransformedOffset)
            let dismissDuration = min(duration, distanceToCover / dismissGestureVelocity)
            
            UIView.animate(withDuration: dismissDuration, delay: 0, options: options) {
                self.dimmingView.alpha = 0
                self.viewsToTranslate.forEach { $0.transform = transform }
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
}
