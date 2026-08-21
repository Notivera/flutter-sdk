//
//  ReuseableCollectionCellBasedOnTypeDequeueing.swift
//  PushSDKDemo
//
//  Created by Phil on 16/08/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

protocol ReusableCollectionCellBasedOnTypeDequeueing {
    
    func dequeueReusableCell<Cell>(
        of cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell where Cell: UICollectionViewCell
    
}

extension UICollectionView: ReusableCollectionCellBasedOnTypeDequeueing {
    
    public func dequeueReusableCell<Cell>(
        of cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell where Cell: UICollectionViewCell {
        unsafelyCasting(dequeueReusableCell(withReuseIdentifier: Cell.identifier, for: indexPath))
    }
    
}
