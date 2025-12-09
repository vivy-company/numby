#if os(iOS) || os(visionOS)
import UIKit

protocol iPadTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: iPadTabBar, didSelectTabAt index: Int)
    func tabBar(_ tabBar: iPadTabBar, didCloseTabAt index: Int)
}

class iPadTabBar: UIView {

    weak var delegate: iPadTabBarDelegate?

    private var tabButtons: [iPadTabButton] = []
    private(set) var selectedIndex: Int = 0

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // No background - transparent
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = true

        addSubview(stackView)
        stackView.isUserInteractionEnabled = true

        // Use lower priority for vertical constraints to avoid conflicts when height is 0
        let topConstraint = stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
        let bottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            topConstraint,
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            bottomConstraint
        ])
    }

    func updateTabs(names: [String], selectedIndex: Int, animated: Bool = true) {
        let oldSelectedIndex = self.selectedIndex
        self.selectedIndex = selectedIndex

        // If same count, just update selection with animation
        if tabButtons.count == names.count {
            for (index, button) in tabButtons.enumerated() {
                let isSelected = index == selectedIndex
                let wasSelected = index == oldSelectedIndex

                if isSelected != wasSelected {
                    if animated {
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
                            button.setSelected(isSelected)
                        }
                    } else {
                        button.setSelected(isSelected)
                    }
                }
            }
            return
        }

        // Rebuild tabs if count changed
        tabButtons.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()

        for (index, name) in names.enumerated() {
            let button = iPadTabButton()
            button.configure(title: name, isSelected: index == selectedIndex, canClose: names.count > 1)
            button.tag = index
            button.onTap = { [weak self] in
                guard let self = self else { return }
                self.delegate?.tabBar(self, didSelectTabAt: index)
            }
            button.onClose = { [weak self] in
                guard let self = self else { return }
                self.delegate?.tabBar(self, didCloseTabAt: index)
            }

            // Animate new tab appearance
            if animated && index == names.count - 1 && names.count > 1 {
                button.alpha = 0
                button.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }

            stackView.addArrangedSubview(button)
            tabButtons.append(button)
        }

        // Animate new tab in
        if animated && names.count > 1 {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                self.tabButtons.last?.alpha = 1
                self.tabButtons.last?.transform = .identity
            }
        }
    }

    func updateTheme() {
        backgroundColor = .clear
        tabButtons.forEach { $0.updateTheme() }
    }
}

// MARK: - Tab Button (Pill-shaped like Safari)

class iPadTabButton: UIControl {

    var onTap: (() -> Void)?
    var onClose: (() -> Void)?

    private var isSelectedTab = false
    private var canClose = true

    // Background pill - only visible when selected
    private let pillBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        btn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Transparent background for the button itself
        backgroundColor = .clear

        addSubview(pillBackground)
        addSubview(closeButton)
        addSubview(titleLabel)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        addTarget(self, action: #selector(tabTapped), for: .touchUpInside)

        #if os(visionOS)
        // Enable hover effect on visionOS for better interactivity feedback
        hoverStyle = UIHoverStyle(shape: .capsule)
        #endif

        NSLayoutConstraint.activate([
            // Pill background fills the button
            pillBackground.topAnchor.constraint(equalTo: topAnchor),
            pillBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            pillBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            pillBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Close button on LEFT
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 18),
            closeButton.heightAnchor.constraint(equalToConstant: 18),

            // Title centered
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(title: String, isSelected: Bool, canClose: Bool) {
        titleLabel.text = title
        self.isSelectedTab = isSelected
        self.canClose = canClose
        closeButton.isHidden = !canClose
        updateTheme()
    }

    func setSelected(_ selected: Bool) {
        isSelectedTab = selected
        updateTheme()
    }

    func updateTheme() {
        let theme = Theme.current

        if isSelectedTab {
            // Selected: show pill background
            pillBackground.backgroundColor = theme.textColor.withAlphaComponent(0.15)
            titleLabel.textColor = theme.textColor
            closeButton.tintColor = theme.textColor.withAlphaComponent(0.6)
        } else {
            // Not selected: subtle background so it looks tappable
            pillBackground.backgroundColor = theme.textColor.withAlphaComponent(0.05)
            titleLabel.textColor = theme.textColor.withAlphaComponent(0.6)
            closeButton.tintColor = theme.textColor.withAlphaComponent(0.4)
        }
    }

    @objc private func tabTapped() {
        onTap?()
    }

    @objc private func closeTapped() {
        onClose?()
    }
}
#endif
