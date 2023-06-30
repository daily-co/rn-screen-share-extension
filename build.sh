# Instructions on how to build a framework and publish It
# https://www.kodeco.com/17753301-creating-a-framework-for-ios

# Building for physical devices
xcodebuild archive \
-scheme ReactNativeDailyJSScreenShareExtension \
-configuration Release \
-destination 'generic/platform=iOS' \
-archivePath './build/ReactNativeDailyJSScreenShareExtension.framework-iphoneos.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

# Building for simulator
xcodebuild archive \
-scheme ReactNativeDailyJSScreenShareExtension \
-configuration Release \
-destination 'generic/platform=iOS Simulator' \
-archivePath './build/ReactNativeDailyJSScreenShareExtension.framework-iphonesimulator.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

# Creating the framework
xcodebuild -create-xcframework \
-framework './build/ReactNativeDailyJSScreenShareExtension.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/ReactNativeDailyJSScreenShareExtension.framework' \
-framework './build/ReactNativeDailyJSScreenShareExtension.framework-iphoneos.xcarchive/Products/Library/Frameworks/ReactNativeDailyJSScreenShareExtension.framework' \
-output './dist/ReactNativeDailyJSScreenShareExtension.xcframework'

# Zipping the framework
(cd dist; zip -r ReactNativeDailyJSScreenShareExtension.xcframework.zip ReactNativeDailyJSScreenShareExtension.xcframework)

# Cleaning the tmp build dir
rm -rf ./build
rm -rf dist/ReactNativeDailyJSScreenShareExtension.xcframework
