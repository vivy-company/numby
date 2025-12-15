#if os(iOS) || os(visionOS)
import UIKit

class iOSAppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Numby configuration
        Configuration.shared.load()

        // Trigger currency rates update on app launch
        triggerCurrencyUpdate()

        return true
    }

    private func triggerCurrencyUpdate() {
        // Create a NumbyWrapper instance to trigger currency update
        let numbyWrapper = NumbyWrapper()
        _ = numbyWrapper.updateCurrencyRates() // Always update on app launch
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Persistence.shared.save()
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = iOSSceneDelegate.self
        return config
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session
    }
}
#endif // os(iOS) || os(visionOS)
