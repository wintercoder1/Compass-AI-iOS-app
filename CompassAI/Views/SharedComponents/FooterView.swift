//
//  FooterView.swift
//  Compass AI V2
//
//  Created by Steve on 8/25/25.
//

import UIKit

// MARK: - Compass AI Footer View
class CompassAIFooterView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Remove any background color, corner radius, shadow, or border styling
        backgroundColor = UIColor.white // or match your app's background
        layer.cornerRadius = 0 // Remove rounded corners
        layer.shadowOpacity = 0 // Remove shadow
        layer.borderWidth = 0 // Remove border
        
        setupFooterContent()
    }
    
    private func setupFooterContent() {
        // Copyright label
        let copyrightLabel = UILabel()
        copyrightLabel.text = "© 2026 \(AppConfiguration.companyName). All rights reserved."
        copyrightLabel.font = UIFont.systemFont(ofSize: 12)
        copyrightLabel.textColor = UIColor.systemGray
        copyrightLabel.textAlignment = .center
        copyrightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Data source label
        let dataSourceLabel = UILabel()
        dataSourceLabel.text = "Data sourced from public FEC filings and other regulatory sources."
        dataSourceLabel.font = UIFont.systemFont(ofSize: 12)
        dataSourceLabel.textColor = UIColor.systemGray
        dataSourceLabel.textAlignment = .center
        dataSourceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Email icon (you can use SF Symbols or a custom image)
//        let emailIcon = UIImageView()
//        emailIcon.image = UIImage(systemName: "envelope")
//        emailIcon.tintColor = UIColor.systemGray
//        emailIcon.contentMode = .scaleAspectFit
//        emailIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Disclaimer label
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "This website provides information derived from publicly available data. \(AppConfiguration.displayName) and \(AppConfiguration.companyName) do not endorse any political candidates or organizations mentioned."
        disclaimerLabel.font = UIFont.systemFont(ofSize: 11)
        disclaimerLabel.textColor = UIColor.systemGray2
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(copyrightLabel)
        addSubview(dataSourceLabel)
//        addSubview(emailIcon)
        addSubview(disclaimerLabel)
        
        NSLayoutConstraint.activate([
            // Copyright at top
            copyrightLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            copyrightLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            copyrightLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Data source below copyright
            dataSourceLabel.topAnchor.constraint(greaterThanOrEqualTo: copyrightLabel.bottomAnchor, constant: 28),
            dataSourceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dataSourceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Email icon below data source
//            emailIcon.topAnchor.constraint(equalTo: dataSourceLabel.bottomAnchor, constant: 16),
//            emailIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
//            emailIcon.widthAnchor.constraint(equalToConstant: 24),
//            emailIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Disclaimer at bottom
//            disclaimerLabel.topAnchor.constraint(equalTo: emailIcon.bottomAnchor, constant: 16),
            disclaimerLabel.topAnchor.constraint(greaterThanOrEqualTo: dataSourceLabel.bottomAnchor, constant: 26),
            disclaimerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            disclaimerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
//            disclaimerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Intrinsic Content Size
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
    
}

// MARK: - UIViewController Extension
extension UIViewController {
    
    // Adds a Compass AI footer to a container view
    /// - Parameters:
    ///   - containerView: The view to add the footer to
    ///   - topAnchor: The anchor to position the footer below
    ///   - topConstant: Top spacing (defaults to 100)
    ///   - bottomConstant: Bottom spacing (defaults to -20)
    ///   - includeBottomPadding: Whether to include extra bottom padding (defaults to true)
    ///   - bottomPaddingHeight: Height of bottom padding view (defaults to 200)
    /// - Returns: The configured footer stack view
    @discardableResult
    func addCompassAIFooterStackView(to containerView: UIView,
                            below topAnchor: NSLayoutYAxisAnchor,
                            topConstant: CGFloat = 100,
                            bottomConstant: CGFloat = -220,
                            includeBottomPadding: Bool = true,
                            bottomPaddingHeight: CGFloat = 800) -> UIStackView {
            
        // Create footer stack view
        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 8
        footerStackView.alignment = .center
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.backgroundColor = .white
        
        // Create footer labels
        let copyrightLabel = UILabel()
        copyrightLabel.text = "  © 2026 \(AppConfiguration.companyName). All rights reserved.  "
        copyrightLabel.font = UIFont.systemFont(ofSize: 14)
        copyrightLabel.textColor = .systemGray
        copyrightLabel.textAlignment = .center
        
        let dataSourceLabel = UILabel()
        dataSourceLabel.text = "  Data sourced from public FEC filings and other regulatory sources.  "
        dataSourceLabel.font = UIFont.systemFont(ofSize: 14)
        dataSourceLabel.textColor = .systemGray
        dataSourceLabel.textAlignment = .center
        dataSourceLabel.numberOfLines = 0
        
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "  This website provides information derived from publicly available data. \(AppConfiguration.displayName) and \(AppConfiguration.companyName) do not endorse any political candidates or organizations mentioned.  "
        disclaimerLabel.font = UIFont.systemFont(ofSize: 12)
        disclaimerLabel.textColor = .systemGray
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        
        // Add labels to stack view
        footerStackView.addArrangedSubview(copyrightLabel)
        footerStackView.addArrangedSubview(dataSourceLabel)
        footerStackView.addArrangedSubview(disclaimerLabel)
        
        // Add footer to container
        containerView.addSubview(footerStackView)
        
        // Create bottom padding view if requested
        var bottomPaddingView: UIView?
        if includeBottomPadding {
            bottomPaddingView = UIView()
            bottomPaddingView!.translatesAutoresizingMaskIntoConstraints = false
            bottomPaddingView!.backgroundColor = .white
            containerView.addSubview(bottomPaddingView!)
        }
        
        // Set up constraints
        let footerViewHeight: CGFloat = 140.0
        
        // Use the provided anchor or default to containerView's top
        let effectiveTopAnchor = topAnchor ?? containerView.topAnchor
        
        var constraints = [
            // Footer stack view constraints
            footerStackView.topAnchor.constraint(greaterThanOrEqualTo: effectiveTopAnchor, constant: topConstant),
            footerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            footerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            footerStackView.heightAnchor.constraint(equalToConstant: footerViewHeight)
        ]
        
        if let bottomPaddingView = bottomPaddingView {
            // If bottom padding is included, anchor footer to it
            constraints.append(contentsOf: [
                footerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottomConstant),
                
                // Bottom padding constraints
                bottomPaddingView.topAnchor.constraint(equalTo: footerStackView.bottomAnchor, constant: 0),
                bottomPaddingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
                bottomPaddingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
                bottomPaddingView.heightAnchor.constraint(equalToConstant: bottomPaddingHeight)
            ])
        } else {
            // If no bottom padding, anchor footer directly to bottom
            constraints.append(
                footerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: bottomConstant)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
        
        return footerStackView
    }
 
    /// Adds a Compass AI footer to a container view
    /// - Parameters:
    ///   - containerView: The view to add the footer to
    ///   - topAnchor: The anchor to position the footer below
    ///   - bottomAnchor: The anchor to position the footer above (optional)
    ///   - leadingConstant: Leading margin (defaults to 20)
    ///   - trailingConstant: Trailing margin (defaults to -20)
    ///   - topConstant: Top spacing (defaults to 40)
    ///   - bottomConstant: Bottom spacing (defaults to -40)
    /// - Returns: The configured footer view
    @discardableResult
    func addCompassAIFooter(to containerView: UIView,
                            below topAnchor: NSLayoutYAxisAnchor,
                            above bottomAnchor: NSLayoutYAxisAnchor? = nil,
                            leadingConstant: CGFloat = 0, // Changed from 20 to 0 for full width
                            trailingConstant: CGFloat = 0, // Changed from -20 to 0 for full width
                            topConstant: CGFloat = 30,
                            bottomConstant: CGFloat = -100) -> CompassAIFooterView {
            
        let footerView = CompassAIFooterView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(footerView)
        
        let constraints = [
            footerView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: topConstant),
            footerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: leadingConstant),
            footerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: trailingConstant),
//            footerView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: bottomConstant)
//            footerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
            footerView.heightAnchor.constraint(equalToConstant: 400)
        ]
   
        NSLayoutConstraint.activate(constraints)
        
        return footerView
    }
}
