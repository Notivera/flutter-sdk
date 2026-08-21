//
//  UICollectionView+register.swift
//  PushSDKDemo
//
//  Created by Phil on 27/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    
    func register<Cell: UICollectionViewCell>(nibForCell cell: Cell.Type) {
        register(
            Cell.nib,
            forCellWithReuseIdentifier: Cell.identifier
        )
    }
    
    func register<Cell: UICollectionViewCell>(classForCell cell: Cell.Type) {
        register(
            cell,
            forCellWithReuseIdentifier: Cell.identifier
        )
    }
    
}
