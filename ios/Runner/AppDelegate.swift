import Flutter
import UIKit
import ReplayKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
          //     ScreenSharing channel handling
          let controller = window.rootViewController as? FlutterViewController
          let screensharingIOSChannel = FlutterMethodChannel(
              name: "example_screensharing_ios",
              binaryMessenger: controller as! FlutterBinaryMessenger)

          screensharingIOSChannel.setMethodCallHandler({
              (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
              if call.method == "startScreenSharing" {
                  self.startScreenSharing(controller: controller!)
                  result(nil)
              } else {
                  result(FlutterMethodNotImplemented)
              }
          })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

   private func startScreenSharing(controller: FlutterViewController) {
          guard #available(iOS 12.0, *) else { return }

          DispatchQueue.main.async {
              let systemBroadcastPicker = RPSystemBroadcastPickerView(frame: CGRect(x: 50, y: 200, width: 60, height: 60))
              systemBroadcastPicker.showsMicrophoneButton = true
              systemBroadcastPicker.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]

              // Set the preferred extension for your app
              if let url = Bundle.main.url(forResource: nil, withExtension: "appex", subdirectory: "PlugIns"),
                 let bundle = Bundle(url: url) {
                  systemBroadcastPicker.preferredExtension = bundle.bundleIdentifier
              }

              // Add picker to the view
              controller.view.addSubview(systemBroadcastPicker)
          }
      }

}
