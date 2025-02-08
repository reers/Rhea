[中文文档](README_CN.md)

# Rhea

A framework for triggering various timings. Inspired by ByteDance's internal framework Gaia, but implemented in a different way.
In Greek mythology, Rhea is the daughter of Gaia, hence the name of this framework.

After Swift 5.10, with the support of `@_used` `@_section` which can write data into sections, combined with Swift Macro, we can now achieve various decoupling and registration capabilities from the OC era. This framework has also been completely refactored using this approach.

🟡 Currently, this capability is still an experimental Swift Feature and needs to be enabled through configuration settings. See the integration documentation for details.

## Requirements
XCode 16.0 +

iOS 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 7.0+

Swift 5.10

swift-syntax 600.0.0

## Basic Usage
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

#rhea(time: .load) { _ in
    print("load with trailing closure")
}

class ViewController: UIViewController {
    
    #rhea(time: .load, func: { _ in
        print("~~~~ load nested in main")
    })

    #rhea(time: .homePageDidAppear) { context in
        print("homePageDidAppear with trailing closure \(context.param)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homePageDidAppear, param: self)
    }
}
```
The framework provides three callback timings:
1. OC + load
2. constructor (premain)
3. appDidFinishLaunching ()

These three timings are triggered internally by the framework, and there's no need for external trigger calls.

Additionally, users can customize timings and triggers, configure execution priorities for the same timing, and whether they can be repeatedly executed.
⚠️⚠️⚠️ However, note that the variable name of custom timing must exactly match its rawValue String, otherwise Swift Macro cannot process it correctly.

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

## Project Integration

### Example Project: https://github.com/Asura19/RheaExample

Since business needs to customize events, like this:
```swift
extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
}
```
The recommended approach is to wrap this framework in another layer, named RheaExtension for example
```
BusinessA    BusinessB
    ↓           ↓
RheaExtension
     ↓
  RheaTime
```

Additionally, RheaExtension can not only customize event names but also encapsulate business logic for timing events
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
External usage
```
#rhea(time: .didEnterBackground, repeatable: true, func: { _ in
    print("~~~~ app did enter background")
})
```

### Swift Package Manager
Enable experimental feature through `swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]` in the dependent Package
```swift
// Package.swift
let package = Package(
    name: "RheaExtension",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RheaExtension", targets: ["RheaExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/Rhea.git", from: "1.2.1")
    ],
    targets: [
        .target(
            name: "RheaExtension",
            dependencies: [
                .product(name: "RheaTime", package: "Rhea")
            ],
            // Add experimental feature enable here
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)

// RheaExtension.swift
// After @_exported, other business modules and main target only need to import RheaExtension
@_exported import RheaTime

extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
}
```

```swift
// Business Module Account
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
            // Add experimental feature enable here
            swiftSettings:[.enableExperimentalFeature("SymbolLinkageMarkers")]
        ),
    ]
)
// Business Module Account usage
import RheaExtension

#rhea(time: .homePageDidAppear, func: { context in
    print("~~~~ homepageDidAppear in main")
})
```

In the main App Target, enable experimental feature in Build Settings:
-enable-experimental-feature SymbolLinkageMarkers
![CleanShot 2024-10-12 at 20 39 59@2x](https://github.com/user-attachments/assets/92a382aa-b8b7-4b49-8a8f-c8587caaf2f1)


```swift
// Main target usage
import RheaExtension

#rhea(time: .premain, func: { _ in
    Rhea.trigger(event: .registerRoute)
})
```

Additionally, you can directly pass `StaticString` as time key.
```
#rhea(time: "ACustomEventString", func: { _ in
    print("~~~~ custom event")
})
```

### CocoaPods

Add to Podfile:

```ruby
pod 'RheaTime'
```

Since CocoaPods doesn't support using Swift Macro directly, you can compile the macro implementation into binary for use. The integration method is as follows, requiring `s.pod_target_xcconfig` to load the binary plugin of macro implementation:
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

  s.dependency 'RheaTime', '1.2.1'

  # Copy following config to your pod
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
  
  # Copy following config to your pod
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
  }
end
```

Alternatively, if not using `s.pod_target_xcconfig` and `s.user_target_xcconfig`, you can add the following script in podfile for unified processing:
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
        
        # Add SymbolLinkageMarkers experimental feature flag
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
Code usage is the same as SPM.

## Author

Asura19, x.rhythm@qq.com

## License

Rhea is available under the MIT license. See the LICENSE file for more info.
