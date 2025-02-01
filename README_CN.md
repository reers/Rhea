# Rhea

一个用于触发各种时机的框架. 灵感来自字节内部的框架 Gaia, 但是以不同的方式实现的.
在希腊神话中, Rhea 是 Gaia 的女儿, 本框架也因此得名.

Swift 5.10 之后, 支持了`@_used` `@_section` 可以将数据写入 section, 再结合 Swift Macro, 就可以实现 OC 时代各种解耦和的, 用于注册信息的能力了. 本框架也采用此方式进行了全面重构.

🟡 目前这个能力还是 Swift 的实验 Feature, 需要通过配置项开启, 详见接入文档.

## 要求
XCode 16.0 +

iOS 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 7.0+

Swift 5.10

swift-syntax 600.0.0

## 基本使用
```swift
import RheaExtension

#rhea(time: .customEvent, priority: .veryLow, repeatable: true, func: { _ in
    print("~~~~ customEvent in main")
})

#rhea(time: .homePageDidAppear, async: true, func: { context in
    // This will run on a background thread
    print("~~~~ homepageDidAppear")
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
2. constructor (premain)
3. appDidFinishLaunching ()

这三个时机是由框架内部触发的，外部无需调用 trigger 方法。

另外用户可以自定义时机和触发, 可以配置同时机的执行优先级, 以及是否可以重复执行.
⚠️⚠️⚠️ 但需要注意的是, 自定义时机的变量名要和其 rawValue 的 String 完全相同, 否则 Swift Macro 无法正确处理 

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
///   - async: A boolean flag indicating whether the callback should be executed asynchronously.
///            If `false` (default), the callback will be executed on the main thread.
///            If `true`, the callback will be executed on a background thread. Note that when
///            `async` is `true`, the execution order based on `priority` may not be guaranteed.
///            Even when `async` is set to `false`, users can still choose to dispatch their tasks
///            to a background queue within the callback function if needed. This provides
///            flexibility for handling both quick, main thread operations and longer-running
///            background tasks.
///   - func: The callback function of type `RheaFunction`. This function receives a `RheaContext`
///           parameter, which includes `launchOptions` and an optional `Any?` parameter.
///
/// - Note: When triggering an event externally using `Rhea.trigger(event:param:)`, you can include
///         an additional parameter that will be passed to the callback via the `RheaContext`.
///
/// ```swift
/// #rhea(time: .load, priority: .veryLow, repeatable: true, func: { _ in
///     print("~~~~ load in Account Module")
/// })
///
/// #rhea(time: .registerRoute, func: { _ in
///     print("~~~~ registerRoute in Account Module")
/// })
///
/// // Use a StaticString as event directly
/// #rhea(time: "ACustomEventString", func: { _ in
///     print("~~~~ custom event")
/// })
///
/// // Example of using async execution
/// #rhea(time: .load, async: true, func: { _ in
///     // This will run on a background thread
///     performHeavyTask()
/// })
///
/// // Example of manually dispatching to background queue when async is false
/// #rhea(time: .load, func: { _ in
///     DispatchQueue.global().async {
///         // Perform background task
///     }
/// })
/// ```
/// - Note: ⚠️⚠️⚠️ When extending ``RheaEvent`` with static constants, ensure that
///   the constant name exactly matches the string literal value. This practice
///   maintains consistency and prevents confusion.
///
@freestanding(declaration)
public macro rhea(
    time: RheaEvent,
    priority: RheaPriority = .normal,
    repeatable: Bool = false,
    async: Bool = false,
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
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
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

另外, RheaExtension 中除了可以自定义事件名, 还可以封装一些时机事件的业务逻辑
```
#rhea(time: .appDidFinishLaunching, func: { _ in
    NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil,
        queue: .main
    ) { _ in
        Rhea.trigger(event: .didEnterBackground)
    }
})
```
外部使用
```
#rhea(time: .didEnterBackground, repeatable: true, func: { _ in
    print("~~~~ app did enter background")
})
```

### Swift Package Manager
在依赖的Package中通过 `swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]` 开启实验feature
```swift
// Package.swift
let package = Package(
    name: "RheaExtension",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RheaExtension", targets: ["RheaExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/Rhea.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "RheaExtension",
            dependencies: [
                .product(name: "RheaTime", package: "Rhea")
            ],
            // 此处添加开启实验 feature
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)

// RheaExtension.swift
// @_exported 导出后, 其他业务 module 以及主 target 就只需 import RheaExtension 了
@_exported import RheaTime

extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
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
            ],
            // 此处添加开启实验 feature
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)
// 业务 Module Account 使用
import RheaExtension

#rhea(time: .homePageDidAppear, func: { context in
    print("~~~~ homepageDidAppear in main")
})
```

在主App Target中 Build Settings设置开启实验feature:
-enable-experimental-feature SymbolLinkageMarkers
![CleanShot 2024-10-12 at 20 39 59@2x](https://github.com/user-attachments/assets/92a382aa-b8b7-4b49-8a8f-c8587caaf2f1)


```swift
// 主 target 使用
import RheaExtension

#rhea(time: .premain, func: { _ in
    Rhea.trigger(event: .registerRoute)
})
```

另外, 还可以直接传入 `StaticString` 作为 time key.
```
#rhea(time: "ACustomEventString", func: { _ in
    print("~~~~ custom event")
})
```

### CocoaPods

Podfile中添加:

```ruby
pod 'RheaTime'
```

由于 CocoaPods 不支持直接使用 Swift Macro, 可以将宏实现编译为二进制提供使用, 接入方式如下, 需要设置`s.pod_target_xcconfig`来加载宏实现的二进制插件:
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

  s.dependency 'RheaTime', '1.1.0'

  # 复制以下 config 到你的 pod
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
  }
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
  
  # 复制以下 config 到你的 pod
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
  }
end
```

或者, 如果不使用`s.pod_target_xcconfig`和`s.user_target_xcconfig`, 也可以在 podfile 中添加如下脚本统一处理:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    rhea_dependency = target.dependencies.find { |d| ['RheaTime', 'RheaExtension'].include?(d.name) }
    if rhea_dependency
      puts "Adding Rhea Swift flags to target: #{target.name}"
      target.build_configurations.each do |config|
        swift_flags = config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
        
        plugin_flag = '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
        
        unless swift_flags.join(' ').include?(plugin_flag)
          swift_flags.concat(plugin_flag.split)
        end
        
        # 添加 SymbolLinkageMarkers 实验性特性标志
        symbol_linkage_flag = '-enable-experimental-feature SymbolLinkageMarkers'
        
        unless swift_flags.join(' ').include?(symbol_linkage_flag)
          swift_flags.concat(symbol_linkage_flag.split)
        end
        
        config.build_settings['OTHER_SWIFT_FLAGS'] = swift_flags
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
