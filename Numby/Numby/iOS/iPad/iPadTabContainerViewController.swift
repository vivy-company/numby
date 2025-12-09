#if os(iOS) || os(visionOS)
import UIKit

class iPadTabContainerViewController: UIViewController, iPadTabBarDelegate {

    private var tabs: [CalculatorTab] = []
    private var selectedTabIndex: Int = 0
    private var tabBarHeightConstraint: NSLayoutConstraint?

    private let tabBarHeight: CGFloat = 40

    // Tab bar goes BELOW the navigation bar
    private let tabBar: iPadTabBar = {
        let bar = iPadTabBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.alpha = 0
        return bar
    }()

    // Container for split view content
    private let contentContainer = UIView()

    // Current split container for the selected tab
    private var currentSplitContainer: iPadSplitContainerViewController?

    // Navigation controller with toolbar
    private var navController: UINavigationController?
    private var contentVC: UIViewController?

    // Split button in bottom left corner
    private lazy var splitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        btn.setImage(UIImage(systemName: "rectangle.split.2x1", withConfiguration: config), for: .normal)
        btn.tintColor = Theme.current.textColor.withAlphaComponent(0.4)
        btn.showsMenuAsPrimaryAction = true
        btn.menu = createSplitMenu()
        return btn
    }()

    private func createSplitMenu() -> UIMenu {
        UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("split.horizontal", comment: "Split Horizontally"), image: UIImage(systemName: "rectangle.split.1x2")) { [weak self] _ in
                self?.splitCurrentPane(direction: .vertical)
            },
            UIAction(title: NSLocalizedString("split.vertical", comment: "Split Vertically"), image: UIImage(systemName: "rectangle.split.2x1")) { [weak self] _ in
                self?.splitCurrentPane(direction: .horizontal)
            }
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createInitialTab()

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: NSNotification.Name("ThemeDidChange"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard Shortcuts

    override var keyCommands: [UIKeyCommand]? {
        return [
            // Cmd+T: New Tab
            UIKeyCommand(title: NSLocalizedString("menu.newTab", comment: ""),
                        action: #selector(newTabButtonTapped),
                        input: "t",
                        modifierFlags: .command),
            // Cmd+D: Split Vertically (side by side)
            UIKeyCommand(title: NSLocalizedString("split.vertical", comment: ""),
                        action: #selector(splitVerticalShortcut),
                        input: "d",
                        modifierFlags: .command),
            // Cmd+Shift+D: Split Horizontally (top/bottom)
            UIKeyCommand(title: NSLocalizedString("split.horizontal", comment: ""),
                        action: #selector(splitHorizontalShortcut),
                        input: "d",
                        modifierFlags: [.command, .shift]),
            // Cmd+W: Close current pane (if multiple) or tab
            UIKeyCommand(title: NSLocalizedString("menu.close", comment: ""),
                        action: #selector(closeCurrentShortcut),
                        input: "w",
                        modifierFlags: .command),
        ]
    }

    @objc private func splitVerticalShortcut() {
        splitCurrentPane(direction: .horizontal)
    }

    @objc private func splitHorizontalShortcut() {
        splitCurrentPane(direction: .vertical)
    }

    @objc private func closeCurrentShortcut() {
        guard selectedTabIndex < tabs.count else { return }
        let tab = tabs[selectedTabIndex]

        // If multiple panes, close current pane
        if tab.controller.leafCount > 1 {
            currentSplitContainer?.saveAllCalculatorStates()
            tab.controller.closeCurrentLeaf()
        } else if tabs.count > 1 {
            // Otherwise close the tab if multiple tabs
            closeTab(at: selectedTabIndex)
        }
    }

    private func setupUI() {
        view.backgroundColor = Theme.current.backgroundColor
        overrideUserInterfaceStyle = .dark

        setupContentVC()

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

        // Add split button to bottom left corner
        view.addSubview(splitButton)
        NSLayoutConstraint.activate([
            splitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            splitButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            splitButton.widthAnchor.constraint(equalToConstant: 32),
            splitButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        updateContentInset(animated: false)
    }

    private func setupContentVC() {
        // Create a content view controller that will contain split views
        let vc = UIViewController()
        vc.view.backgroundColor = Theme.current.backgroundColor

        // Content container fills the view
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(contentContainer)
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])

        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = false
        nav.overrideUserInterfaceStyle = .dark

        updateNavBarAppearance(nav)

        addChild(nav)
        view.addSubview(nav.view)
        nav.didMove(toParent: self)

        self.navController = nav
        self.contentVC = vc

        // Setup navigation bar items
        setupNavigationItems()
    }

    private func setupNavigationItems() {
        contentVC?.title = "Numby"

        // Left side: Settings, History
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        let historyButton = UIBarButtonItem(
            image: UIImage(systemName: "clock"),
            style: .plain,
            target: self,
            action: #selector(openHistory)
        )
        contentVC?.navigationItem.leftBarButtonItems = [settingsButton, historyButton]

        // Right side: Share, New Tab (order is right-to-left)
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareResult)
        )

        let newTabButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(newTabButtonTapped)
        )

        contentVC?.navigationItem.rightBarButtonItems = [shareButton, newTabButton]
    }

    @objc private func newTabButtonTapped() {
        createNewTab()
    }

    @objc private func openSettings() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    @objc private func openHistory() {
        let historyVC = HistoryViewController()
        let navController = UINavigationController(rootViewController: historyVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    @objc private func shareResult() {
        guard selectedTabIndex < tabs.count else { return }
        currentSplitContainer?.saveAllCalculatorStates()

        let tab = tabs[selectedTabIndex]
        guard let focusedId = tab.controller.focusedLeafId,
              let instance = tab.controller.calculators[focusedId] else { return }

        let text = instance.inputText
        let results = instance.results
        guard !text.isEmpty else { return }

        let lines = text.components(separatedBy: "\n")
        var imageLines: [(expression: String, result: String)] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && index < results.count && !results[index].isEmpty {
                imageLines.append((expression: trimmed, result: results[index]))
            }
        }

        guard !imageLines.isEmpty else { return }

        let alert = UIAlertController(title: NSLocalizedString("share.title", comment: "Share"), message: nil, preferredStyle: .actionSheet)

        // Copy as Text
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyText", comment: "Copy as Text"), style: .default) { [weak self] _ in
            let shareText = ShareURLGenerator.generateText(lines: imageLines)
            UIPasteboard.general.string = shareText
            self?.showCopiedFeedback()
        })

        // Copy as Image
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyImage", comment: "Copy as Image"), style: .default) { [weak self] _ in
            let config = Configuration.shared.config
            if let image = CalculatorImageRenderer.render(
                lines: imageLines,
                theme: Theme.current,
                fontSize: config.fontSize,
                fontName: config.fontName ?? "Menlo-Regular"
            ) {
                UIPasteboard.general.image = image
                self?.showCopiedFeedback()
            }
        })

        // Copy as Link
        alert.addAction(UIAlertAction(title: NSLocalizedString("share.copyLink", comment: "Copy as Link"), style: .default) { [weak self] _ in
            let url = ShareURLGenerator.generate(lines: imageLines, theme: Theme.current.name)
            UIPasteboard.general.string = url.absoluteString
            self?.showCopiedFeedback()
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("nav.cancel", comment: "Cancel"), style: .cancel))

        // iPad popover
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = contentVC?.navigationItem.rightBarButtonItems?.first
        }

        present(alert, animated: true)
    }

    private func showCopiedFeedback() {
        let label = UILabel()
        label.text = NSLocalizedString("share.copied", comment: "Copied!")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            label.widthAnchor.constraint(equalToConstant: 100),
            label.heightAnchor.constraint(equalToConstant: 36)
        ])

        label.alpha = 0
        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 1.0) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }

    private func updateContentInset(animated: Bool) {
        let showTabBar = tabs.count > 1
        let topInset: CGFloat = showTabBar ? tabBarHeight : 0

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.contentVC?.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            }
        } else {
            contentVC?.additionalSafeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        }
    }

    // MARK: - Split Actions

    private func splitCurrentPane(direction: SplitDirection) {
        guard selectedTabIndex < tabs.count else { return }
        let tab = tabs[selectedTabIndex]
        currentSplitContainer?.saveAllCalculatorStates()
        tab.controller.splitCurrentLeaf(direction: direction)
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
        loadTabState(tab)
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
        loadTabState(tab)
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
            }

            updateContentInset(animated: true)
        } else {
            tabBar.transform = .identity
            tabBar.alpha = 1
            updateContentInset(animated: false)
        }
    }

    private func hideTabBar(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
                self.tabBar.transform = CGAffineTransform(translationX: 0, y: -self.tabBarHeight)
                self.tabBar.alpha = 0
            } completion: { _ in
                self.tabBarHeightConstraint?.constant = 0
            }

            updateContentInset(animated: true)
        } else {
            tabBarHeightConstraint?.constant = 0
            tabBar.alpha = 0
            updateContentInset(animated: false)
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

        // Save content to history before closing
        let closingTab = tabs[index]
        currentSplitContainer?.saveAllCalculatorStates()
        let snapshot = closingTab.createSnapshot()
        let searchableText = closingTab.searchableText()
        if !searchableText.isEmpty {
            Persistence.shared.saveSession(snapshot: snapshot, searchableText: searchableText)
        }

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
        currentSplitContainer?.saveAllCalculatorStates()
    }

    private func loadTabState(_ tab: CalculatorTab) {
        guard let contentVC = contentVC else { return }

        // Remove old split container
        if let oldContainer = currentSplitContainer {
            oldContainer.willMove(toParent: nil)
            oldContainer.view.removeFromSuperview()
            oldContainer.removeFromParent()
        }

        // Create new split container for this tab
        let splitContainer = iPadSplitContainerViewController(controller: tab.controller)
        splitContainer.view.translatesAutoresizingMaskIntoConstraints = false

        // Add as child of contentVC (not self) to match view hierarchy
        contentVC.addChild(splitContainer)
        contentContainer.addSubview(splitContainer.view)
        NSLayoutConstraint.activate([
            splitContainer.view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            splitContainer.view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            splitContainer.view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            splitContainer.view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
        splitContainer.didMove(toParent: contentVC)

        currentSplitContainer = splitContainer
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
        splitButton.tintColor = theme.textColor.withAlphaComponent(0.5)
        if let nav = navController {
            updateNavBarAppearance(nav)
        }
    }

    // MARK: - Save to History

    func saveCurrentTabToHistory() {
        guard selectedTabIndex < tabs.count else { return }
        currentSplitContainer?.saveAllCalculatorStates()

        let tab = tabs[selectedTabIndex]
        let snapshot = tab.createSnapshot()
        let searchableText = tab.searchableText()

        // Only save if there's actual content
        guard !searchableText.isEmpty else { return }

        Persistence.shared.saveSession(snapshot: snapshot, searchableText: searchableText)
    }
}
#endif
