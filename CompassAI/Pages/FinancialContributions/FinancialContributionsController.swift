//
//  FinancialContributionsController.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//


import UIKit
import Foundation

// MARK: - Financial Contributions View Controller
class FinancialContributionsViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: CompassAIHeaderView!
    private let contributionsBreakdownCardView = UIView()
    private let leadershipContributionsCardView = UIView()
    private let topRecipientsCardView = UIView()
    private let detailsCardView = UIView()
    private let loadingView = UIView()
    private let spinnerView = UIView()
    private let loadingLabel = UILabel()
    private let footerStackView = UIStackView()
    private let bottomPaddingView = UIView()
    
    private var organizationName: String = ""
    private var viewModel: FinancialContributionsViewModel!
    private var financialContributions: FinancialContributionsResponse?
    private weak var coordinator: AppCoordinator?
    
    private var maxContributionsInitiallyDisplayed = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        setupUI()
        setupConstraints()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("viewModel")
        print(viewModel)
        print("financialContributions")
        print(financialContributions)
    }
    
    func configure(organizationName: String, viewModel: FinancialContributionsViewModel, coordinator: AppCoordinator) {
        self.organizationName = organizationName
        self.viewModel = viewModel
        self.coordinator = coordinator
    }
    
    // Update the bindViewModel method to handle the new callback
    private func bindViewModelUpdated() {
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.showLoading()
            } else {
                self?.hideLoading()
            }
        }
        
        viewModel.onDataLoaded = { [weak self] financialText in
            self?.showFinancialContent(financialText)
        }
        
        // NEW: Handle the full data response
        viewModel.onFullDataLoaded = { [weak self] financialResponse in
            self?.setFinancialContributions(financialResponse)
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.showError(errorMessage)
        }
    }
    
    private func bindViewModel() {
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.showLoading()
            } else {
                self?.hideLoading()
            }
        }
        
        viewModel.onDataLoaded = { [weak self] financialText in
            self?.showFinancialContent(financialText)
        }
        // May be redundant.
        // TODO: Combine this with the above call and refactor of what this calls.
        viewModel.onFullDataLoaded = { [weak self] financialResponse in
            self?.setFinancialContributions(financialResponse)
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.showError(errorMessage)
        }
    }
    
    
    // Add this method to receive the full financial contributions data
    func setFinancialContributions(_ contributions: FinancialContributionsResponse) {
        print("set financial contributions")
        print("We got percent contributions old: \(self.financialContributions?.percentContributions)")
        print("We got percent contributions new: \(contributions.percentContributions)")
        self.financialContributions = contributions
        
        // Children need to be un-azy loaaded
        if let leadershipContributionsToCommittee = contributions.leadershipContributionsToCommittee {
            self.financialContributions?.leadershipContributionsToCommittee = leadershipContributionsToCommittee
            print("|| leadershipContributionsToCommittee: \(leadershipContributionsToCommittee)")
        } else {
            print("|| NO leadership contirbutions")
            print("|| this is the self.financialContributions:")
            print("|| \(self.financialContributions)")
        }
        DispatchQueue.main.async {
            print("will updateContributionsBreakdownCard")
            
            self.updateContributionsBreakdownCard()
            self.updateLeadershipContributionsCard()
            self.updateTopRecipientsCard()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Hide the navigation bar since we're using our custom header
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Add the custom header using the extension
        headerView = addCompassAIHeader(title: "Compass AI", showBackButton: true)
        headerView.delegate = self
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.systemGroupedBackground
        scrollView.contentInsetAdjustmentBehavior = .never // Prevent automatic content inset
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupContributionsBreakdownCard()
        setupLeadershipContributionsCard()
        setupTopRecipientsCard()
        setupDetailsCard()
        setupLoadingView()
        setupFooterOld()
    }
    
    private func setupContributionsBreakdownCard() {
        contributionsBreakdownCardView.backgroundColor = .white
        contributionsBreakdownCardView.layer.cornerRadius = 16
        contributionsBreakdownCardView.layer.shadowColor = UIColor.black.cgColor
        contributionsBreakdownCardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        contributionsBreakdownCardView.layer.shadowRadius = 16
        contributionsBreakdownCardView.layer.shadowOpacity = 0.1
        contributionsBreakdownCardView.translatesAutoresizingMaskIntoConstraints = false
        contributionsBreakdownCardView.isHidden = true // Initially hidden until data loads
        
        contentView.addSubview(contributionsBreakdownCardView)
    }
    
    private func setupLeadershipContributionsCard() {
        leadershipContributionsCardView.backgroundColor = .white
        leadershipContributionsCardView.layer.cornerRadius = 16
        leadershipContributionsCardView.layer.shadowColor = UIColor.black.cgColor
        leadershipContributionsCardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        leadershipContributionsCardView.layer.shadowRadius = 16
        leadershipContributionsCardView.layer.shadowOpacity = 0.1
        leadershipContributionsCardView.translatesAutoresizingMaskIntoConstraints = false
        leadershipContributionsCardView.isHidden = true // Initially hidden until data loads
        
        contentView.addSubview(leadershipContributionsCardView)
    }
    
    private func setupTopRecipientsCard() {
        topRecipientsCardView.backgroundColor = .white
        topRecipientsCardView.layer.cornerRadius = 16
        topRecipientsCardView.layer.shadowColor = UIColor.black.cgColor
        topRecipientsCardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        topRecipientsCardView.layer.shadowRadius = 16
        topRecipientsCardView.layer.shadowOpacity = 0.1
        topRecipientsCardView.translatesAutoresizingMaskIntoConstraints = false
        topRecipientsCardView.isHidden = true // Initially hidden until data loads
        
        contentView.addSubview(topRecipientsCardView)
    }
    
    private func setupDetailsCard() {
        detailsCardView.backgroundColor = .white
        detailsCardView.layer.cornerRadius = 16
        detailsCardView.layer.shadowColor = UIColor.black.cgColor
        detailsCardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        detailsCardView.layer.shadowRadius = 16
        detailsCardView.layer.shadowOpacity = 0.1
        detailsCardView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(detailsCardView)
    }
    
    private func setupLoadingView() {
        loadingView.backgroundColor = UIColor.systemGroupedBackground
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading label
        loadingLabel.text = "Loading financial data..."
        loadingLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        loadingLabel.textColor = .systemGray
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Spinner
        spinnerView.backgroundColor = .clear
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        
        loadingView.addSubview(loadingLabel)
        loadingView.addSubview(spinnerView)
        detailsCardView.addSubview(loadingView)
        
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: detailsCardView.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: detailsCardView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: detailsCardView.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: detailsCardView.bottomAnchor),
            
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -30),
            
            spinnerView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            spinnerView.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 40),
            spinnerView.widthAnchor.constraint(equalToConstant: 40),
            spinnerView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        startLoadingSpinner()
    }
    
    private func setupFooterOld() {
        footerStackView.axis = .vertical
        footerStackView.spacing = 8
        footerStackView.alignment = .center
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.backgroundColor = .white
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        bottomPaddingView.backgroundColor = .white
//        bottomPaddingView.backgroundColor = .cyan
        
        let copyrightLabel = UILabel()
        copyrightLabel.text = "  © 2025 Correlation Apps LLC. All rights reserved.  "
        copyrightLabel.font = UIFont.systemFont(ofSize: 14)
        copyrightLabel.textColor = .systemGray
        copyrightLabel.textAlignment = .center
        
        let dataSourceLabel = UILabel()
        dataSourceLabel.text = "  Data sourced from public FEC filings and other regulatory sources.  "
        dataSourceLabel.font = UIFont.systemFont(ofSize: 14)
        dataSourceLabel.textColor = .systemGray
        dataSourceLabel.textAlignment = .center
        dataSourceLabel.numberOfLines = 0
        
//        let emailImageView = UIImageView(image: UIImage(systemName: "envelope"))
//        emailImageView.tintColor = .systemGray
//        emailImageView.contentMode = .scaleAspectFit
        
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "  This website provides information derived from publicly available data. Compass AI and Correlation Apps LLC do not endorse any political candidates or organizations mentioned.  "
        disclaimerLabel.font = UIFont.systemFont(ofSize: 12)
        disclaimerLabel.textColor = .systemGray
        disclaimerLabel.textAlignment = .center
        disclaimerLabel.numberOfLines = 0
        
        footerStackView.addArrangedSubview(copyrightLabel)
        footerStackView.addArrangedSubview(dataSourceLabel)
//        footerStackView.addArrangedSubview(emailImageView)
        footerStackView.addArrangedSubview(disclaimerLabel)
        
        contentView.addSubview(footerStackView)
        contentView.addSubview(bottomPaddingView)
    }
    
    private func updateContributionsBreakdownCard() {
        guard let contributions = financialContributions,
              let percentContributions = contributions.percentContributions else {
            contributionsBreakdownCardView.isHidden = true
//            print("|| contributionsBreakdownCardView.isHidden = true ||")
            return
        }
        
        contributionsBreakdownCardView.isHidden = false
//        print("|| contributionsBreakdownCardView.isHidden NOT HIDDEN ||")
        
        // Clear existing content
        contributionsBreakdownCardView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Contributions to Each Party"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        
        // Total contributions
        let totalLabel = UILabel()
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let totalAmount = formatter.string(from: NSNumber(value: percentContributions.totalContributions)) ?? "$0"
        totalLabel.text = "Total Contributions: \(totalAmount)"
        totalLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        totalLabel.textColor = .black
        
        // Party breakdown
        let partyStackView = UIStackView()
        partyStackView.axis = .vertical
        partyStackView.spacing = 12
        
        // Republicans
        let republicanAmount = formatter.string(from: NSNumber(value: percentContributions.totalToRepublicans)) ?? "$0"
        let republicanLabel = UILabel()
        republicanLabel.text = "To Republicans: \(republicanAmount) (\(String(format: "%.2f", percentContributions.percentToRepublicans))%)"
        republicanLabel.font = UIFont.systemFont(ofSize: 16)
        republicanLabel.textColor = .black
        
        // Democrats
        let democratAmount = formatter.string(from: NSNumber(value: percentContributions.totalToDemocrats)) ?? "$0"
        let democratLabel = UILabel()
        democratLabel.text = "To Democrats: \(democratAmount) (\(String(format: "%.2f", percentContributions.percentToDemocrats))%)"
        democratLabel.font = UIFont.systemFont(ofSize: 16)
        democratLabel.textColor = .black
        
        partyStackView.addArrangedSubview(republicanLabel)
        partyStackView.addArrangedSubview(democratLabel)
        
        // Progress bar container
        let progressBarContainer = UIView()
        progressBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Background bar
        let backgroundBar = UIView()
        backgroundBar.backgroundColor = .systemGray5
        backgroundBar.layer.cornerRadius = 6
        backgroundBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Democratic bar (blue)
        let democraticBar = UIView()
        democraticBar.backgroundColor = .systemBlue
        democraticBar.layer.cornerRadius = 6
        democraticBar.translatesAutoresizingMaskIntoConstraints = false
        
        // Republican bar (red)
        let republicanBar = UIView()
        republicanBar.backgroundColor = .systemRed
        republicanBar.layer.cornerRadius = 6
        republicanBar.translatesAutoresizingMaskIntoConstraints = false
        
        progressBarContainer.addSubview(backgroundBar)
        progressBarContainer.addSubview(democraticBar)
        progressBarContainer.addSubview(republicanBar)
        
        // Legend
        let legendStackView = UIStackView()
        legendStackView.axis = .horizontal
        legendStackView.distribution = .equalSpacing
        legendStackView.alignment = .center
        
        // Democratic legend
        let democraticLegendStack = UIStackView()
        democraticLegendStack.axis = .horizontal
        democraticLegendStack.spacing = 8
        democraticLegendStack.alignment = .center
        
        let democraticDot = UIView()
        democraticDot.backgroundColor = .systemBlue
        democraticDot.layer.cornerRadius = 6
        democraticDot.translatesAutoresizingMaskIntoConstraints = false
        
        let democraticLegendLabel = UILabel()
        democraticLegendLabel.text = "Democrats"
        democraticLegendLabel.font = UIFont.systemFont(ofSize: 14)
        democraticLegendLabel.textColor = .black
        
        democraticLegendStack.addArrangedSubview(democraticDot)
        democraticLegendStack.addArrangedSubview(democraticLegendLabel)
        
        // Republican legend
        let republicanLegendStack = UIStackView()
        republicanLegendStack.axis = .horizontal
        republicanLegendStack.spacing = 8
        republicanLegendStack.alignment = .center
        
        let republicanDot = UIView()
        republicanDot.backgroundColor = .systemRed
        republicanDot.layer.cornerRadius = 6
        republicanDot.translatesAutoresizingMaskIntoConstraints = false
        
        let republicanLegendLabel = UILabel()
        republicanLegendLabel.text = "Republicans"
        republicanLegendLabel.font = UIFont.systemFont(ofSize: 14)
        republicanLegendLabel.textColor = .black
        
        republicanLegendStack.addArrangedSubview(republicanDot)
        republicanLegendStack.addArrangedSubview(republicanLegendLabel)
        
        legendStackView.addArrangedSubview(democraticLegendStack)
        legendStackView.addArrangedSubview(republicanLegendStack)
        
        // Add all elements to main stack
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(totalLabel)
        stackView.addArrangedSubview(partyStackView)
        stackView.addArrangedSubview(progressBarContainer)
        stackView.addArrangedSubview(legendStackView)
        
        contributionsBreakdownCardView.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Main stack view
            stackView.topAnchor.constraint(equalTo: contributionsBreakdownCardView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: contributionsBreakdownCardView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: contributionsBreakdownCardView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: contributionsBreakdownCardView.bottomAnchor, constant: -30),
            
            // Progress bar container
            progressBarContainer.heightAnchor.constraint(equalToConstant: 12),
            
            // Background bar
            backgroundBar.topAnchor.constraint(equalTo: progressBarContainer.topAnchor),
            backgroundBar.leadingAnchor.constraint(equalTo: progressBarContainer.leadingAnchor),
            backgroundBar.trailingAnchor.constraint(equalTo: progressBarContainer.trailingAnchor),
            backgroundBar.bottomAnchor.constraint(equalTo: progressBarContainer.bottomAnchor),
            
            // Democratic bar (left side)
            democraticBar.topAnchor.constraint(equalTo: progressBarContainer.topAnchor),
            democraticBar.leadingAnchor.constraint(equalTo: progressBarContainer.leadingAnchor),
            democraticBar.bottomAnchor.constraint(equalTo: progressBarContainer.bottomAnchor),
            democraticBar.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor, multiplier: CGFloat(percentContributions.percentToDemocrats / 100.0)),
            
            // Republican bar (right side)
            republicanBar.topAnchor.constraint(equalTo: progressBarContainer.topAnchor),
            republicanBar.trailingAnchor.constraint(equalTo: progressBarContainer.trailingAnchor),
            republicanBar.bottomAnchor.constraint(equalTo: progressBarContainer.bottomAnchor),
            republicanBar.widthAnchor.constraint(equalTo: progressBarContainer.widthAnchor, multiplier: CGFloat(percentContributions.percentToRepublicans / 100.0)),
            
            // Legend dots
            democraticDot.widthAnchor.constraint(equalToConstant: 12),
            democraticDot.heightAnchor.constraint(equalToConstant: 12),
            
            republicanDot.widthAnchor.constraint(equalToConstant: 12),
            republicanDot.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    private func updateLeadershipContributionsCard() {
        guard let contributions = financialContributions,
              let leadershipContributions = contributions.leadershipContributionsToCommittee,
              !leadershipContributions.isEmpty else {
            leadershipContributionsCardView.isHidden = true
            return
        }
        
        leadershipContributionsCardView.isHidden = false
        
        // Clear existing content
        leadershipContributionsCardView.subviews.forEach { $0.removeFromSuperview() }
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Contributors in Company Leadership"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        
        mainStackView.addArrangedSubview(titleLabel)
        
        // Number formatter for currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        // Sort contributions by amount in descending order
        let sortedContributions = leadershipContributions.sorted { contribution1, contribution2 in
            let amount1 = Double(contribution1.transactionAmount) ?? 0
            let amount2 = Double(contribution2.transactionAmount) ?? 0
            return amount1 > amount2
        }
        
        // Show first 5-10 contributors
        let displayCount = min(self.maxContributionsInitiallyDisplayed, sortedContributions.count)
        for i in 0..<displayCount {
            let contribution = sortedContributions[i]
            
            let contributorView = createLeadershipContributorView(
                contribution: contribution,
                formatter: formatter
            )
            
            mainStackView.addArrangedSubview(contributorView)
            
            // Add separator if not the last item
            if i < displayCount - 1 {
                let separator = UIView()
                separator.backgroundColor = .systemGray5
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                mainStackView.addArrangedSubview(separator)
            }
        }
        
        // Footer showing count and view all button
        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 12
        footerStack.alignment = .center
        
        let countLabel = UILabel()
        countLabel.text = "Showing \(displayCount) of \(leadershipContributions.count) total leadership contributors"
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .systemGray
        countLabel.textAlignment = .center
        
        // TODO: Implement mores contributions detail page.
//        let viewAllButton = UIButton(type: .system)
//        viewAllButton.setTitle("View All Leadership Contributors", for: .normal)
//        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        viewAllButton.addTarget(self, action: #selector(viewAllLeadershipContributorsTapped), for: .touchUpInside)
        
        footerStack.addArrangedSubview(countLabel)
//        footerStack.addArrangedSubview(viewAllButton)
        
        mainStackView.addArrangedSubview(footerStack)
        
        leadershipContributionsCardView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: leadershipContributionsCardView.topAnchor, constant: 30),
            mainStackView.leadingAnchor.constraint(equalTo: leadershipContributionsCardView.leadingAnchor, constant: 30),
            mainStackView.trailingAnchor.constraint(equalTo: leadershipContributionsCardView.trailingAnchor, constant: -30),
            mainStackView.bottomAnchor.constraint(equalTo: leadershipContributionsCardView.bottomAnchor, constant: -30)
        ])
    }
    
    private func updateTopRecipientsCard() {
        guard let contributions = financialContributions,
              let contributionTotals = contributions.contributionTotals,
              !contributionTotals.isEmpty else {
            topRecipientsCardView.isHidden = true
            return
        }
        
        topRecipientsCardView.isHidden = false
        
        // Clear existing content
        topRecipientsCardView.subviews.forEach { $0.removeFromSuperview() }
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Politicians Receiving Contributions"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        
        mainStackView.addArrangedSubview(titleLabel)
        
        // Number formatter for currency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        // Sort contributions by amount in descending order
        let sortedRecipients = contributionTotals.sorted { recipient1, recipient2 in
            let amount1 = recipient1.totalContributionAmount ?? 0
            let amount2 = recipient2.totalContributionAmount ?? 0
            return amount1 > amount2
        }
        
        // Show first 5-10 recipients
        let displayCount = min(self.maxContributionsInitiallyDisplayed, sortedRecipients.count)
        for i in 0..<displayCount {
            let recipient = sortedRecipients[i]
            
            let recipientView = createTopRecipientView(
                recipient: recipient,
                formatter: formatter
            )
            
            mainStackView.addArrangedSubview(recipientView)
            
            // Add separator if not the last item
            if i < displayCount - 1 {
                let separator = UIView()
                separator.backgroundColor = .systemGray5
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                mainStackView.addArrangedSubview(separator)
            }
        }
        
        // Footer showing count and view all button
        let footerStack = UIStackView()
        footerStack.axis = .vertical
        footerStack.spacing = 12
        footerStack.alignment = .center
        
        let countLabel = UILabel()
        countLabel.text = "Showing \(displayCount) of \(contributionTotals.count) total recipients"
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .systemGray
        countLabel.textAlignment = .center
        
        // TODO: Implement mores contributions detail page.
//        let viewAllButton = UIButton(type: .system)
//        viewAllButton.setTitle("View All Contribution Recipients", for: .normal)
//        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        viewAllButton.addTarget(self, action: #selector(viewAllRecipientsTapped), for: .touchUpInside)
        
        footerStack.addArrangedSubview(countLabel)
//        footerStack.addArrangedSubview(viewAllButton)
        
        mainStackView.addArrangedSubview(footerStack)
        
        topRecipientsCardView.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topRecipientsCardView.topAnchor, constant: 30),
            mainStackView.leadingAnchor.constraint(equalTo: topRecipientsCardView.leadingAnchor, constant: 30),
            mainStackView.trailingAnchor.constraint(equalTo: topRecipientsCardView.trailingAnchor, constant: -30),
            mainStackView.bottomAnchor.constraint(equalTo: topRecipientsCardView.bottomAnchor, constant: -30)
        ])
    }
    
    private func createLeadershipContributorView(contribution: LeadershipContribution, formatter: NumberFormatter) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Top row: Name and Amount
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.distribution = .equalSpacing
        topRow.alignment = .top
        
        let nameLabel = UILabel()
        nameLabel.text = contribution.name.uppercased()
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 0
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let amountLabel = UILabel()
        if let amount = Double(contribution.transactionAmount) {
            amountLabel.text = formatter.string(from: NSNumber(value: amount))
        } else {
            amountLabel.text = contribution.transactionAmount
        }
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        amountLabel.textColor = .black
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        topRow.addArrangedSubview(nameLabel)
        topRow.addArrangedSubview(amountLabel)
        
        // Occupation
        let occupationLabel = UILabel()
        occupationLabel.text = contribution.occupation
        occupationLabel.font = UIFont.systemFont(ofSize: 14)
        occupationLabel.textColor = .systemGray
        occupationLabel.numberOfLines = 0
        
        // Employer
        let employerLabel = UILabel()
        employerLabel.text = contribution.employer
        employerLabel.font = UIFont.systemFont(ofSize: 14)
        employerLabel.textColor = .systemGray
        employerLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(topRow)
        stackView.addArrangedSubview(occupationLabel)
        stackView.addArrangedSubview(employerLabel)
        
        // Contributions count label (if you want to add it later)
        // For now, showing single contribution
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    private func createTopRecipientView(recipient: ContributionTotal, formatter: NumberFormatter) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Top row: Recipient Name and Amount
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.distribution = .equalSpacing
        topRow.alignment = .top
        
        let nameLabel = UILabel()
        nameLabel.text = (recipient.recipientName ?? "Unknown").uppercased()
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .black
        nameLabel.numberOfLines = 0
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let amountLabel = UILabel()
        if let amount = recipient.totalContributionAmount {
            amountLabel.text = formatter.string(from: NSNumber(value: amount))
        } else {
            amountLabel.text = "$0"
        }
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        amountLabel.textColor = .black
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        topRow.addArrangedSubview(nameLabel)
        topRow.addArrangedSubview(amountLabel)
        
        // Contribution count
        let countLabel = UILabel()
        if let count = recipient.numberOfContributions {
            let contributionText = count == 1 ? "contribution" : "contributions"
            countLabel.text = "\(count) \(contributionText)"
        } else {
            countLabel.text = "0 contributions"
        }
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .systemGray
        countLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(topRow)
        stackView.addArrangedSubview(countLabel)
        
        containerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    @objc private func viewAllLeadershipContributorsTapped() {
        // TODO: Implement navigation to full list of leadership contributors
        // You can create a new view controller to show all contributors
        print("View all leadership contributors tapped")
    }
    
    @objc private func viewAllRecipientsTapped() {
        // TODO: Implement navigation to full list of contribution recipients
        // You can create a new view controller to show all recipients
        print("View all contribution recipients tapped")
    }
    
    private func startLoadingSpinner() {
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: 20, y: 20),
            radius: 15,
            startAngle: 0,
            endAngle: CGFloat.pi * 1.6,
            clockwise: true
        )
        
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.systemBlue.cgColor
        circleLayer.lineWidth = 3
        circleLayer.lineCap = .round
        
        spinnerView.layer.addSublayer(circleLayer)
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 1.0
        rotationAnimation.repeatCount = .infinity
        
        spinnerView.layer.add(rotationAnimation, forKey: "rotation")
    }
    
    private func setupConstraints() {
        let footerViewHeight: CGFloat = 140.0
        NSLayoutConstraint.activate([
            // Scroll view - positioned below the header
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Details card view (first)
            detailsCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            detailsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            detailsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            detailsCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Contributions breakdown card (second)
            contributionsBreakdownCardView.topAnchor.constraint(equalTo: detailsCardView.bottomAnchor, constant: 20),
            contributionsBreakdownCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contributionsBreakdownCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Leadership contributions card (third)
            leadershipContributionsCardView.topAnchor.constraint(equalTo: contributionsBreakdownCardView.bottomAnchor, constant: 20),
            leadershipContributionsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            leadershipContributionsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Top recipients card (fourth)
            topRecipientsCardView.topAnchor.constraint(equalTo: leadershipContributionsCardView.bottomAnchor, constant: 20),
            topRecipientsCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            topRecipientsCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Footer
            footerStackView.topAnchor.constraint(greaterThanOrEqualTo: topRecipientsCardView.bottomAnchor, constant: 25),
            footerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            footerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            footerStackView.heightAnchor.constraint(equalToConstant: footerViewHeight),
            footerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Bottom Padding
            bottomPaddingView.topAnchor.constraint(equalTo: footerStackView.bottomAnchor, constant: 0),
            bottomPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            bottomPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            bottomPaddingView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    private func showLoading() {
        loadingView.isHidden = false
        contributionsBreakdownCardView.isHidden = true
        leadershipContributionsCardView.isHidden = true
        topRecipientsCardView.isHidden = true
    }
    
    private func hideLoading() {
        loadingView.isHidden = true
    }
    
    private func showFinancialContent(_ financialText: String) {
//    private func showFinancialContent(_ financialContributionsResponse: FinancialContributionsResponse) {
//        let financialText = financialContributionsResponse.fecFinancialContributionsSummaryText
        // Clear existing content in details card (except loading view)
        detailsCardView.subviews.forEach { subview in
            if subview != loadingView {
                subview.removeFromSuperview()
            }
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Financial Contributions Overview for \(organizationName)"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        
        // Financial text content
        let contentLabel = UILabel()
        contentLabel.text = financialText
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = .black
        contentLabel.numberOfLines = 0
        
        
        // Financial info source disclaimer
        let disclaimerLabel = UILabel()
        let disclaimerText = "This financial information is based on Federal Election Commission filings from the 2024 election cycle."
        let disclaimerTextAttributedString = NSMutableAttributedString(string: disclaimerText)
        disclaimerLabel.attributedText = disclaimerTextAttributedString
        disclaimerLabel.font = UIFont.systemFont(ofSize: 16)
        disclaimerLabel.textColor = .gray
        disclaimerLabel.numberOfLines = 3
        // Put in italics.
        let nsRange = NSRange(location: 0, length: disclaimerText.utf16.count)
        // Apply italic font to the specified range
        if let currentFont = disclaimerLabel.font {
            let italicFont = UIFont(descriptor: currentFont.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: currentFont.pointSize)
            disclaimerTextAttributedString.addAttribute(.font, value: italicFont, range: nsRange)
        }
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(contentLabel)
        stackView.addArrangedSubview(disclaimerLabel)
        
        detailsCardView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: detailsCardView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: detailsCardView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: detailsCardView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: detailsCardView.bottomAnchor, constant: -30)
        ])
        
        // Update the breakdown card as well
        updateContributionsBreakdownCard()
        updateLeadershipContributionsCard()
        updateTopRecipientsCard()
    }
    
    private func showError(_ message: String) {
        // Clear existing content in details card (except loading view)
        detailsCardView.subviews.forEach { subview in
            if subview != loadingView {
                subview.removeFromSuperview()
            }
        }
        
        contributionsBreakdownCardView.isHidden = true
        leadershipContributionsCardView.isHidden = true
        topRecipientsCardView.isHidden = true
        
        let errorStackView = UIStackView()
        errorStackView.axis = .vertical
        errorStackView.spacing = 16
        errorStackView.alignment = .center
        errorStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let errorLabel = UILabel()
        errorLabel.text = "Failed to load financial data"
        errorLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        
        let detailLabel = UILabel()
        detailLabel.text = message
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .systemGray
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        retryButton.backgroundColor = UIColor.systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        errorStackView.addArrangedSubview(errorLabel)
        errorStackView.addArrangedSubview(detailLabel)
        errorStackView.addArrangedSubview(retryButton)
        
        detailsCardView.addSubview(errorStackView)
        
        NSLayoutConstraint.activate([
            errorStackView.centerXAnchor.constraint(equalTo: detailsCardView.centerXAnchor),
            errorStackView.centerYAnchor.constraint(equalTo: detailsCardView.centerYAnchor),
            errorStackView.leadingAnchor.constraint(greaterThanOrEqualTo: detailsCardView.leadingAnchor, constant: 30),
            errorStackView.trailingAnchor.constraint(lessThanOrEqualTo: detailsCardView.trailingAnchor, constant: -30)
        ])
    }
    
    @objc private func retryButtonTapped() {
        viewModel.fetchFinancialContributions(for: organizationName)
    }
}

// MARK: - CompassAIHeaderViewDelegate
extension FinancialContributionsViewController: CompassAIHeaderViewDelegate {
    func headerViewBackButtonTapped(_ headerView: CompassAIHeaderView) {
        coordinator?.navigateBack()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FinancialContributionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
