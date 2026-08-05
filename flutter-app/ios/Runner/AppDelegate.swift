import UIKit
import Flutter
import WidgetKit
import UserNotifications

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
      case "scheduleMedicationAlarm":
        if let args = call.arguments as? [String: Any] {
          let idInt = args["id"] as? Int ?? 0
          let id = String(idInt)
          let title = args["title"] as? String ?? "복약 알림"
          let message = args["message"] as? String ?? "약 먹을 시간입니다!"
          let hour = args["hour"] as? Int ?? 8
          let minute = args["minute"] as? Int ?? 0
          
          if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            
            // Request permissions if not already authorized
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // Create daily repeating calendar trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            center.add(request) { error in
              if let error = error {
                print("Failed to schedule local notification: \(error)")
              }
            }
          }
        }
        result(true)
      case "cancelMedicationAlarm":
        if let args = call.arguments as? [String: Any] {
          let idInt = args["id"] as? Int ?? 0
          let id = String(idInt)
          if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
          }
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
