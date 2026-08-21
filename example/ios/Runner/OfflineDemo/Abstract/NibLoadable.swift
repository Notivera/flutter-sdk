//
//  NibLoadable.swift
//  PushSDKDemo
//
//  Created by Phil on 27/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

protocol NibLoadable: AnyObject {
    
    static var nib: UINib { get }
    
}

extension NibLoadable {
    
    static var nib: UINib {
        UINib(
            nibName: String(describing: Self.self),
            bundle: Bundle(for: self)
        )
    }
    
}

