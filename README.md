# rn-screen-share-extension

The Daily Framework to make It easy add support for screen share on iOS.

## Description

In order to be able to use the screen sharing functionality for iOS, you will need to create a Broadcast Upload Extension for your App.

This framework provides all the files needed for capturing the contents of the user's screen and send It to Daily.

It is available for applications running on iOS 14 or newer.

> The feature to send screen sharing is only supported when using react-native-daily-hs 0.46.0 or above.

## Using the Framework

### 1 - Create a new Broadcast Upload Extension target in Xcode.

![new_upload_extension.png](doc-images%2Fnew_upload_extension.png)

- Do not select "include UI extension".
- Recommended naming: ScreenCaptureExtension, since it’s an independent process responsible for ingesting and processing the captured video & audio frames that the OS captures and passing it to your app, which then actually sends the media via WebRTC.

### 2 - Add the ReactNativeDailyJSScreenShareExtension as dependency

You have two options to add the screen share extension: either by utilizing the framework already provided by the pods or by using the package manager. 

It is recommended to follow the steps outlined in Step 2.1.

#### 2.1 Using Cocoa pods

If you are using react-native-daily-js 0.46.0 or later, the easiest way to integrate is using the version that is already available inside the Pods.

Inside the target that you have created, for instance `ScreenCaptureExtension`:
- Click to add a new item inside **_Frameworks and Libraries_**/
- Search for Daily to filter the options.
- Add the `ReactNativeDailyJSScreenShareExtension`.

![search_pod_dependency.png](doc-images%2Fsearch_pod_dependency.png)

![pod_dependency.png](doc-images%2Fpod_dependency.png)

#### 2.2 Using Swift Package Manager

![framework_dependency.png](doc-images%2Fframework_dependency.png)

- You can add this package via Xcode's package manager using the URL of this git repository directly

> You don't need to follow this step if you have already added the dependency using the method described in the step 2.1.

### 3 - Replace your SampleHandler.swift

Replace the default code that has been created by this code below:

```Swift
import ReactNativeDailyJSScreenShareExtension

public class SampleHandler: DailyRPHandler {

  override init() {
    super.init(appGroupIdentifier: "group.co.daily.DailyPlayground")
  }
  
}
```

### 4 - Add the same App Group capability to your App and to your ScreenCaptureExtension target.

![app-group.png](doc-images%2Fapp-group.png)

### 5 Edit your app app target’s `Info.plist`
 
- Add RTCAppGroupIdentifier key with your app group identifier (e.g. co.daily.DailyPlayground.group)
- Add DailyScreenCaptureExtensionBundleIdentifier key with your screen share extension’s bundle identifier (e.g. co.daily.DailyPlayground.ScreenCaptureExtension)

If you view the raw file contents of `Info.plist`, it should look like this:

```
<dict>
    ...
    <key>DailyScreenCaptureExtensionBundleIdentifier</key>
    <string>co.daily.DailyPlayground.ScreenCaptureExtension</string>
    <key>RTCAppGroupIdentifier</key>
    <string>group.co.daily.DailyPlayground</string>
    <key>CFBundleDevelopmentRegion</key>
    ...
</dict>
```
