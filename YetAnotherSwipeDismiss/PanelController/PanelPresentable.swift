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
///         // Add views to `contentView` (from `PanelPresentable`)
///         // or to `panelController.contentView` so they‘re added
///         // to the scrollView
///         let someView = UIView()
///         contentView.addSubview(someView)
///
///         // .. set auto layout constraints
///     }
/// }

protocol PanelPresentable: UIViewController {
	var panelController: PanelController { get }
	var panelScrollView: UIScrollView { get }
	var panelTopInset: CGFloat { get }
}

extension PanelPresentable {
	var panelScrollView: UIScrollView { panelController.panelScrollView }
	var panelTopInset: CGFloat { 10 }
	
	var contentView: UIView { panelController.contentView }
	var headerContentView: UIView { panelController.headerContentView }
}
