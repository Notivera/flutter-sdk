//
//  LoadableFromStoryboard.swift
//  PushSDKDemo
//
//  Created by Phil on 27/05/2022.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

protocol LoadableFromStoryboard {}

extension LoadableFromStoryboard where Self: UIViewController {
    
    internal static func loadFromStoryboard(
        named storyboardName: String? = nil,
        inBundle bundle: Bundle? = nil,
        creator: ((NSCoder) -> UIViewController?)? = nil
    ) -> Self {
        let storyboard = UIStoryboard(
            name: storyboardName ?? String(describing: Self.self),
            bundle: Bundle(for: self)
        )
        
        guard let initalViewController = storyboard.instantiateInitialViewController(creator: creator) else {
            fatalError("Cannot find initial view controller")
        }
        
        let viewController: UIViewController?
        if let initalViewController = initalViewController as? UINavigationController {
            viewController = initalViewController.children.first
        } else {
            viewController = initalViewController
        }
        
        guard let castedViewController = viewController as? Self else {
            fatalError("Cannot cast \(String(describing: viewController)) into instance of \(Self.self)")
        }
        
        return castedViewController
    }
    
}

