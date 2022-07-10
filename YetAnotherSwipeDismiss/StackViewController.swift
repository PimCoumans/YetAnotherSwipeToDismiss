//
//  StackViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 09/07/2022.
//

import UIKit

class StackViewController: UIViewController, PanelPresentable {
    
    let panelController = PanelController()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var addButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Add"
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(didPressAddButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var addALotButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Add a lot"
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(didPressAddALotButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var removeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Remove"
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(didPressRemoveButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 20
        return stackView
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        panelController.viewController = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = .black
        
        contentView.addSubview(stackView)
        stackView.extend(to: contentView.layoutMarginsGuide)
        
        topContentView.addSubview(buttonStackView)
        buttonStackView.extend(to: topContentView.layoutMarginsGuide)
        
        buttonStackView.addArrangedSubview(removeButton)
        buttonStackView.addArrangedSubview(addALotButton)
        buttonStackView.addArrangedSubview(addButton)
                
        addLabel(initialAlpha: 1)
    }
}

extension UIFont.Weight: CaseIterable {
    public static var allCases: [UIFont.Weight] {
        [
            .ultraLight,
            .thin,
            .light,
            .regular,
            .medium,
            .semibold,
            .bold,
            .heavy,
            .black
        ]
    }
}

private extension StackViewController {
    
    var randomWord: String {
        [
            "enoy",
            "great",
            "cat",
            "powerful",
            "awesome",
            "dismiss me",
            "auto",
            "layout",
            "what a world",
            "hello",
            "smells like wrongdog in here",
            "i like snacks",
            "so much words",
            "forgot translatesAutoresizingMaskIntoConstraints again",
            "this is pretty nifty",
            "yes, okay, well",
            "can‘t get enough of this"
        ].randomElement()!
    }
    
    var randomFontSize: CGFloat {
        .random(in: 24...64)
    }
    
    var randomFontWeight: UIFont.Weight {
        .allCases.randomElement()!
    }
    
    @objc func didPressAddButton() {
        addLabel()
        animateChanges()
        scrollToLastLabel()
    }
    
    @objc func didPressRemoveButton() {
        let animations = removeLabel()
        animateChanges(with: animations.change, completion: animations.completion)
    }
    
    @objc func didPressAddALotButton() {
        for _ in 0..<5 {
            addLabel()
        }
        animateChanges()
        scrollToLastLabel()
    }
    
    func animateChanges(with animation: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        guard !isBeingPresented && !isBeingDismissed else {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .allowUserInteraction) {
            self.stackView.arrangedSubviews.forEach { if !$0.isHidden { $0.alpha = 1 } }
            animation?()
            self.view.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }
    
    func scrollToLastLabel() {
        if let lastView = stackView.arrangedSubviews.last {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.scrollView.scrollRectToVisible(lastView.frame, animated: true)
            }
        }
    }
    
    func addLabel(initialAlpha: CGFloat = 0) {
        
        let maxViewCount = 40
        
        guard stackView.arrangedSubviews.count <= maxViewCount else {
            return
        }
        
        let label = UILabel()
        let lastRandomWord = (stackView.arrangedSubviews.last as? UILabel)?.text
        var randomWord = lastRandomWord
        
        if stackView.arrangedSubviews.count == maxViewCount {
            randomWord = "let‘s not get carried away"
        }
        
        while randomWord == lastRandomWord {
            randomWord = self.randomWord
        }
        
        label.text = randomWord
        label.numberOfLines = 0
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: randomFontSize, weight: randomFontWeight)
        stackView.addArrangedSubview(label)
        
        // Calculate approximate initial frame to fix in-animation
        label.frame.size = label.sizeThatFits(CGSize(width: stackView.bounds.width, height: .greatestFiniteMagnitude))
        label.frame.origin.y = stackView.bounds.maxY
        label.alpha = initialAlpha
        
        label.applyConstraints {
            $0.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            $0.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        }
        
        removeButton.isEnabled = true
    }
    
    func removeLabel() -> (change: () -> Void, completion: () -> Void) {
        var result = (change: {}, completion: {})
        
        if let label = stackView.arrangedSubviews.last(where: { $0.isHidden == false }) {
            result.change = {
                label.transform = CGAffineTransform(translationX: label.frame.minX, y: label.frame.minY)
                self.stackView.removeArrangedSubview(label)
                label.alpha = 0
            }
            result.completion = {
                label.removeFromSuperview()
            }
        }
        
        if stackView.arrangedSubviews.filter({ $0.isHidden == false }).isEmpty {
            removeButton.isEnabled = false
        }
        return result
    }
}
