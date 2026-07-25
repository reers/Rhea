#
# Be sure to run `pod lib lint RheaTime.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RheaTime'
  s.version          = '2.4.0'
  s.summary          = 'iOS App Time Dispatcher.'

  s.description      = <<-DESC
  iOS App Time Dispatcher (Swift, Objc supported).
                       DESC

  s.homepage         = 'https://github.com/reers/Rhea'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Asura19' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/reers/Rhea.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = "10.15"
  s.watchos.deployment_target = "7.0"
  s.tvos.deployment_target = "13.0"
  s.visionos.deployment_target = "1.0"

  s.swift_versions = '5.10'

  s.source_files = 'Sources/RheaTime/**/*', 'Sources/OCRhea/**/*'
  # Macro plugin sources are SPM-only (need SwiftSyntax); CocoaPods downloads
  # a prebuilt universal binary from GitHub Release (see script_phase below).
  s.exclude_files = 'Sources/RheaTimeMacros', 'Sources/RheaTimeMacroExpansion'

  s.preserve_paths = [
    'Package.swift',
    'Sources/RheaTimeMacros',
    'Sources/RheaTimeMacroExpansion',
    'Tests',
    'MacroPlugin'
  ]

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_BUILD_DIR}/RheaTime/MacroPlugin/RheaTimeMacros#RheaTimeMacros'
  }

  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-enable-experimental-feature SymbolLinkageMarkers -Xfrontend -load-plugin-executable -Xfrontend ${PODS_BUILD_DIR}/RheaTime/MacroPlugin/RheaTimeMacros#RheaTimeMacros'
  }

  # Download prebuilt universal macro plugin from GitHub Release
  script = <<-SCRIPT
    set -e

    PLUGIN_DIR="${PODS_BUILD_DIR}/RheaTime/MacroPlugin"
    PLUGIN_NAME="RheaTimeMacros"
    VERSION="#{s.version}"
    DOWNLOAD_URL="https://github.com/reers/Rhea/releases/download/${VERSION}/${PLUGIN_NAME}.zip"

    # Check if plugin already exists
    if [ -x "${PLUGIN_DIR}/${PLUGIN_NAME}" ]; then
      echo "Macro plugin already exists, skipping download."
      exit 0
    fi

    mkdir -p "${PLUGIN_DIR}"

    echo "Downloading prebuilt macro plugin from ${DOWNLOAD_URL}..."

    if curl -L -f --connect-timeout 3 --max-time 60 -o "${PLUGIN_DIR}/${PLUGIN_NAME}.zip" "${DOWNLOAD_URL}"; then
      unzip -o "${PLUGIN_DIR}/${PLUGIN_NAME}.zip" -d "${PLUGIN_DIR}"
      rm -f "${PLUGIN_DIR}/${PLUGIN_NAME}.zip"
      chmod +x "${PLUGIN_DIR}/${PLUGIN_NAME}"
      echo "Successfully downloaded prebuilt macro plugin"
      file "${PLUGIN_DIR}/${PLUGIN_NAME}"
    else
      echo "Warning: Failed to download prebuilt macro plugin, will build from source..."

      # Fallback: build from source
      env -i PATH="$PATH" "$SHELL" -l -c "swift build -c release --package-path \\"${PODS_TARGET_SRCROOT}\\" --build-path \\"${PODS_BUILD_DIR}/RheaTime\\" --product RheaTimeMacros"
      cp "${PODS_BUILD_DIR}/RheaTime/release/RheaTimeMacros-tool" "${PLUGIN_DIR}/${PLUGIN_NAME}"
      chmod +x "${PLUGIN_DIR}/${PLUGIN_NAME}"
      echo "Built macro plugin from source"
      file "${PLUGIN_DIR}/${PLUGIN_NAME}"
    fi
  SCRIPT

  s.script_phase = {
    :name => 'Download RheaTimeMacros Plugin',
    :script => script,
    :execution_position => :before_compile
  }

  s.dependency 'SectionReader'
end
