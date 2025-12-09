#if os(iOS) || os(visionOS)
import UIKit

/// A split view container that renders two child views with a draggable divider
class iPadSplitView: UIView {

    // MARK: - Properties

    let direction: SplitDirection
    private(set) var ratio: Float
    var onRatioChange: ((Float) -> Void)?

    private let leftContainer = UIView()
    private let rightContainer = UIView()
    private let divider = UIView()

    private var leftView: UIView?
    private var rightView: UIView?

    private let dividerThickness: CGFloat = 1
    private let dividerHitArea: CGFloat = 20
    private let minRatio: Float = 0.15
    private let maxRatio: Float = 0.85

    // Constraints that change with ratio
    private var leftWidthConstraint: NSLayoutConstraint?
    private var leftHeightConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    init(direction: SplitDirection, ratio: Float = 0.5) {
        self.direction = direction
        self.ratio = max(minRatio, min(maxRatio, ratio))
        super.init(frame: .zero)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        addSubview(leftContainer)
        addSubview(rightContainer)
        addSubview(divider)

        divider.backgroundColor = Theme.current.textColor.withAlphaComponent(0.15)

        setupConstraints()
    }

    private func setupConstraints() {
        switch direction {
        case .horizontal:
            // Left | Right (side by side)
            NSLayoutConstraint.activate([
                leftContainer.topAnchor.constraint(equalTo: topAnchor),
                leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                leftContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

                divider.topAnchor.constraint(equalTo: topAnchor),
                divider.bottomAnchor.constraint(equalTo: bottomAnchor),
                divider.leadingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
                divider.widthAnchor.constraint(equalToConstant: dividerThickness),

                rightContainer.topAnchor.constraint(equalTo: topAnchor),
                rightContainer.leadingAnchor.constraint(equalTo: divider.trailingAnchor),
                rightContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                rightContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            // Width constraint that changes with ratio
            leftWidthConstraint = leftContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(ratio))
            leftWidthConstraint?.isActive = true

        case .vertical:
            // Top / Bottom (stacked)
            NSLayoutConstraint.activate([
                leftContainer.topAnchor.constraint(equalTo: topAnchor),
                leftContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                leftContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

                divider.leadingAnchor.constraint(equalTo: leadingAnchor),
                divider.trailingAnchor.constraint(equalTo: trailingAnchor),
                divider.topAnchor.constraint(equalTo: leftContainer.bottomAnchor),
                divider.heightAnchor.constraint(equalToConstant: dividerThickness),

                rightContainer.topAnchor.constraint(equalTo: divider.bottomAnchor),
                rightContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
                rightContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
                rightContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])

            // Height constraint that changes with ratio
            leftHeightConstraint = leftContainer.heightAnchor.constraint(equalTo: heightAnchor, multiplier: CGFloat(ratio))
            leftHeightConstraint?.isActive = true
        }
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        divider.addGestureRecognizer(panGesture)
        divider.isUserInteractionEnabled = true

        // Expand hit area for divider
        let hitAreaView = UIView()
        hitAreaView.translatesAutoresizingMaskIntoConstraints = false
        hitAreaView.backgroundColor = .clear
        addSubview(hitAreaView)

        switch direction {
        case .horizontal:
            NSLayoutConstraint.activate([
                hitAreaView.centerXAnchor.constraint(equalTo: divider.centerXAnchor),
                hitAreaView.topAnchor.constraint(equalTo: topAnchor),
                hitAreaView.bottomAnchor.constraint(equalTo: bottomAnchor),
                hitAreaView.widthAnchor.constraint(equalToConstant: dividerHitArea)
            ])
        case .vertical:
            NSLayoutConstraint.activate([
                hitAreaView.centerYAnchor.constraint(equalTo: divider.centerYAnchor),
                hitAreaView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hitAreaView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hitAreaView.heightAnchor.constraint(equalToConstant: dividerHitArea)
            ])
        }

        let hitAreaPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        hitAreaView.addGestureRecognizer(hitAreaPanGesture)
        hitAreaView.isUserInteractionEnabled = true
    }

    // MARK: - Gesture Handling

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let totalSize: CGFloat
        let position: CGFloat

        switch direction {
        case .horizontal:
            totalSize = bounds.width
            position = location.x
        case .vertical:
            totalSize = bounds.height
            position = location.y
        }

        guard totalSize > 0 else { return }

        let newRatio = Float(position / totalSize)
        let clampedRatio = max(minRatio, min(maxRatio, newRatio))

        if abs(clampedRatio - ratio) > 0.005 {
            updateRatio(clampedRatio, animated: false)
            onRatioChange?(clampedRatio)
        }
    }

    // MARK: - Public Methods

    func setLeftView(_ view: UIView) {
        leftView?.removeFromSuperview()
        leftView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor)
        ])
    }

    func setRightView(_ view: UIView) {
        rightView?.removeFromSuperview()
        rightView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor)
        ])
    }

    func updateRatio(_ newRatio: Float, animated: Bool = true) {
        ratio = max(minRatio, min(maxRatio, newRatio))

        // Remove old constraint and create new one with updated multiplier
        switch direction {
        case .horizontal:
            leftWidthConstraint?.isActive = false
            leftWidthConstraint = leftContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: CGFloat(ratio))
            leftWidthConstraint?.isActive = true
        case .vertical:
            leftHeightConstraint?.isActive = false
            leftHeightConstraint = leftContainer.heightAnchor.constraint(equalTo: heightAnchor, multiplier: CGFloat(ratio))
            leftHeightConstraint?.isActive = true
        }

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    // MARK: - Theme

    func updateTheme() {
        divider.backgroundColor = Theme.current.textColor.withAlphaComponent(0.15)
    }
}
#endif
