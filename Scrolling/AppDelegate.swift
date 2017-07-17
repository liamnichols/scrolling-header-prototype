//
//  AppDelegate.swift
//  Scrolling
//
//  Created by Liam Nichols on 15/07/2017.
//  Copyright © 2017 Liam Nichols. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MainViewController()
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}

