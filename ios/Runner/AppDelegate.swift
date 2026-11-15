import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let encoded = (Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String),
       let value = encoded.split(separator: ",").compactMap({ Data(base64Encoded: String($0)) })
         .compactMap({ String(data: $0, encoding: .utf8) })
         .first(where: { $0.hasPrefix("GOOGLE_MAPS_API_KEY=") }) {
      GMSServices.provideAPIKey(String(value.dropFirst("GOOGLE_MAPS_API_KEY=".count)))
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
