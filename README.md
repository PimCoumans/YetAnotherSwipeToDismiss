# YetAnotherSwipeToDismiss

Proof of concept of adding swipe-dismiss logic to a view controller, supporting Auto Layout and dynamic height.

<img width="564" alt="image" src="https://user-images.githubusercontent.com/1199454/178160455-00e0d766-f9a1-42c4-bb45-d40f06e87747.png">


## Installation

This isn't proper open-source code, so no package managers are supported yet. Just add the files from the `PanelController` to your project.

To make use of the behavior that `PanelController` provided, make sure your view controller conforms to `PanelPresentable` and set its `viewController` property to `self` in your initializer. If you do this at a later stage, your view controller will not presented in a nice way.

```swift
class SimpleViewController: UIViewController, PanelPresentable {
    
    let panelController = PanelController()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        panelController.viewController = self
    }
}
```

Make sure to add your views to the `contentView` property, which is forwarded to the view is `panelController`'s scroll view. And any navigation-type views can be placed in the `topContentView` which will be displayed above your content and will stick to the top of the screen when scrolling.

```swift
    private lazy var simpleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemMint
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.addAction(UIAction { [unowned self] _ in
            self.presentingViewController?.dismiss(animated: true)
        }, for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .black
        
        contentView.addSubview(simpleView)
        topContentView.addSubview(cancelButton)
        
        simpleView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            simpleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            simpleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            simpleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            simpleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            simpleView.heightAnchor.constraint(equalToConstant: 200),
            
            cancelButton.leadingAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.leadingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: topContentView.layoutMarginsGuide.centerYAnchor)
        ])
    }
```

## Example code

In the repo you‘ll find `SimpleViewController` that does something simular as the code showed above. A more complex example is `StackViewController` where a bunch of random, multiline labels can be added to a `UIStackView`. The height animates whenever the a label is added or removed. In the `animateChanges()` method an example is shown how to animate the height change by wrapping `self.view.layoutIfNeeded()` in an animation closure.

## Questions?

Look me up on [twitter](https://twitter.com/pimcoumans)! ✌🏻
