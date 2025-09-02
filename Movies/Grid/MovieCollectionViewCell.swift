//
//  MovieCollectionViewCell.swift
//  Movies
//
//  Created by Rod Brown on 20/10/17.
//  Copyright © 2017 Rod Brown. All rights reserved.
//

import UIKit
import FastImageCache

class MovieCollectionViewCell: UICollectionViewCell {

    static func cellSize(forDisplaySize displaySize: CGSize) -> CGSize {
        let portraitWidth: CGFloat
        if UIDevice.current.userInterfaceIdiom == .pad {
            portraitWidth = 320.0
        } else {
            portraitWidth = min(displaySize.width, displaySize.height)
        }

        let imageWidth = (portraitWidth - 60.0) / 2.0
        return CGSize(width: imageWidth, height: round(imageWidth / 2 * 3))
    }

    let imageView = UIImageView()
    
    override var isSelected: Bool {
        didSet {
            if isSelected != oldValue && isEditing {
                updateHighlightedState()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue && isEditing {
                updateHighlightedState()
            }
        }
    }
    
    var lastFetchedForIndexPath: IndexPath?
    
    private var highlightedDimmingView: UIView?
    private lazy var checkmarkImageView = UIImageView(image: .strokedCheckmark)
    
    private var isEditing: Bool = false {
        didSet {
            if isEditing != oldValue {
                updateHighlightedState()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.backgroundColor = .secondarySystemGroupedBackground
        contentView.addSubview(imageView)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        if state.isEditing != isEditing {
            isEditing = state.isEditing
        }
    }
    
    private func updateHighlightedState() {
        let showHighlightedView = isHighlighted || isSelected
        let preferredAlpha: CGFloat = showHighlightedView ? 1 : 0
        
        if showHighlightedView && highlightedDimmingView == nil {
            let dimmingView = UIView(frame: imageView.bounds)
            dimmingView.backgroundColor = .cellSelectionOverlay
            dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            dimmingView.alpha = 0
            
            checkmarkImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
            checkmarkImageView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
            checkmarkImageView.isHidden = isEditing == false
            
            let highlightBounds = dimmingView.bounds
            let checkmarkSize = checkmarkImageView.frame(forAlignmentRect: CGRect(origin: .zero, size: checkmarkImageView.intrinsicContentSize)).size
            checkmarkImageView.frame = CGRect(
                x: highlightBounds.size.width - 10 - checkmarkSize.width,
                y: highlightBounds.size.height - 10 - checkmarkSize.height,
                width: checkmarkSize.width,
                height: checkmarkSize.height
            )
            dimmingView.alpha = 0
            highlightedDimmingView = dimmingView
            dimmingView.addSubview(checkmarkImageView)
            imageView.addSubview(dimmingView)
        }
 
        guard 
            UIView.areAnimationsEnabled,
            isEditing == false,
            let highlightedDimmingView
        else {
            highlightedDimmingView?.alpha = preferredAlpha
            highlightedDimmingView?.isHidden = showHighlightedView == false
            return
        }
        
        if showHighlightedView {
            highlightedDimmingView.isHidden = false
        }
        
        guard abs(highlightedDimmingView.alpha - preferredAlpha) > 0.01 else {
            return
        }
        
        UIView.animate(withDuration: 0.12) {
            highlightedDimmingView.alpha = preferredAlpha
        } completion: { [self] complete in
            guard
                complete,
                showHighlightedView == false,
                isHighlighted == false,
                isSelected == false
            else {
                return
            }
            
            highlightedDimmingView.alpha = 0
            highlightedDimmingView.isHidden = true
        }
    }

}
