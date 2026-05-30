import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Реєструємо фонові задачі для workmanager (iOS BGTaskScheduler)
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.viti.gradebook.gradesCheck"
    )
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.viti.gradebook.journalsReminder"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
