import UIKit

class PanelController: NSObject {
	
	weak var viewController: PanelPresentable? { didSet {
		setupViewController()
	}}
	
	var dimOpactity: CGFloat = 0.45 { didSet {
		dimmingView.backgroundColor = UIColor(white: 0, alpha: dimOpactity)
	}}
	
	var headerShadowOpactity: CGFloat = 0.15 { didSet {
		headerShadowView.backgroundColor = UIColor(white: 0, alpha: headerShadowOpactity)
	}}
	
	var contentView: UIView {
		scrollContentView
	}
	
	var headerContentView: UIView {
		headerView
	}
	
	/// Default scrollView used to display contents
	private(set) lazy var panelScrollView: PanelScrollView = {
		let scrollView = PanelScrollView()
		scrollView.alwaysBounceVertical = true
		scrollView.canCancelContentTouches = true
		scrollView.panGestureRecognizer.cancelsTouchesInView = true
		scrollViewObserver.scrollView = scrollView
		return scrollView
	}()
	
	/// Call this method from a UIView animation to animate height changes
	func layoutIfNeeded() {
		viewController?.view.layoutIfNeeded()
		backgroundView.superview?.layoutIfNeeded()
	}
	
	/// Height of view placed above scrollView
	private let headerViewHeight: CGFloat = 65
	private let headerShadowHeight: CGFloat = 2
	/// Extend scrollView height allowing for views bouncing up
	private let bottomBounceAllowance: CGFloat = 100
	/// Inset
	private var backgroundTopConstraint: NSLayoutConstraint?
	/// multiplier to use for transform when bouncing back after pulling down
	private var bounceBackScrollViewMultiplier: CGFloat?
	
	private var viewObserver: NSKeyValueObservation?
	private var scrollViewObserver = ScrollViewObserver()
	
	private var isScrollViewCustom: Bool {
		scrollView is PanelScrollView == false
	}
	
	private var scrollView: UIScrollView {
		viewController?.panelScrollView ?? panelScrollView
	}
	
	private var startedGestureInHeaderView: Bool = false
	private var dismissGestureVelocity: CGFloat = 0
	
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
	
	private lazy var containerView: UIView = PanelContrainerView()
	
	private lazy var scrollContentView: UIView = {
		let view = PanelScrollContentView()
		view.translatesAutoresizingMaskIntoConstraints = false
		return view
	}()
	
	private lazy var dimmingView: UIView = {
		let view = PanelDimmingView()
		view.backgroundColor = .black.withAlphaComponent(dimOpactity)
		return view
	}()
	
	private lazy var headerView: UIView = {
		let view = PanelHeaderContentView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.directionalLayoutMargins.leading = headerViewHeight * 0.4
		view.directionalLayoutMargins.trailing = headerViewHeight * 0.4
		return view
	}()
	
	private(set) lazy var headerShadowView: UIView = {
		let view = PanelHeaderShadowView()
		view.isUserInteractionEnabled = false
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .black.withAlphaComponent(headerShadowOpactity)
		view.alpha = 0
		return view
	}()
	
	private(set) lazy var backgroundView: UIView = {
		let view = PanelBackgroundView(effect: UIBlurEffect(style: .regular))
		
		let cornerRadius = headerViewHeight / 2
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
		scrollViewObserver.didUpdate = { [weak self] scrollView in
			self?.updateScrollView(scrollView)
		}
	}
}

// MARK: Custom class names (mostly for view inspection)
extension PanelController {
	private class PanelContrainerView: UIView { }
	private class PanelDimmingView: UIView { }
	private class PanelScrollContentView: UIView { }
	private class PanelHeaderContentView: UIView { }
	private class PanelHeaderShadowView: UIView { }
	private class PanelBackgroundView: UIVisualEffectView { }
}

// MARK: - Setting up view controller
private extension PanelController {
	
	func setupViewController() {
		viewController?.modalPresentationStyle = .custom
		viewController?.transitioningDelegate = self
		
		ensureViewHierarchy()
	}
	
	/// Makes sure containerView is added to the view hierarchy
	func ensureViewHierarchy() {
		guard containerView.superview == nil, let panelPresentable = viewController else {
			return
		}
		let viewController = panelPresentable as UIViewController
		if viewController.isViewLoaded == true {
			setupViewControllerView()
		} else if viewObserver != nil {
			// Wait for `viewController.view` to be loaded
			viewObserver = viewController.observe(\.view, options: [.new], changeHandler: { viewController, change in
				self.ensureViewHierarchy()
				self.viewObserver = nil
			})
		}
	}
	
	func setupViewControllerView() {
		guard let viewController = viewController else {
			return
		}
		if isScrollViewCustom {
			panelScrollView.removeFromSuperview()
			prepareCustomScrollView(scrollView)
			viewController.view.insertSubview(containerView, belowSubview: scrollView)
			containerView.insertSubview(scrollView, at: 0)
		} else {
			viewController.view.addSubview(containerView)
		}
		
		setupViewConstraints()
		setupGestureRecognizers()
	}
	
	func prepareCustomScrollView(_ scrollView: UIScrollView) {
		scrollView.removeConstraints(scrollView.constraints)
		if let constraintsToRemove = scrollView.superview?
			.constraints
			.filter({ ($0.firstItem as? UIScrollView) == scrollView })
		{
			scrollView.superview?.removeConstraints(constraintsToRemove)
		}
		scrollView.backgroundColor = .clear
		scrollView.alwaysBounceVertical = true
		scrollView.canCancelContentTouches = true
		scrollView.panGestureRecognizer.cancelsTouchesInView = true
		scrollViewObserver.scrollView = scrollView
	}
}

// MARK: - View setup
private extension PanelController {
	
	func setupViews() {
		containerView.layoutMargins.top = headerViewHeight
		
		scrollView.addSubview(scrollContentView)
		
		containerView.addSubview(scrollView)
		containerView.addSubview(headerView)
		containerView.addSubview(headerShadowView)
	}
	
	func setupViewConstraints() {
		containerView.extendToSuperview()
		
		let topHeight = headerViewHeight
		
		scrollView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
			$0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottomBounceAllowance)
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
		
		headerShadowView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
			$0.heightAnchor.constraint(equalToConstant: headerShadowHeight)
			$0.topAnchor.constraint(equalTo: headerView.bottomAnchor)
		}
		updateScrollView(scrollView)
	}
	
	func setupBackgroundViews(in containerView: UIView) {
		containerView.addSubview(dimmingView)
		containerView.addSubview(backgroundView)
	}
	
	func setupBackgroundViewConstraints() {
		dimmingView.extendToSuperview()
		
		let topInset = headerViewHeight
		
		// Align to bottom of screen when possible
		let bottomAnchor = viewController?.view.bottomAnchor ?? containerView.bottomAnchor
		// Align to scrollView‘s top inset. Constraint will be updated when scrollView updates
		backgroundTopConstraint = backgroundView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: topInset)
		backgroundTopConstraint?.priority = .defaultLow
		
		backgroundView.applyConstraints {
			$0.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
			$0.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
			$0.topAnchor.constraint(greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor)
			
			$0.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottomBounceAllowance)
			backgroundTopConstraint!
		}
		
		headerView.applyConstraints {
			$0.topAnchor.constraint(equalTo: backgroundView.topAnchor)
		}
		updateScrollView(scrollView)
	}
	
	func setupGestureRecognizers() {
		containerView.addGestureRecognizer(scrollView.panGestureRecognizer)
		containerView.addGestureRecognizer(dismissTapGestureRecognizer)
		containerView.addGestureRecognizer(dismissPanGestureRecognizer)
	}
}

// MARK: - UIScrollView handling
private extension PanelController {
	
	/// Called whenever any layout properties of `scrollView` changes
	func updateScrollView(_ scrollView: UIScrollView) {
		// ScrollView‘s bottom extends by `bottomBounceAllowance`
		scrollView.contentInset.bottom = bottomBounceAllowance
		let scrollViewHeight = scrollView.frame.inset(by: scrollView.safeAreaInsets).height - bottomBounceAllowance
		let contentHeight = scrollView.contentSize.height
		// Set top inset so content is always aligned to bottom
		scrollView.contentInset.top = max(0, scrollViewHeight - contentHeight)
		
		let scrollOffset = scrollView.relativeContentOffset.y
		
		if let transformMultiplier = bounceBackScrollViewMultiplier {
			// When bouncing back from being dragged down, reset the transform as scrollview bounces back up
			if scrollOffset >= 0 {
				translateViews(withOffset: nil)
				bounceBackScrollViewMultiplier = nil
			} else {
				let multipliedOffset = -scrollOffset * transformMultiplier
				translateViews(withOffset: multipliedOffset)
			}
		}
		
		backgroundTopConstraint?.constant = scrollView.contentInset.top - scrollOffset
		
		// Make top of scroll indicator never extend beyond top of content
		let topScrollOvershoot = min(0, scrollOffset)
		scrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
			top: max(0, scrollView.adjustedContentInset.top - topScrollOvershoot) + headerShadowHeight,
			left: 0,
			bottom: scrollView.contentInset.bottom,
			right: 0
		)
		
		// Show or hide shadowView based on content offset
		let shadowAlpha: CGFloat = scrollView.contentOffset.y > 0 ? 1 : 0
		if headerShadowView.alpha != shadowAlpha {
			UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
				self.headerShadowView.alpha = shadowAlpha
			}
		}
	}
}

// MARK: - Handling gesture recognizers
extension PanelController: UIGestureRecognizerDelegate {
	
	private func isGestureRecognizer(_ recognizer: UIGestureRecognizer, inView view: UIView) -> Bool {
		view.point(inside: recognizer.location(in: view), with: nil)
	}
	
	private func isGestureRecognizerInScrollContent(_ recognizer: UIGestureRecognizer) -> Bool {
		if isScrollViewCustom {
			let point = recognizer.location(in: scrollView)
			return scrollView.isPointInScrollContent(point)
		} else {
			return isGestureRecognizer(recognizer, inView: scrollContentView)
		}
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if isGestureRecognizer(gestureRecognizer, inView: headerView) && scrollView.contentExeedsBounds {
			// Draggin from headerView should not allow scrolling when content can actually scroll
			return false
		}
		return otherGestureRecognizer == scrollView.panGestureRecognizer
	}
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Set initial state
		startedGestureInHeaderView = false
		
		let isGestureInContent = isGestureRecognizerInScrollContent(gestureRecognizer)
		let isGestureInHeaderView = isGestureRecognizer(gestureRecognizer, inView: headerView)
		
		if gestureRecognizer == dismissTapGestureRecognizer {
			// Allow dismiss taps outside panel
			return !isGestureInContent && !isGestureInHeaderView
		} else if gestureRecognizer == dismissPanGestureRecognizer {
			if isGestureInHeaderView {
				// Always allow drags from headerView
				startedGestureInHeaderView = true
				return true
			}
			if isGestureInContent {
				// Drag along with scrollView when content is at top or panel content shouldn‘t scroll
				return scrollView.isAtTop || !scrollView.contentExeedsBounds
			}
		}
		
		return true
	}
	
	@objc func handleDismissTapGestureRecognizer(recognizer: UITapGestureRecognizer) {
		animateDismissal(velocity: 0)
	}
	
	@objc func handleDismissGestureRecognizer(recognizer: UIPanGestureRecognizer) {
		if recognizer.state == .began {
			// Manually set translation when catching the scrollView‘s content while it‘s bouncing down
			let scrollOffset = scrollView.relativeContentOffset.y
			if scrollOffset < 0 {
				let translation = recognizer.translation(in: containerView).y
				recognizer.setTranslation(CGPoint(x: 0, y: translation - scrollOffset), in: containerView)
				scrollView.stopVerticalScrolling()
			}
		}
		
		let velocity = recognizer.velocity(in: containerView).y
		let offset = recognizer.translation(in: containerView).y
		
		let endStates: [UIGestureRecognizer.State] = [.cancelled, .failed, .ended]
		let recognizerEnded = endStates.contains(recognizer.state)
		
		let canDragWithScrollViewBounce = !scrollView.contentExeedsBounds || !startedGestureInHeaderView
		
		if recognizerEnded {
			scrollView.bounces = true
			if recognizer.state == .ended && velocity > 0 && offset > 0 {
				scrollView.showsVerticalScrollIndicator = false
				animateDismissal(velocity: velocity)
			} else if let transformedOffset = currentViewTranslation, transformedOffset != 0 {
				if !scrollView.contentExeedsBounds {
					// Bounce back along with scrollView (see `updateScrollView(_:)` for more)
					let multiplier = transformedOffset / -scrollView.relativeContentOffset.y
					bounceBackScrollViewMultiplier = multiplier
					return
				} else {
					// Animate back with manual spring bouncing, resetting scrollView offset
					let overshoot = max(0, -scrollView.relativeContentOffset.y)
					let springVelocity = velocity / -(transformedOffset + overshoot)
					scrollView.stopVerticalScrolling()
					
					// Add the scrollView‘s original offset to the transform
					translateViews(withOffsetTransformer: { $0 + overshoot })
					
					// Bounce back the views
					UIView.animate(
						withDuration: 0.6, delay: 0,
						usingSpringWithDamping: 0.94, initialSpringVelocity: springVelocity,
						options: [.beginFromCurrentState, .allowUserInteraction]
					) {
						self.translateViews(withOffset: nil)
					}
				}
			}
		} else {
			var translation = max(0, offset)
			if canDragWithScrollViewBounce {
				translation += min(0, scrollView.relativeContentOffset.y)
			}
			translateViews(withOffset: translation)
			scrollView.bounces = canDragWithScrollViewBounce
		}
	}
}

// MARK: - Setting view offset transforms
private extension PanelController {
	/// Views that should move when translating along with dismiss gesture or scrollView bounce
	var viewsToTranslate: [UIView] { [containerView, backgroundView] }
	
	var currentViewTranslation: CGFloat? {
		viewsToTranslate.first?.transform.ty
	}
	
	func translateViews(withOffsetTransformer transformer: (CGFloat) -> CGFloat?) {
		viewsToTranslate.forEach {
			let offset = transformer($0.transform.ty) ?? 0
			$0.transform = CGAffineTransform(translationX: 0, y: offset)
		}
	}
	
	func translateViews(withOffset offset: CGFloat?) {
		let transform = offset.map { CGAffineTransform(translationX: 0, y: $0) } ?? .identity
		viewsToTranslate.forEach {
			$0.transform = transform
		}
	}
}

// MARK: - Animate presentation and dismissal
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
			ensureViewHierarchy()
			toView.setNeedsLayout()
			toView.layoutIfNeeded()
		}
		
		if isPresenting {
			setupBackgroundViewConstraints()
		}
		
		let fullOffset = scrollView.contentSize.height + headerViewHeight + containerView.safeAreaInsets.bottom
		let fullDuration = transitionDuration(using: transitionContext)
		let duration = max(0.15, fullDuration * ((fullOffset / containerView.bounds.height) * 0.75))
		
		if isPresenting {
			dimmingView.alpha = 0
			translateViews(withOffset: fullOffset)
			
			UIView.animate(withDuration: fullDuration * 0.35, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
				self.dimmingView.alpha = 1
			}
			
			UIView.animate(
				withDuration: fullDuration, delay: 0,
				usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
				options: .allowUserInteraction
			) {
				self.dimmingView.alpha = 1
				self.translateViews(withOffset: nil)
			} completion: { finished in
				transitionContext.completeTransition(finished)
			}
		} else {
			let options: UIView.AnimationOptions = dismissGestureVelocity > 5 ? .curveLinear : .curveEaseIn
			let untransformedOffset = containerView.frame.applying(containerView.transform.inverted()).minY
			let transformedOffset = containerView.frame.minY
			let distanceToCover = fullOffset - (transformedOffset - untransformedOffset)
			let dismissDuration = min(duration, distanceToCover / dismissGestureVelocity)
			
			UIView.animate(withDuration: dismissDuration, delay: 0, options: options) {
				self.dimmingView.alpha = 0
				self.translateViews(withOffset: fullOffset)
			} completion: { finished in
				transitionContext.completeTransition(finished)
			}
		}
	}
}
