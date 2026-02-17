import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  static let appGroupId = "group.com.example.taskit"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up platform channel for widget communication
    let controller = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "com.taskit.widget", binaryMessenger: controller.binaryMessenger)

    widgetChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setWidgetConfig":
        if let args = call.arguments as? [String: Any] {
          guard let defaults = UserDefaults(suiteName: AppDelegate.appGroupId) else {
            result(FlutterError(code: "DEFAULTS_ERROR", message: "Cannot access shared defaults", details: nil))
            return
          }
          if let userId = args["userId"] as? String {
            defaults.set(userId, forKey: "widget_user_id")
          }
          if let displayMode = args["displayMode"] as? String {
            defaults.set(displayMode, forKey: "widget_display_mode")
          }
          if let listId = args["listId"] as? Int {
            defaults.set(listId, forKey: "widget_list_id")
          }
          defaults.synchronize()

          // Tell WidgetKit to refresh
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }

      case "getWidgetConfig":
        let defaults = UserDefaults(suiteName: AppDelegate.appGroupId)
        let config: [String: Any?] = [
          "userId": defaults?.string(forKey: "widget_user_id"),
          "displayMode": defaults?.string(forKey: "widget_display_mode") ?? "all_tasks",
          "listId": defaults?.integer(forKey: "widget_list_id") ?? 0
        ]
        result(config)

      case "clearWidgetConfig":
        if let defaults = UserDefaults(suiteName: AppDelegate.appGroupId) {
          defaults.removeObject(forKey: "widget_user_id")
          defaults.removeObject(forKey: "widget_display_mode")
          defaults.removeObject(forKey: "widget_list_id")
          defaults.synchronize()
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
          }
        }
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
