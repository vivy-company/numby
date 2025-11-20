#if os(iOS)
import UIKit

class iOSAppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Numby configuration
        Configuration.shared.load()

        // Create window manually (no SceneDelegate)
        window = UIWindow(frame: UIScreen.main.bounds)

        // Create main tab bar controller
        let tabBarController = UITabBarController()

        // Calculator tab
        let calculatorVC = CalculatorViewController()
        calculatorVC.tabBarItem = UITabBarItem(
            title: "Calculator",
            image: UIImage(systemName: "function"),
            tag: 0
        )
        let calculatorNav = UINavigationController(rootViewController: calculatorVC)

        // History tab
        let historyVC = HistoryViewController()
        historyVC.tabBarItem = UITabBarItem(
            title: "History",
            image: UIImage(systemName: "clock"),
            tag: 1
        )
        let historyNav = UINavigationController(rootViewController: historyVC)

        // Settings tab
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            tag: 2
        )
        let settingsNav = UINavigationController(rootViewController: settingsVC)

        tabBarController.viewControllers = [calculatorNav, historyNav, settingsNav]

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Persistence.shared.save()
    }
}
#endif
