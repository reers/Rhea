//
//  RheaConfigable.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

/// Extend `RheaConfigable` to setup the classes that will listen rhea time.
///
///     extension Rhea: RheaConfigable {
///         public static var classNames: [String] {
///             return [
///                 "Rhea_Example.ViewController"
///             ]
///         }
///     }
///
public protocol RheaConfigable: Rhea {
    static var classNames: [String] { get }
}
