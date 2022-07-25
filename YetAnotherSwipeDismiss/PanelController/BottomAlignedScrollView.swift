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
    
    private(set) lazy var contentView: UIView = {
        let view = ContentView(frame: self.bounds)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        automaticallyAdjustsScrollIndicatorInsets = false
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.add {
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
            contentView.widthAnchor.constraint(equalTo: widthAnchor)
            contentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateInsets()
    }
    
    private func updateInsets() {
        // Set top inset so content is aligned to bottom
        let availableArea = frame.inset(by: safeAreaInsets).size
        contentInset.top = max(0, availableArea.height - contentView.bounds.height)
        contentSize.height = contentView.bounds.height
        
        // Make top of scroll indicator never extend beyond top of content
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
