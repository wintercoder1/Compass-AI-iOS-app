
//
//  HeaderView.swift
//  Compass AI V2
//
//  Created by Steve on 8/25/25.
//
import UIKit

// MARK: - Compass AI Header View
class CompassAIHeaderView: UIView {
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .system)
    private let centerContentView = UIView()
    private let slashLineView = UIView()
    private let titleLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let separatorLine = UIView()
    
    // MARK: - Properties
    weak var delegate: CompassAIHeaderViewDelegate?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        backgroundColor = .white
        
        // Configure back button with chevron icon
        let chevronImage = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
        backButton.setImage(chevronImage, for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Configure center content view to hold the centered title.
        centerContentView.translatesAutoresizingMaskIntoConstraints = false
        
        // TODO: Replace the slash line with a compass logo.
//         Configure slash line (the diagonal line/logo)
//        slashLineView.backgroundColor = .black
//        slashLineView.translatesAutoresizingMaskIntoConstraints = false
//        slashLineView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 6) // 30 degree rotation
        
        // Configure title label
        titleLabel.text = AppConfiguration.displayName
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let infoImage = UIImage(systemName: "info.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .regular))
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = .systemGray
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.isHidden = true
        infoButton.accessibilityLabel = "About \(AppConfiguration.displayName)"
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        
        // Configure separator line at bottom
        separatorLine.backgroundColor = UIColor.systemGray4
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(backButton)
        addSubview(centerContentView)
//        centerContentView.addSubview(slashLineView)
        centerContentView.addSubview(titleLabel)
        addSubview(infoButton)
        addSubview(separatorLine)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back button - positioned on the left in safe area
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            backButton.bottomAnchor.constraint(equalTo: separatorLine.topAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Center content view - contains logo and title
            centerContentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerContentView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            centerContentView.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            centerContentView.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -12),

            titleLabel.leadingAnchor.constraint(equalTo: centerContentView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerContentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centerContentView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: centerContentView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: centerContentView.bottomAnchor),

            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            infoButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            infoButton.widthAnchor.constraint(equalToConstant: 28),
            infoButton.heightAnchor.constraint(equalToConstant: 28),
            
            // Separator line at the bottom
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    // MARK: - Public Configuration Methods
    func configure(title: String = AppConfiguration.displayName, showBackButton: Bool = true, showInfoButton: Bool = false) {
        titleLabel.text = title
        backButton.isHidden = !showBackButton
        infoButton.isHidden = !showInfoButton
    }
    
    func setTitleColor(_ color: UIColor) {
        titleLabel.textColor = color
    }
    
    func setSlashColor(_ color: UIColor) {
        slashLineView.backgroundColor = color
    }
    
    func setBackButtonColor(_ color: UIColor) {
        backButton.tintColor = color
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        delegate?.headerViewBackButtonTapped(self)
    }

    @objc private func infoButtonTapped() {
        delegate?.headerViewInfoButtonTapped(self)
    }
    
    // MARK: - Intrinsic Content Size
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 70)
    }
}

// MARK: - Delegate Protocol
protocol CompassAIHeaderViewDelegate: AnyObject {
    func headerViewBackButtonTapped(_ headerView: CompassAIHeaderView)
    func headerViewInfoButtonTapped(_ headerView: CompassAIHeaderView)
}

extension CompassAIHeaderViewDelegate {
    func headerViewBackButtonTapped(_ headerView: CompassAIHeaderView) {}
    func headerViewInfoButtonTapped(_ headerView: CompassAIHeaderView) {}
}

// MARK: - UIViewController Extension
extension UIViewController {
    
    /// Adds a Compass AI header to the view controller that extends to the top of the screen
    /// - Parameters:
    ///   - title: The title to display (defaults to the configured app display name)
    ///   - showBackButton: Whether to show the back button (defaults to true)
    /// - Returns: The configured header view
    @discardableResult
    func addCompassAIHeader(title: String = AppConfiguration.displayName, showBackButton: Bool = true, showInfoButton: Bool = false) -> CompassAIHeaderView {
        
        let headerView = CompassAIHeaderView()
        headerView.configure(title: title, showBackButton: showBackButton, showInfoButton: showInfoButton)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add a background view that extends to the very top to prevent any gray showing through
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        
        view.addSubview(headerView)
        
        NSLayoutConstraint.activate([
            // Background view extends to the very top
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            
            // Header view on top of background
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70)
        ])
        
        return headerView
    }
}
