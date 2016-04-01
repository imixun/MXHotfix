#
# Be sure to run `pod lib lint MXHotfix.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MXHotfix"
  s.version          = "0.1.0"
  s.summary          = "MXHotfix is the hotfix for imixun's application"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                        An optional longer description of MXCrashReporter

                        * Markdown format.
                        * Don't worry about the indent, we strip it!
                       DESC

  s.homepage         = "https://github.com/imixun/MXHotfix"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "wuxingyu1983" => "85401996@qq.com" }
  s.source           = { :git => "https://github.com/imixun/MXHotfix.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'MXHotfix' => ['Pod/Assets/*.png']
  }

  s.public_header_files = 'Pod/Classes/MXHotfix.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'JSPatch', '0.2'
  s.dependency 'AFNetworking', '3.0.4'
  s.dependency 'PLCrashReporter', '1.2.0'
  s.dependency 'SSZipArchive', '1.1'
end
