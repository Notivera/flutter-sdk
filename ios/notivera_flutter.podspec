#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint notivera_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'notivera_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin wrapping the Notivera native Android and iOS SDKs.'
  s.description      = <<-DESC
Flutter plugin wrapping the Notivera native Android and iOS SDKs.
                       DESC
  s.homepage         = 'https://github.com/Notivera/flutter_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Notivera' => 'support@notivera.com' }
  s.source           = { :path => '.' }
  s.source_files = 'notivera_flutter/Sources/notivera_flutter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
