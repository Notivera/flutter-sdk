//
//  UIApplication+topViewController.swift
//  PushSDKApp
//
//  Created by Dimitrios Tsoumanis on 22/02/2023.
//  Copyright © 2026 Notivera. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    class func topViewController(
        viewController: UIViewController? = (
            UIApplication
                .shared
                .connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow })?.rootViewController
    ) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(viewController: nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(viewController: selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(viewController: presented)
        }
        return viewController
    }
}
