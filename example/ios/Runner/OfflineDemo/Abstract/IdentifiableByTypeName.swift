//
//  IdentifiableByTypeName.swift
//  PushSDKDemo
//
//  Created by Phil on 27/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation

protocol IdentifiableByTypeName {
    
    static var identifier: String { get }
    
}

extension IdentifiableByTypeName {
    
    static var identifier: String {
        String(describing: Self.self)
    }
    
}
