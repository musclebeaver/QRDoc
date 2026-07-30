import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let CHANNEL = "com.devbeaver.qrdoc/emergency"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let emergencyChannel = FlutterMethodChannel(name: CHANNEL,
                                              binaryMessenger: controller.binaryMessenger)
    
    emergencyChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      switch call.method {
      case "getInitialRoute":
        // Query initial launch arguments (e.g. from widgets deep link)
        result(nil)
      case "startEmergencyService":
        if let args = call.arguments as? [String: Any] {
          let name = args["name"] as? String ?? ""
          let blood = args["blood"] as? String ?? ""
          let contact = args["contact"] as? String ?? ""
          
          // Save to App Group shared container for Widget access
          if let sharedDefaults = UserDefaults(suiteName: "group.com.devbeaver.qrdoc") {
            sharedDefaults.set(name, forKey: "name")
            sharedDefaults.set(blood, forKey: "blood")
            sharedDefaults.set(contact, forKey: "contact")
            sharedDefaults.synchronize()
          }
          
          // Refresh iOS Home Screen Widgets
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
        }
        result(true)
      case "stopEmergencyService":
        // Wipe shared values
        if let sharedDefaults = UserDefaults(suiteName: "group.com.devbeaver.qrdoc") {
          sharedDefaults.removeObject(forKey: "name")
          sharedDefaults.removeObject(forKey: "blood")
          sharedDefaults.removeObject(forKey: "contact")
          sharedDefaults.synchronize()
        }
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
