#if os(iOS) || os(visionOS)
import UIKit

class iOSSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let idiom = UIDevice.current.userInterfaceIdiom
        #if os(visionOS)
        // visionOS: Use iPad-style tab container
        window.rootViewController = iPadTabContainerViewController()
        #else
        if idiom == .pad {
            // iPad: Use tab container with Safari-style tabs
            window.rootViewController = iPadTabContainerViewController()
        } else {
            // iPhone: Single calculator with navigation
            let calculatorVC = CalculatorViewController()
            let navController = UINavigationController(rootViewController: calculatorVC)
            navController.navigationBar.prefersLargeTitles = false
            navController.overrideUserInterfaceStyle = .dark

            let theme = Theme.current
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = theme.backgroundColor
            appearance.titleTextAttributes = [.foregroundColor: theme.textColor]
            appearance.shadowColor = .clear
            navController.navigationBar.standardAppearance = appearance
            navController.navigationBar.scrollEdgeAppearance = appearance
            navController.navigationBar.tintColor = theme.textColor

            window.rootViewController = navController
        }
        #endif

        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()

        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        Persistence.shared.save()
    }
}
#endif // os(iOS) || os(visionOS)
