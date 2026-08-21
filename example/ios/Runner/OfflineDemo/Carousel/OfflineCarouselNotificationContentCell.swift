//
//  CarouselNotificationContentCell.swift
//  PushSDKApp
//
//  Created by Phil on 14/11/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit
import WebKit
    
class OfflineCarouselNotificationContentCell: UICollectionViewCell {
    
    //MARK: - State
    
    var scaleMinimum: CGFloat = 0.9
    var scaleDivisor: CGFloat = 10.0
    var alphaMinimum: CGFloat = 0.85
    var cornerRadius: CGFloat = 20.0
    
    //MARK: - Outlets
    
    @IBOutlet private var mainView: UIView!
    @IBOutlet private var imgView: UIImageView!
    
    //MARK: - Actions
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let carouselView = superview as? OfflinePSDKScalingCarouselView else { return }
        carouselView.backgroundColor = .clear
        mainView.backgroundColor = .clear
        scale(withCarouselInset: carouselView.inset)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        mainView.transform = CGAffineTransform.identity
        mainView.alpha = 1.0
    }

    func configure(image: UIImage?) {
        guard let image else {
            return
        }
        
        imgView.image = image
    }

    func scale(withCarouselInset carouselInset: CGFloat) {
        guard let superview = superview,
        let mainView = mainView else { return }

        var origin = superview.convert(frame, to: superview.superview).origin.x
        var contentWidthOrHeight = frame.size.width
        if let collectionView = superview as? OfflinePSDKScalingCarouselView, collectionView.scrollDirection == .vertical {
            origin = superview.convert(frame, to: superview.superview).origin.y
            contentWidthOrHeight = frame.size.height
        }

        let originActual = origin - carouselInset
        let scaleCalculator = abs(contentWidthOrHeight - abs(originActual))
        let percentageScale = (scaleCalculator/contentWidthOrHeight)

        let scaleValue = scaleMinimum
            + (percentageScale/scaleDivisor)

        let alphaValue = alphaMinimum
            + (percentageScale/scaleDivisor)

        let affineIdentity = CGAffineTransform.identity
        mainView.transform = affineIdentity.scaledBy(x: scaleValue, y: scaleValue)
        mainView.alpha = alphaValue
        mainView.layer.cornerRadius = cornerRadius
    }
    
}
