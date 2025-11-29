#if os(iOS) || os(visionOS)
import UIKit

class iPadTabContainerViewController: UIViewController, iPadTabBarDelegate {

    private var tabs: [CalculatorTab] = []
    private var selectedTabIndex: Int = 0
    private var tabBarHeightConstraint: NSLayoutConstraint?
    private var calculatorTopInsetConstraint: NSLayoutConstraint?

    private let tabBarHeight: CGFloat = 40

    // Tab bar goes BELOW the navigation bar
    private let tabBar: iPadTabBar = {
        let bar = iPadTabBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.alpha = 0
        return bar
    }()

    private var navController: UINavigationController?
    private var calculatorVC: CalculatorViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createInitialTab()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name("ThemeDidChange"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = Theme.current.backgroundColor
        overrideUserInterfaceStyle = .dark

        setupCalculatorVC()

        guard let nav = navController else { return }

        nav.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nav.view.topAnchor.constraint(equalTo: view.topAnchor),
            nav.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nav.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add tab bar to main view, on top of navigation controller
        view.addSubview(tabBar)
        tabBar.delegate = self
        tabBar.isUserInteractionEnabled = true

        let heightConstraint = tabBar.heightAnchor.constraint(equalToConstant: 0)
        tabBarHeightConstraint = heightConstraint

        // Position tab bar below the navigation bar
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: nav.navigationBar.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightConstraint
        ])

        updateCalculatorInset(animated: false)
    }

    private func setupCalculatorVC() {
        let calcVC = CalculatorViewController()
        calcVC.tabContainer = self

        let nav = UINavigationController(rootViewController: calcVC)
        nav.navigationBar.prefersLargeTitles = false
        nav.overrideUserInterfaceStyle = .dark

        updateNavBarAppearance(nav)

        addChild(nav)
        view.addSubview(nav.view)
        nav.didMove(toParent: self)

        self.navController = nav
        self.calculatorVC = calcVC
    }

    private func updateCalculatorInset(animated: Bool) {
        let showTabBar = tabs.count > 1
        let topInset: CGFloat = showTabBar ? tabBarHeight : 0

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.calculatorVC?.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
                self.view.layoutIfNeeded()
            }
        } else {
            calculatorVC?.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        }
    }

    private func updateNavBarAppearance(_ nav: UINavigationController) {
        let theme = Theme.current
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.backgroundColor
        appearance.titleTextAttributes = [.foregroundColor: theme.textColor]
        appearance.shadowColor = .clear
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = theme.textColor
    }

    private func createInitialTab() {
        let tab = CalculatorTab()
        tabs.append(tab)
        selectedTabIndex = 0
        updateTabBar(animated: false)
        calculatorVC?.title = "Numby"
    }

    // MARK: - Public API

    func createNewTab() {
        saveCurrentTabState()

        let wasShowingTabs = tabs.count > 1
        let tab = CalculatorTab()
        tabs.append(tab)
        selectedTabIndex = tabs.count - 1

        // Show tab bar with animation if this is the second tab
        if !wasShowingTabs {
            showTabBar(animated: true)
        }

        updateTabBar(animated: true)
        loadTabState(tabs[selectedTabIndex])
    }

    // MARK: - Tab Bar Visibility

    private func showTabBar(animated: Bool) {
        tabBarHeightConstraint?.constant = tabBarHeight
        view.bringSubviewToFront(tabBar)

        if animated {
            tabBar.transform = CGAffineTransform(translationX: 0, y: -tabBarHeight)
            tabBar.alpha = 0

            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.tabBar.transform = .identity
                self.tabBar.alpha = 1
                self.view.layoutIfNeeded()
            }

            updateCalculatorInset(animated: true)
        } else {
            tabBar.transform = .identity
            tabBar.alpha = 1
            view.layoutIfNeeded()
            updateCalculatorInset(animated: false)
        }
    }

    private func hideTabBar(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                self.tabBar.transform = CGAffineTransform(translationX: 0, y: -self.tabBarHeight)
                self.tabBar.alpha = 0
            } completion: { _ in
                self.tabBarHeightConstraint?.constant = 0
                self.view.layoutIfNeeded()
            }

            updateCalculatorInset(animated: true)
        } else {
            tabBarHeightConstraint?.constant = 0
            tabBar.alpha = 0
            view.layoutIfNeeded()
            updateCalculatorInset(animated: false)
        }
    }

    // MARK: - Tab Management

    private func selectTab(at index: Int) {
        guard index != selectedTabIndex, index >= 0, index < tabs.count else { return }

        saveCurrentTabState()
        selectedTabIndex = index
        updateTabBar(animated: true)
        loadTabState(tabs[selectedTabIndex])
    }

    private func closeTab(at index: Int) {
        guard tabs.count > 1 else { return }

        let wasShowingTabs = tabs.count > 1
        tabs.remove(at: index)

        if selectedTabIndex >= tabs.count {
            selectedTabIndex = tabs.count - 1
        } else if index < selectedTabIndex {
            selectedTabIndex -= 1
        } else if index == selectedTabIndex {
            selectedTabIndex = min(selectedTabIndex, tabs.count - 1)
            loadTabState(tabs[selectedTabIndex])
        }

        // Hide tab bar with animation if going back to 1 tab
        if wasShowingTabs && tabs.count == 1 {
            hideTabBar(animated: true)
        }

        updateTabBar(animated: true)
    }

    private func saveCurrentTabState() {
        guard selectedTabIndex < tabs.count else { return }
        calculatorVC?.saveState(to: tabs[selectedTabIndex])
    }

    private func loadTabState(_ tab: CalculatorTab) {
        calculatorVC?.restoreState(from: tab)
        // Always show "Numby" in toolbar, tab name is in tab bar
        calculatorVC?.title = "Numby"
    }

    private func updateTabBar(animated: Bool) {
        let names = tabs.map { $0.name }

        // Only update tab bar content if we have more than 1 tab
        if tabs.count > 1 {
            tabBar.updateTabs(names: names, selectedIndex: selectedTabIndex, animated: animated)
        }
    }

    // MARK: - iPadTabBarDelegate

    func tabBar(_ tabBar: iPadTabBar, didSelectTabAt index: Int) {
        selectTab(at: index)
    }

    func tabBar(_ tabBar: iPadTabBar, didCloseTabAt index: Int) {
        closeTab(at: index)
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        let theme = Theme.current
        view.backgroundColor = theme.backgroundColor
        tabBar.updateTheme()
        if let nav = navController {
            updateNavBarAppearance(nav)
        }
    }
}
#endif
