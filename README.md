# Rhea

一个用于触发各种时机的框架. 灵感来自字节内部的框架 Gaia, 但是以不同的方式实现的.
在希腊神话中, Rhea 是 Gaia 的女儿, 本框架也因此得名.

Swift 5.10 之后, 支持了`@_used` `@_section` 可以想 section 写入数组, 再通过 Swift Macro, 结合起来, 就可以实现 OC 时代各种解耦和的框架了. 本框架也采用此方式进行了全面重构.

## 要求
XCode 16.1 +
iOS 13 +
Swift 5.10
swift-syntax

## 基本使用
```swift
import RheaExtension

#rhea(time: .customEvent, priority: .veryLow, repeatable: true, func: { _ in
    print("~~~~ customEvent in main")
})

#rhea(time: .homePageDidAppear, func: { context in
    print("~~~~ homepageDidAppear in main")
})

#rhea(time: .premain, func: { _ in
    Rhea.trigger(event: .registerRoute)
})

class ViewController: UIViewController {
    
    #rhea(time: .load, func: { _ in
        print("~~~~ load nested in main")
    })

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homePageDidAppear, param: self)
    }
}
```
框架内提供了三个回调时机, 分别是
1. OC + load
2. premain
3. appDidFinishLaunching

另外用户可以自定义时机和触发, 可以配置同时机的执行优先级, 以及是否可以重复执行

```swift
/// Registers a callback function for a specific Rhea event.
///
/// This macro is used to register a callback function to a section in the binary,
/// associating it with a specific event time, priority, and repeatability.
///
/// - Parameters:
///   - time: A `RheaEvent` representing the timing or event name for the callback.
///           This parameter also supports direct string input, which will be
///           processed by the framework as an event identifier.
///   - priority: A `RheaPriority` value indicating the execution priority of the callback.
///               Default is `.normal`. Predefined values include `.veryLow`, `.low`,
///               `.normal`, `.high`, and `.veryHigh`. Custom integer priorities are also
///               supported. Callbacks for the same event are sorted and executed based
///               on this priority.
///   - repeatable: A boolean flag indicating whether the callback can be triggered multiple times.
///                 If `false` (default), the callback will only be executed once.
///                 If `true`, the callback can be re-triggered on subsequent event occurrences.
///   - func: The callback function of type `RheaFunction`. This function receives a `RheaContext`
///           parameter, which includes `launchOptions` and an optional `Any?` parameter.
///
/// - Note: When triggering an event externally using `Rhea.trigger(event:param:)`, you can include
///              an additional parameter that will be passed to the callback via the `RheaContext`.
///
@freestanding(declaration)
public macro rhea(
    time: RheaEvent,
    priority: RheaPriority = .normal,
    repeatable: Bool = false,
    func: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteTimeToSectionMacro")
```

## 接入工程

### Example工程: https://github.com/Asura19/RheaExample

因为业务要自定义事件, 如下:
```swift
extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
}
```
所以推荐的方式是, 将本框架再封装一层, 如命名为 RheaExtension
```
业务A    业务B
  ↓       ↓
RheaExtension
     ↓
  RheaTime
```

### Swift Package Manager
```swift
// Package.swift
let package = Package(
    name: "RheaExtension",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RheaExtension", targets: ["RheaExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/Rhea.git", from: "1.0.1")
    ],
    targets: [
        .target(
            name: "RheaExtension",
            dependencies: [
                .product(name: "RheaTime", package: "Rhea")
            ]
        ),
    ]
)

// RheaExtension.swift
// @_exported 导出后, 其他业务 module 以及主 target 就只需 import RheaExtension 了
@_exported import RheaTime

extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
}
```

```swift
// 业务 Module Account
// Package.swift
let package = Package(
    name: "Account",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Account",
            targets: ["Account"]),
    ],
    dependencies: [
        .package(name: "RheaExtension", path: "../RheaExtension")
    ],
    targets: [
        .target(
            name: "Account",
            dependencies: [
                .product(name: "RheaExtension", package: "RheaExtension")
            ]
        ),
    ]
)
// 业务 Module Account 使用
import RheaExtension

#rhea(time: .homePageDidAppear, func: { context in
    print("~~~~ homepageDidAppear in main")
})
```

```swift
// 主 target 使用
import RheaExtension

#rhea(time: .premain, func: { _ in
    Rhea.trigger(event: .registerRoute)
})
```

### CocoaPods
由于 CocoaPods 不支持直接使用 Swift Macro, 可以将宏实现编译为二进制提供使用, 接入方式如下:
```swift
// RheaExtension podspec
Pod::Spec.new do |s|
  s.name             = 'RheaExtension'
  s.version          = '0.1.0'
  s.summary          = 'A short description of RheaExtension.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/bjwoodman/RheaExtension'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bjwoodman' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/bjwoodman/RheaExtension.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'RheaExtension/Classes/**/*'
  s.dependency 'RheaTime', '1.0.1'
end
```

```swift
Pod::Spec.new do |s|
  s.name             = 'Account'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Account.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/bjwoodman/Account'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bjwoodman' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/bjwoodman/Account.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Account/Classes/**/*'
  s.dependency 'RheaExtension'
end
```

另外, 因为要加载宏实现的二进制, 需要给每个 pod 添加 other swift flag, 还需要在 podfile 中添加如下脚本:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    rhea_dependency = target.dependencies.find { |d| ['RheaTime', 'RheaExtension'].include?(d.name) }
    if rhea_dependency
      puts "Adding Rhea Swift flags to target: #{target.name}"
      target.build_configurations.each do |config|
        config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
        unless config.build_settings['OTHER_SWIFT_FLAGS'].include?('-load-plugin-executable ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros')
          config.build_settings['OTHER_SWIFT_FLAGS'] << '-load-plugin-executable ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
        end
        unless config.build_settings['OTHER_SWIFT_FLAGS'].include?('-enable-experimental-feature SymbolLinkageMarkers')
          config.build_settings['OTHER_SWIFT_FLAGS'] << '-enable-experimental-feature SymbolLinkageMarkers'
        end
      end
    end
  end
end
```
代码使用上与SPM相同.

----
# 以下为旧版 0.2.1 版本

## 使用方法

### 在工程任意位置扩展 `Rhea` 以实现 `RheaConfigable` 协议, 框架会在启动时自动读取该配置, 并以 `NSClassFromString()` 生成 Class, 所以要求使用本框架的类型必须是 class, 而不能是 struct, enum
```
import Foundation
import RheaTime

extension Rhea: RheaConfigable {
    public static var classNames: [String] {
        return [
            "Rhea_Example.ViewController".
            "REAccountModule"
        ]
    }
}

```

### 在需要使用的类型实现 `RheaDelegate` 中需要的方法. 
其中 `rheaLoad`, `rheaAppDidFinishLaunching(context:)` 为框架内部自动调用, 而 `rheaDidReceiveCustomEvent(event:)` 需要使用者调用 `Rhea.trigger(event:)` 来主动触发.
主动触发的事件名可以直接使用字符串, 也可以扩展 `RheaEvent` 定义常量
```
extension RheaEvent {
    static let homepageDidAppear: RheaEvent = "app_homepageDidAppear"
}

class ViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homepageDidAppear)
    }
}


extension ViewController: RheaDelegate {
    static func rheaLoad() {
        print(#function)
    }
    
    static func rheaPremain() {
        print("ViewController \(#function)")
    }

    static func rheaAppDidFinishLaunching(context: RheaContext) {
        print(#function)
        print(context)
    }

    static func rheaDidReceiveCustomEvent(event: RheaEvent) {
        switch event {
        case "register_route": print("register_route")
        case .homepageDidAppear: print(RheaEvent.homepageDidAppear)
        default: break
        }
    }
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
`>= iOS 10.0`

## Installation

Rhea is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RheaTime'
```

## Author

Asura19, x.rhythm@qq.com

## License

Rhea is available under the MIT license. See the LICENSE file for more info.
