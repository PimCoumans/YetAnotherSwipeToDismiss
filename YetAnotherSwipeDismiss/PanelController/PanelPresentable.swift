import UIKit

/// Allows any ViewController to use panel presenting logic
/// Typically just creating a `PanelController` instance and setting its `viewController` property to your view contorller.
///
/// Basic implementation:
/// ```
/// class MyViewController: UIViewController, PanelPresentable {
///
///     let panelController = PanelController()
///
///     init() {
///         super.init(nibName: nil, bundle: nil)
///         panelController.viewController = self
///     }
///
///     func viewDidLoad() {
///         super.viewDidLoad()
///
///         // Your view will be added to `panelController.contentView`
///         // so any constraints sizing your view will size the
///         // panel‘s scrollView
///         let someView = UIView()
///         view.addSubview(someView)
///
///         // .. set auto layout constraints
///     }
/// }

protocol PanelPresentable: UIViewController {
	var panelController: PanelController { get }
	
	/// Override to provide your own scroll view to use for dismissing logic
	var panelScrollView: UIScrollView { get }
	
	/// Set an additional top inset from the screen‘s top
	var panelTopInset: CGFloat { get }
}

extension PanelPresentable {
	var panelScrollView: UIScrollView { panelController.panelScrollView }
	var panelTopInset: CGFloat { 10 }
	
	var headerContentView: UIView { panelController.headerContentView }
}

extension UIViewController {
	var presentingPanelController: PanelController? {
		transitioningDelegate as? PanelController
	}
}
