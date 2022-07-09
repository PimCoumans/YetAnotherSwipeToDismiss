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
    
    var startedGestureFromTopView: Bool = false
    
    private lazy var dismissGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGestureRecognizer(recognizer:)))
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
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        return view
    }()
    
    private lazy var topView: UIView = {
        let view = TopView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray2
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
        setupScrollBehavior()
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
    
    private func setupScrollBehavior() {
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
        view.addGestureRecognizer(dismissGestureRecognizer)
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
                let scrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
                if scrollOffset < 0 {
                    let translation = panGestureRecognizer.translation(in: contentView).y
                    panGestureRecognizer.setTranslation(CGPoint(x: 0, y: translation - scrollOffset), in: contentView)
                }
                return true
            }
            return false
        }
        return true
    }
    
    @objc func handleDismissGestureRecognizer(recognizer: UIPanGestureRecognizer) {
        let velocity = recognizer.velocity(in: view).y
        let scrollOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let offset = recognizer.translation(in: view).y        
        
        let limitTransform = !startedGestureFromTopView
        var translation = limitTransform ? max(0, offset) : offset
        
        if translation < 0 {
            translation *= 0.5
        }
        
        let transform = CGAffineTransform(translationX: 0, y: translation)
        let translatingViews = [self.scrollView, self.topView, self.backgroundView]
        
        if recognizer.state == .ended {
            if velocity > 0 && offset > 0 {
                dismissSelf()
            } else {
                scrollView.bounces = true
                UIView.animate(
                    withDuration: 0.6, delay: 0,
                    usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
                    options: [.beginFromCurrentState, .allowUserInteraction]
                ) {
                    translatingViews.forEach { $0.transform = .identity }
                }
            }
        } else {
            translatingViews.forEach { $0.transform = transform }
            scrollView.bounces = offset <= 0 || startedGestureFromTopView
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // ...
    }
}

private extension DismissViewController {
    @objc func dismissSelf() {
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
        
        let translatingViews = [self.scrollView, self.topView, self.backgroundView]
        
        if isBeingPresented {
            dimmingView.alpha = 0
            translatingViews.forEach { $0.transform = transform }
            
            UIView.animate(withDuration: fullDuration * 0.35, delay: 0, options: .curveEaseOut) {
                self.dimmingView.alpha = 1
            }
            UIView.animate(withDuration: fullDuration, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0) {
                self.dimmingView.alpha = 1
                translatingViews.forEach { $0.transform = .identity }
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                self.dimmingView.alpha = 0
                translatingViews.forEach { $0.transform = transform }
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
    
}
