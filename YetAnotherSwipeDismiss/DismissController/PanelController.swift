//
//  DismissController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 10/07/2022.
//

import UIKit

protocol PanelPresentable: UIViewController {
    var panelController: PanelController { get }
}

extension PanelPresentable {
    var contentView: UIView { panelController.contentView }
    var topContentView: UIView { panelController.topContentView }
    var scrollView: UIScrollView { panelController.scrollView }
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
    let topShadowHeight: CGFloat = 1
    
    class DismissContrainerView: UIView { }
    class DimmingView: UIView { }
    class TopView: UIView { }
    class TopShadowView: UIView { }
    class BackgroundView: UIView { }
    
    private var viewObserver: NSKeyValueObservation?
    
    private(set) lazy var containerView: UIView = DismissContrainerView()
    
    var contentView: UIView {
        ensureViewHierarchy()
        return scrollView.contentView
    }
    
    var topContentView: UIView {
        ensureViewHierarchy()
        return topView
    }
    
    private var startedGestureFromTopView: Bool = false
    private var dismissGestureVelocity: CGFloat = 0
    
    private var scrollContentView: UIView { scrollView.contentView }
    private var viewsToTranslate: [UIView] { [scrollView, backgroundView, topView, topShadowView] }
    
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
    
    private(set) lazy var scrollView: BottomAlignedScrollView = {
        let scrollView = BottomAlignedScrollView()
        scrollView.extraTopInset = backgroundTopInset
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        return scrollView
    }()
    
    private lazy var dimmingView: UIView = {
        let view = DimmingView()
        view.backgroundColor = .black.withAlphaComponent(dimOpactity)
        return view
    }()
    
    private lazy var topView: UIView = {
        let view = TopView()
        let cornerRadius = backgroundTopInset / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.directionalLayoutMargins.leading = cornerRadius * 0.8
        view.directionalLayoutMargins.trailing = cornerRadius * 0.8
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        view.contentMode = .redraw
        return view
    }()
    
    private(set) lazy var topShadowView: UIView = {
        let view = TopShadowView()
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0, alpha: topShadowOpactity)
        view.alpha = 0
        return view
    }()
    
    private(set) lazy var backgroundView: UIView = {
        let view = BackgroundView(frame: .zero)
        view.backgroundColor = .white
        return view
    }()
    
    override init() {
        super.init()
        
        setupViews()
        setupViewConstraints()
        setupGestureRecognizers()
    }
}

private extension PanelController {
    
    func ensureViewHierarchy() {
        guard containerView.superview == nil, let viewController = viewController else {
            return
        }
        if viewController.isViewLoaded == true {
            viewController.view.addSubview(containerView)
            self.containerView.extendToSuperview()
        } else if viewObserver != nil {
            viewObserver = (viewController as UIViewController).observe(\.view, options: [.new], changeHandler: { viewController, change in
                self.ensureViewHierarchy()
                self.viewObserver = nil
            })
        }
    }
    
    func setupViews() {
        containerView.addSubview(dimmingView)
        containerView.addSubview(backgroundView)
        containerView.addSubview(scrollView)
        containerView.addSubview(topShadowView)
        containerView.addSubview(topView)
    }
    
    func setupViewController() {
        viewController?.modalPresentationStyle = .custom
        viewController?.transitioningDelegate = self
        
        ensureViewHierarchy()
    }
    
    func setupViewConstraints() {
        dimmingView.extendToSuperview()
        
        scrollView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: backgroundTopInset)
            $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        }
        
        topView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.heightAnchor.constraint(equalToConstant: backgroundTopInset)
            $0.topAnchor.constraint(greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor)
            
            $0.bottomAnchor.constraint(greaterThanOrEqualTo: scrollContentView.topAnchor)
        }
        
        topShadowView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.heightAnchor.constraint(equalToConstant: topShadowHeight)
            $0.topAnchor.constraint(equalTo: topView.bottomAnchor)
        }
        
        backgroundView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            $0.topAnchor.constraint(equalTo: topView.bottomAnchor)
            $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 300) // allow for initial bounce animation
        }
    }
    
    func setupGestureRecognizers() {
        containerView.addGestureRecognizer(scrollView.panGestureRecognizer)
        containerView.addGestureRecognizer(dismissTapGestureRecognizer)
        containerView.addGestureRecognizer(dismissPanGestureRecognizer)
    }
}

extension PanelController: UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    private func isGestureRecognizer(_ recognizer: UIGestureRecognizer, inView view: UIView) -> Bool {
        view.point(inside: recognizer.location(in: view), with: nil)
    }
    
    private var isScrollViewAtTop: Bool {
        scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if isGestureRecognizer(gestureRecognizer, inView: topView) {
            return false
        }
        return otherGestureRecognizer == scrollView.panGestureRecognizer
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        let gestureInContent = isGestureRecognizer(gestureRecognizer, inView: scrollContentView)
        let gestureInTopView = isGestureRecognizer(gestureRecognizer, inView: topView)
        
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shadowAlpha: CGFloat = scrollView.contentOffset.y > 0 ? 1 : 0
        if topShadowView.alpha != shadowAlpha {
            UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                self.topShadowView.alpha = shadowAlpha
            }
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
        if let toView = transitionContext.view(forKey: .to) {
            transitionContext.containerView.addSubview(toView)
            toView.setNeedsLayout()
            toView.layoutIfNeeded()
        }
        
        let fullOffset = scrollContentView.bounds.height + backgroundTopInset + containerView.safeAreaInsets.bottom
        let transform = CGAffineTransform(translationX: 0, y: fullOffset)
        let fullDuration = transitionDuration(using: transitionContext)
        let duration = max(0.15, fullDuration * ((fullOffset / containerView.bounds.height) * 0.75))
        
        
        if isPresenting(using: transitionContext) {
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
