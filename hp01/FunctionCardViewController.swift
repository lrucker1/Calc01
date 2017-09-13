//
//  FunctionCardViewController.swift
//  retrocalc
//
//  Created by Lee Ann Rucker on 9/13/17.
//  Copyright © 2017 Lee Ann Rucker. All rights reserved.
//

import UIKit

class FunctionCardViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            // There's a layout bug in 10 that's fixed in 11 - it shrinks the height for landscape mode,
            // but then doesn't grow when it goes back to portrait.
            // Restrict it to portrait as that's the usual way to hold a phone,
            // because the transition is wonky looking when they're not matched.
            if (UIDevice.current.systemVersion as NSString).intValue < 11 {
                return .portrait
            }
            return .all
        }
    }
}
