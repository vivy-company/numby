#if os(iOS) || os(visionOS)
import UIKit

/// Protocol for calculator pane delegate
protocol iPadCalculatorPaneDelegate: AnyObject {
    func paneTapped(leafId: SplitLeafID)
    func paneRequestsSplit(leafId: SplitLeafID, direction: SplitDirection)
    func paneRequestsClose(leafId: SplitLeafID)
}

/// Root view controller that renders the split tree recursively
class iPadSplitContainerViewController: UIViewController {

    // MARK: - Properties

    let controller: iPadCalculatorController
    private var rootView: UIView?
    private var calculatorVCs: [SplitLeafID: CalculatorViewController] = [:]

    weak var delegate: iPadCalculatorPaneDelegate?

    // MARK: - Initialization

    private var pendingFocusLeafId: SplitLeafID?
    private var isRebuilding = false

    init(controller: iPadCalculatorController) {
        self.controller = controller
        super.init(nibName: nil, bundle: nil)

        controller.onSplitTreeChanged = { [weak self] in
            // Store the focused leaf ID before rebuild
            self?.pendingFocusLeafId = controller.focusedLeafId
            self?.rebuildViewHierarchy()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.current.backgroundColor
        rebuildViewHierarchy()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChange"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Hierarchy

    func rebuildViewHierarchy() {
        isRebuilding = true

        // Remove old hierarchy
        rootView?.removeFromSuperview()
        for (_, vc) in calculatorVCs {
            vc.willMove(toParent: nil)
            vc.removeFromParent()
        }
        calculatorVCs.removeAll()

        // Build new hierarchy
        guard let root = controller.splitTree.root else {
            isRebuilding = false
            return
        }

        let newRootView = buildView(for: root)
        newRootView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newRootView)

        NSLayoutConstraint.activate([
            newRootView.topAnchor.constraint(equalTo: view.topAnchor),
            newRootView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newRootView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newRootView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        rootView = newRootView

        // Focus the pending leaf after rebuild completes
        if let focusId = pendingFocusLeafId {
            pendingFocusLeafId = nil
            // Keep isRebuilding true until focus is applied to prevent interference
            DispatchQueue.main.async { [weak self] in
                self?.focusCalculator(leafId: focusId)
                self?.isRebuilding = false
            }
        } else {
            isRebuilding = false
        }
    }

    private func buildView(for node: SplitTree.Node) -> UIView {
        switch node {
        case .leaf(let leafId):
            return buildCalculatorPane(for: leafId)

        case .split(let direction, let ratio, let left, let right):
            let splitView = iPadSplitView(direction: direction, ratio: ratio)
            splitView.translatesAutoresizingMaskIntoConstraints = false

            let leftView = buildView(for: left)
            let rightView = buildView(for: right)

            splitView.setLeftView(leftView)
            splitView.setRightView(rightView)

            // Get leaf IDs for ratio update callback
            let leftLeafId = getFirstLeafId(from: left)
            splitView.onRatioChange = { [weak self] newRatio in
                if let leafId = leftLeafId {
                    self?.controller.updateRatio(leafId, newRatio: newRatio)
                }
            }

            return splitView
        }
    }

    private func buildCalculatorPane(for leafId: SplitLeafID) -> UIView {
        guard let instance = controller.calculators[leafId] else {
            let errorView = UIView()
            errorView.backgroundColor = .systemRed
            return errorView
        }

        // Create calculator view controller
        let calcVC = CalculatorViewController()
        calcVC.leafId = leafId
        calcVC.splitContainerDelegate = self

        // Restore state from instance
        calcVC.restoreFromInstance(instance)

        // Add as child
        addChild(calcVC)
        calcVC.didMove(toParent: self)
        calculatorVCs[leafId] = calcVC

        // Container with close button if multiple panes
        let container = UIView()
        container.addSubview(calcVC.view)
        calcVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            calcVC.view.topAnchor.constraint(equalTo: container.topAnchor),
            calcVC.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            calcVC.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            calcVC.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Add close button if multiple panes
        if controller.leafCount > 1 {
            let closeButton = UIButton(type: .system)
            closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            closeButton.tintColor = Theme.current.textColor.withAlphaComponent(0.5)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.tag = leafId.uuid.hashValue
            closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
            container.addSubview(closeButton)

            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
                closeButton.widthAnchor.constraint(equalToConstant: 24),
                closeButton.heightAnchor.constraint(equalToConstant: 24)
            ])

            // Store leafId for later lookup
            closeButton.accessibilityIdentifier = leafId.uuid.uuidString
        }

        return container
    }

    private func getFirstLeafId(from node: SplitTree.Node) -> SplitLeafID? {
        switch node {
        case .leaf(let id):
            return id
        case .split(_, _, let left, _):
            return getFirstLeafId(from: left)
        }
    }

    // MARK: - Actions

    @objc private func closeButtonTapped(_ sender: UIButton) {
        guard let uuidString = sender.accessibilityIdentifier,
              let uuid = UUID(uuidString: uuidString) else { return }

        let leafId = SplitLeafID(uuid: uuid)
        saveCalculatorState(for: leafId)
        controller.closeLeaf(leafId)
    }

    // MARK: - State Management

    func saveAllCalculatorStates() {
        for (leafId, vc) in calculatorVCs {
            if let instance = controller.calculators[leafId] {
                vc.saveToInstance(instance)
            }
        }
    }

    func saveCalculatorState(for leafId: SplitLeafID) {
        if let vc = calculatorVCs[leafId],
           let instance = controller.calculators[leafId] {
            vc.saveToInstance(instance)
        }
    }

    func focusCalculator(leafId: SplitLeafID) {
        calculatorVCs[leafId]?.focus()
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        view.backgroundColor = Theme.current.backgroundColor
        updateSplitViewThemes(rootView)
    }

    private func updateSplitViewThemes(_ view: UIView?) {
        guard let view = view else { return }
        if let splitView = view as? iPadSplitView {
            splitView.updateTheme()
        }
        for subview in view.subviews {
            updateSplitViewThemes(subview)
        }
    }
}

// MARK: - iPadCalculatorPaneDelegate

extension iPadSplitContainerViewController: iPadCalculatorPaneDelegate {
    func paneTapped(leafId: SplitLeafID) {
        // Ignore focus changes during rebuild (restoreFromInstance triggers selection changes)
        guard !isRebuilding else { return }

        // Save state of previously focused pane before switching
        if let previousFocusId = controller.focusedLeafId, previousFocusId != leafId {
            saveCalculatorState(for: previousFocusId)
        }
        controller.setFocus(leafId)
    }

    func paneRequestsSplit(leafId: SplitLeafID, direction: SplitDirection) {
        saveCalculatorState(for: leafId)
        controller.splitLeaf(leafId, direction: direction)
    }

    func paneRequestsClose(leafId: SplitLeafID) {
        saveCalculatorState(for: leafId)
        controller.closeLeaf(leafId)
    }
}
#endif
