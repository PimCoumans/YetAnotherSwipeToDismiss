//
//  DismissViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 08/07/2022.
//

import UIKit

class DismissViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let dimOpactity: CGFloat = 0.35
    let backgroundTopInset: CGFloat = 65
    
    class DimmingView: UIView { }
    class TopView: UIView { }
    class BackgroundView: UIView { }
    
    var contentView: UIView { scrollView.contentView }
    
    private var startedGestureFromTopView: Bool = false
    private var dismissGestureVelocity: CGFloat = 0
    
    private var viewsToTranslate: [UIView] { [scrollView, backgroundView, topView] }
    
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
    
    private lazy var scrollView: BottomAlignedScrollView = {
        let scrollView = BottomAlignedScrollView(frame: self.view.bounds)
        scrollView.extraTopInset = backgroundTopInset
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        return scrollView
    }()
    
    private lazy var dimmingView: UIView = {
        let view = DimmingView(frame: self.view.bounds)
        view.backgroundColor = .black.withAlphaComponent(dimOpactity)
        return view
    }()
    
    private lazy var topView: UIView = {
        let view = TopView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = backgroundTopInset / 2
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        view.contentMode = .redraw
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = BackgroundView(frame: .zero)
        view.backgroundColor = .systemGray
        return view
    }()
    
    private lazy var dummyContent: UILabel = {
        let label = UILabel()
        label.contentMode = .top
        label.font = UIFont.systemFont(ofSize: 237)
        label.text = "1 2 3 4 5 6 7"
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        label.isUserInteractionEnabled = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        view.addSubview(dimmingView)
        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        view.addSubview(topView)
        
        contentView.addSubview(dummyContent)
        setupLayoutConstraints()
        setupGestureRecognizers()
    }
    
    private func setupLayoutConstraints() {
        dimmingView.extendToSuperview()
        dummyContent.extendToSuperviewSafeArea()
        
        scrollView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: backgroundTopInset)
            $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        }
        
        topView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            $0.heightAnchor.constraint(equalToConstant: backgroundTopInset)
            $0.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor)
            
            $0.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor)
        }
        
        backgroundView.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            $0.topAnchor.constraint(equalTo: topView.bottomAnchor)
            $0.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.bounds.height) // allow for initial bounce animation
        }
    }
    
    private func setupGestureRecognizers() {
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        view.addGestureRecognizer(dismissTapGestureRecognizer)
        view.addGestureRecognizer(dismissPanGestureRecognizer)
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0, options: []) {
            self.dummyContent.font = UIFont.systemFont(ofSize: self.randomFontSize)
            self.view.layoutIfNeeded()
        }
    }
}

extension DismissViewController: UIScrollViewDelegate, UIGestureRecognizerDelegate {
    
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
        if gestureRecognizer == dismissTapGestureRecognizer {
            return !isGestureRecognizer(gestureRecognizer, inView: contentView) && !isGestureRecognizer(gestureRecognizer, inView: topView)
        }
        
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let isSwipingDown = panGestureRecognizer.velocity(in: view).y > 0
        if isGestureRecognizer(gestureRecognizer, inView: topView) {
            startedGestureFromTopView = true
            return true
        }
        if isGestureRecognizer(gestureRecognizer, inView: contentView) {
            if isScrollViewAtTop && isSwipingDown {
                return true
            }
            return false
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
                let translation = recognizer.translation(in: contentView).y
                recognizer.setTranslation(CGPoint(x: 0, y: translation - scrollOffset), in: contentView)
                scrollView.stopScrolling()
            }
        }
        
        let velocity = recognizer.velocity(in: view).y
        let offset = recognizer.translation(in: view).y
        
        // Only allow gesturing up when starting drag in top view
        var translation = startedGestureFromTopView ? offset : max(0, offset)
        if translation < 0 {
            // TODO: Proper rubber banding
            translation *= 0.5
        }
        
        let transform = CGAffineTransform(translationX: 0, y: translation)
        
        if recognizer.state == .ended {
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
        // ...
    }
}

private extension DismissViewController {
    @objc func animateDismissal(velocity: CGFloat = 0) {
        dismissGestureVelocity = velocity
        presentingViewController?.dismiss(animated: true)
    }
}

private extension DismissViewController {
    var randomFontSize: CGFloat { .random(in: 20...250) }
}

extension DismissViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}

extension DismissViewController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if isBeingPresented {
            return 0.62
        } else {
            return 0.38
        }
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let toView = transitionContext.view(forKey: .to) {
            transitionContext.containerView.addSubview(toView)
        }
        
        let fullOffset = contentView.bounds.height + backgroundTopInset + view.safeAreaInsets.bottom
        let transform = CGAffineTransform(translationX: 0, y: fullOffset)
        let fullDuration = transitionDuration(using: transitionContext)
        let duration = max(0.15, fullDuration * ((fullOffset / view.bounds.height) * 0.75))
        
        
        if isBeingPresented {
            dimmingView.alpha = 0
            viewsToTranslate.forEach { $0.transform = transform }
            
            UIView.animate(withDuration: fullDuration * 0.35, delay: 0, options: .curveEaseOut) {
                self.dimmingView.alpha = 1
            }
            UIView.animate(withDuration: fullDuration, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0) {
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
