//
//  StackViewController.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 09/07/2022.
//

import UIKit

class StackViewController: DismissViewController {
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var addButton: UIButton = {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = "Add"
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
            self.addLabel()
        })
        return button
    }()
    
    private lazy var removeButton: UIButton = {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = "Remove"
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
            self.removeLabel()
        })
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.addSubview(stackView)
        stackView.extend(to: contentView.layoutMarginsGuide)
        
        topContentView.addSubview(buttonStackView)
        buttonStackView.extend(to: topContentView.layoutMarginsGuide)
        
        buttonStackView.addArrangedSubview(removeButton)
        buttonStackView.addArrangedSubview(addButton)
        
        addLabel()
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
    
    func addLabel() {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let lastRandomWord = (stackView.arrangedSubviews.last as? UILabel)?.text
        var randomWord = lastRandomWord
        while randomWord == lastRandomWord {
            randomWord = self.randomWord
        }
        label.text = randomWord
        label.numberOfLines = 0
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: randomFontSize, weight: randomFontWeight)

        removeButton.isEnabled = true
        
        stackView.addArrangedSubview(label)
    }
    
    func removeLabel() {
        if let label = stackView.arrangedSubviews.last {
            stackView.removeArrangedSubview(label)
            label.removeFromSuperview()
        }
        
        if stackView.arrangedSubviews.isEmpty {
            removeButton.isEnabled = false
        }
    }
}
