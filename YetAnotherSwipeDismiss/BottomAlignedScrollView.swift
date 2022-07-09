//
//  BottomAlignedScrollView.swift
//  YetAnotherSwipeDismiss
//
//  Created by Pim on 09/07/2022.
//

import UIKit

class BottomAlignedScrollView: UIScrollView {
    
    var extraTopInset: CGFloat = 0 { didSet {
        setNeedsLayout()
    }}
    
    class ContentView: UIView { }
    class BackgroundView: UIView { }
    
    private(set) lazy var contentView: UIView = {
        let view = ContentView(frame: self.bounds)
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = BackgroundView(frame: self.bounds)
        view.backgroundColor = .systemGray
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        automaticallyAdjustsScrollIndicatorInsets = false
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        addSubview(contentView)
        
        setLayoutConstraints()
    }
    
    private func setLayoutConstraints() {
        NSLayoutConstraint.add {
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
            contentView.widthAnchor.constraint(equalTo: widthAnchor)
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor)
        }
    }
    
    override func updateConstraints() {
        super.updateConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let availableArea = frame.inset(by: safeAreaInsets).size
        contentInset.top = max(0, availableArea.height - contentView.bounds.height)
        contentSize.height = contentView.bounds.height
        
        let bottomInset = safeAreaInsets.bottom
        let bottomScrollOvershoot = bounds.height - (bounds.maxY + adjustedContentInset.top)

        backgroundView.frame = contentView.frame.inset(by: UIEdgeInsets(
            top: 0, left: 0,
            bottom: -bottomInset + bottomScrollOvershoot,
            right: 0
        ))
        
        let topScrollOvershoot = min(0, contentOffset.y + adjustedContentInset.top)
        verticalScrollIndicatorInsets = UIEdgeInsets(
            top: adjustedContentInset.top - topScrollOvershoot,
            left: 0,
            bottom: adjustedContentInset.bottom,
            right: 0
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
