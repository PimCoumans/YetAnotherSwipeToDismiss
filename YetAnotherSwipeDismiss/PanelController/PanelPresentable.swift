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
/// }

protocol PanelPresentable: UIViewController {
	var panelController: PanelController { get }
	var panelScrollView: UIScrollView { get }
}

extension PanelPresentable {
	var panelScrollView: UIScrollView { panelController.panelScrollView }
	
	var contentView: UIView { panelController.contentView }
	var headerContentView: UIView { panelController.headerContentView }
}
