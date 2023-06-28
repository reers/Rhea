//
//  RheaClasses.swift
//  Rhea_Example
//
//  Created by phoenix on 2023/4/1.
//  Copyright © 2023 Reer. All rights reserved.
//

import Foundation
import RheaTime

extension Rhea: RheaConfigable {
    public static var classNames: [String] {
        return [
            "Rhea_Example.ViewController",
            "REAccountModule"
        ]
    }
}
