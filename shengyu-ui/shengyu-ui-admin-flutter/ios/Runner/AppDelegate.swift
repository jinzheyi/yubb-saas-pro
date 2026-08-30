import Flutter
import FirebaseCore
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Keep Android/Web work unblocked when an iOS Firebase plist has not yet
    // been provisioned. Once GoogleService-Info.plist is added to Runner,
    // Firebase Messaging is initialized before Flutter plugins are registered.
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil,
       FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CallScreenAwakeService") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.shengyu.im/call_screen_awake",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setKeepScreenOn", let enabled = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.isIdleTimerDisabled = enabled
      result(nil)
    }
  }
}
