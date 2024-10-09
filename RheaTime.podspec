#
# Be sure to run `pod lib lint Rhea.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RheaTime'
  s.version          = '1.0.6'
  s.summary          = 'iOS App Time Dispatcher.'

  s.description      = <<-DESC
  iOS App Time Dispatcher (Swift, Objc supported).
                       DESC

  s.homepage         = 'https://github.com/reers/Rhea'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Asura19' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/Rhea.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.10'

  s.source_files = 'Sources/**/*'
  s.preserve_paths = ["Sources/Resources/RheaTimeMacros"]
  s.exclude_files = 'Sources/RheaTimeMacros'
  
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
  }
  
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/Sources/Resources/RheaTimeMacros#RheaTimeMacros'
  }

end
