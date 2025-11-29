#if os(iOS) || os(visionOS)
import UIKit

class SearchablePickerViewController: UIViewController {

    // MARK: - Properties

    private var items: [String]
    private var filteredItems: [String]
    private let pickerTitle: String
    private let selectedItem: String?
    private let onSelect: (String) -> Void

    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search..."
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "PickerCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        #if !os(visionOS)
        table.keyboardDismissMode = .onDrag
        #endif
        table.estimatedRowHeight = 44
        table.rowHeight = UITableView.automaticDimension
        return table
    }()

    // MARK: - Initialization

    init(title: String, items: [String], selectedItem: String?, onSelect: @escaping (String) -> Void) {
        self.pickerTitle = title
        self.items = items
        self.filteredItems = items
        self.selectedItem = selectedItem
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        overrideUserInterfaceStyle = .dark
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateTheme()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChange"),
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        self.title = self.pickerTitle

        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissPicker)
        )
    }

    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    // MARK: - Theme

    @objc private func themeDidChange() {
        updateTheme()
    }

    private func updateTheme() {
        let darkBg = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1) // iOS dark mode background
        let darkSecondary = UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)

        view.backgroundColor = darkBg
        tableView.backgroundColor = darkBg
        searchBar.barTintColor = darkBg
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .systemBlue
        searchBar.searchTextField.backgroundColor = darkSecondary
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.tintColor = .systemBlue

        // Force navigation bar dark
        navigationController?.navigationBar.barTintColor = darkBg
        navigationController?.navigationBar.backgroundColor = darkBg
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SearchablePickerViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath)
        let item = filteredItems[indexPath.row]

        cell.textLabel?.text = item
        cell.accessoryType = (item == selectedItem) ? .checkmark : .none
        cell.tintColor = .systemBlue

        // Hardcoded dark colors
        let darkBg = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
        let darkSelected = UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1)
        cell.backgroundColor = darkBg
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = darkSelected
        cell.textLabel?.textColor = .white

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = filteredItems[indexPath.row]
        onSelect(selectedItem)
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension SearchablePickerViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { item in
                item.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
#endif
