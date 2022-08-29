//
//  ViewController.swift
//  Rhea
//
//  Created by Asura19 on 08/13/2022.
//  Copyright (c) 2022 Asura19. All rights reserved.
//

import UIKit
import Rhea
import OSLog

extension RheaTimeName {
    static let mainViewControllerDidAppear = RheaTimeName(rawValue: "mainViewControllerDidAppear")
}

extension Rhea {
    
    @objc
    func load_viewController() {
        ViewController.doSomethingWhenload()
    }
    
    @objc
    func appDidFinishLaunching_viewController() {
        ViewController.doSomethingWhenAppDidFinishLaunching()
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.shared().trigger(withTime: .mainViewControllerDidAppear)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    class func doSomethingWhenload() {
        os_log("ViewController doSomethingWhenload")
    }
    
    class func doSomethingWhenAppDidFinishLaunching() {
        os_log("ViewController doSomethingWhenAppDidFinishLaunching")
    }
}

