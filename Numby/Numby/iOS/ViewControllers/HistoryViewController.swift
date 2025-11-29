#if os(iOS) || os(visionOS)
import UIKit

class HistoryViewController: UIViewController {

    // MARK: - Properties

    private var historyEntries: [(expression: String, result: String)] = []

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var clearButton: UIBarButtonItem = {
        return UIBarButtonItem(
            title: NSLocalizedString("nav.clear", comment: ""),
            style: .plain,
            target: self,
            action: #selector(clearHistory)
        )
    }()

    private lazy var closeButton: UIBarButtonItem = {
        return UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissHistory)
        )
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("history.title", comment: "")
        setupUI()
        loadHistory()
        updateTheme()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyDidUpdate),
            name: NSNotification.Name("HistoryDidUpdate"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChange"),
            object: nil
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Respond to system dark mode changes
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTheme()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistory()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = clearButton

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Support multi-line cells for full expression/result display
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60.0
    }

    // MARK: - Data

    private func loadHistory() {
        historyEntries = Persistence.shared.getHistory()
        tableView.reloadData()
    }

    @objc private func dismissHistory() {
        dismiss(animated: true)
    }

    @objc private func clearHistory() {
        let alert = UIAlertController(
            title: NSLocalizedString("history.clearTitle", comment: ""),
            message: NSLocalizedString("history.clearMessage", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("alert.cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("nav.clear", comment: ""), style: .destructive) { [weak self] _ in
            Persistence.shared.clearHistory()
            self?.loadHistory()
        })

        present(alert, animated: true)
    }

    @objc private func historyDidUpdate() {
        loadHistory()
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
    }

    private func updateTheme() {
        // Always use dark mode
        overrideUserInterfaceStyle = .dark

        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemGroupedBackground
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let entry = historyEntries[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = entry.expression
        config.textProperties.numberOfLines = 0
        config.secondaryText = "= \(entry.result)"
        config.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = config

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = historyEntries[indexPath.row]

        // Load the note back to calculator input
        NotificationCenter.default.post(
            name: NSNotification.Name("LoadHistoryEntry"),
            object: nil,
            userInfo: ["expression": entry.expression]
        )

        // Dismiss history to return to calculator
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            historyEntries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveHistory()
        }
    }

    private func saveHistory() {
        // Rebuild history in Persistence by clearing and re-adding
        Persistence.shared.clearHistory()
        for entry in historyEntries {
            Persistence.shared.addHistoryEntry(expression: entry.expression, result: entry.result)
        }
    }
}
#endif
