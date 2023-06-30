Pod::Spec.new do |spec|
  spec.name               = "ReactNativeDailyJSScreenShareExtension"
  spec.version            = "0.0.1"
  spec.summary            = "Daily Screen Share Extension for iOS"
  spec.homepage           = "https://github.com/daily-co/rn-screen-share-extension"
  spec.description        = "The Daily extension to allow you to screen share on iOS"
  spec.documentation_url  = "https://github.com/daily-co/rn-screen-share-extension"
  spec.license            = { :type => "BSD-2" }
  spec.author             = { "Daily.co" => "help@daily.co" }
  spec.platforms          = { :ios => '12.0' }
  spec.source             = { :http => 'https://www.daily.co/sdk/ReactNativeDailyJSScreenShareExtension.xcframework-0.0.1.zip', :flatten => false }
  spec.vendored_frameworks = "ReactNativeDailyJSScreenShareExtension.xcframework"
end
