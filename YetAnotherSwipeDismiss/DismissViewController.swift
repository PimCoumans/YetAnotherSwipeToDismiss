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
    
    let backgroundTopInset: CGFloat = 65
    
    class DimmingView: UIView { }
    class TopView: UIView { }
    
    var contentView: UIView { scrollView.contentView }
    
    private lazy var scrollView: BottomAlignedScrollView = {
        let scrollView = BottomAlignedScrollView(frame: self.view.bounds)
        scrollView.extraTopInset = backgroundTopInset
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        scrollView.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        return scrollView
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
    
    private lazy var dimmingView: UIView = {
        let view = DimmingView(frame: self.view.bounds)
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var dummyContent: UILabel = {
        let label = UILabel()
        label.contentMode = .top
        label.font = UIFont.systemFont(ofSize: 45)
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
        view.addSubview(scrollView)
        view.addSubview(topView)
        
        contentView.addSubview(dummyContent)
        setLayoutConstraints()
    }
    
    private func setLayoutConstraints() {
        dimmingView.extendToSuperview()
        
        NSLayoutConstraint.add {
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: backgroundTopInset)
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            topView.heightAnchor.constraint(equalToConstant: backgroundTopInset)
            topView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor)
            
            topView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor)
        }
        
        dummyContent.extendToSuperviewSafeArea()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateBackgroundView()
    }

    func updateBackgroundView() {
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0, options: []) {
            self.dummyContent.font = UIFont.systemFont(ofSize: CGFloat.random(in: 20...250))
            self.view.layoutIfNeeded()
        }
    }
}

extension DismissViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBackgroundView()
    }
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
        return 1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        transitionContext.containerView.addSubview(toView)
        if isBeingDismissed {
            transitionContext.containerView.sendSubviewToBack(toView)
        }
        
        let fullOffset = contentView.bounds.height + backgroundTopInset
        let transform = CGAffineTransform(translationX: 0, y: fullOffset)
        if isBeingDismissed {
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           options: .curveEaseIn) {
                self.dimmingView.alpha = 0
                self.scrollView.transform = transform
                self.topView.transform = transform
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            scrollView.transform = CGAffineTransform(translationX: 0, y: fullOffset)
            topView.transform = transform
            dimmingView.alpha = 0
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           options: .curveEaseOut) {
                self.dimmingView.alpha = 1
                self.scrollView.transform = .identity
                self.topView.transform = .identity
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
    
}
