#
# Be sure to run `pod lib lint NetworkKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "WDAppKit"
  s.version          = "1.0.0"
  s.summary          = "WDAppKit Lib."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  WDApp工具包
                       DESC

  s.homepage         = "https://github.com/leocll/WDAppKit.git"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "leocll" => "leocll@qq.com" }
  s.source           = { :git => "https://github.com/leocll/WDAppKit.git", :branch => 'master' }
  #s.source_files = ""
  #s.resources = ""

  # WDHelper
  s.subspec 'WDHelper' do |ss|
    ss.source_files = 'WDAppKit/WDAppKit/Core/WDHelper/**/*'
  end

  s.ios.deployment_target = "8.0"

  # FaceBook
  s.dependency 'FBSDKLoginKit'
  # google 统计
  s.dependency 'Firebase/Core'
  # 统计
  s.dependency 'AppsFlyerFramework'

end


