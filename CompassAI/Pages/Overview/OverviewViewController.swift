//
//  ResultsViewController.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//
import UIKit
import Foundation
import CoreData
import GoogleMobileAds

// MARK: - Results View Controller
class OverviewViewController: BaseViewController, BannerViewDelegate  {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: CompassAIHeaderView!
    private let cardView = UIView()

    private var footerStackView = UIStackView()
    private let bottomPaddingView = UIView()
    private var saveButton: UIButton!
    private var bannerView: BannerView!
    
    private var analysis: OrganizationAnalysis?
    private var category: CurrentSearchCategory?
    private var organizationName: String = ""
    private weak var coordinator: AppCoordinator?
    private var isSaved: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        
//        setupBannerAdContent() // view will appear
//        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    func configure(with analysis: OrganizationAnalysis, organizationName: String, coordinator: AppCoordinator) {
        self.analysis = analysis
        self.category = analysis.category
        self.organizationName = organizationName
        self.coordinator = coordinator
        
        if isViewLoaded {
            updateContent()
            checkIfAlreadySaved()
        }
    }
    
    //
    func configureWithPersistedData(analysis: OrganizationAnalysis, organizationName: String, coordinator: AppCoordinator) {
        self.analysis = analysis
        self.category = analysis.category
        self.organizationName = organizationName
        self.coordinator = coordinator
        
        // Mark as already saved since this is persisted data
        self.isSaved = true
        
        if isViewLoaded {
            updateContent()
            updateSaveButtonAppearance()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContent()
        
        // Only check if saved when not configured with persisted data
        // (to avoid overriding the isSaved = true from configureWithPersistedData)
        if !isSaved {
            checkIfAlreadySaved()
        } else {
            updateSaveButtonAppearance()
        }
        
        // 
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self

    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // Hide the navigation bar since we're using our custom header
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Add the custom header using the extension
        headerView = addCompassAIHeader()
        headerView.delegate = self
        
        // Configure scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupCard()
        setupSaveButton()
//        setupFooter()
        setupBannerAdUI()
        setupFooterOld()
    }
    
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 0  // ← Changed from 16 to 0
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOpacity = 0.1
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(cardView)
    }
    
//    private func setupCard() {
//        cardView.backgroundColor = .white
//        cardView.layer.cornerRadius = 16
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
//        cardView.layer.shadowRadius = 16
//        cardView.layer.shadowOpacity = 0.1
//        cardView.translatesAutoresizingMaskIntoConstraints = false
//        
//        contentView.addSubview(cardView)
//    }
    
//    private func setupCard() {
//        cardView.backgroundColor = .white
//        cardView.layer.cornerRadius = 16
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
//        cardView.layer.shadowRadius = 16
//        cardView.layer.shadowOpacity = 0.1
//        cardView.translatesAutoresizingMaskIntoConstraints = false
//        
//        contentView.addSubview(cardView)
//    }
    
    private func setupSaveButton() {
        saveButton = UIButton(type: .system)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Initial state - outline heart
        updateSaveButtonAppearance()
        
        view.addSubview(saveButton)
    }
    
    
    
    private func updateSaveButtonAppearance() {
        let heartImageName = isSaved ? "heart.fill" : "heart"
        let heartImage = UIImage(systemName: heartImageName)
        saveButton.setImage(heartImage, for: .normal)
        saveButton.tintColor = isSaved ? .black : .systemGray
        
        // Add a subtle background for better visibility
        saveButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        saveButton.layer.cornerRadius = 20
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        saveButton.layer.shadowRadius = 4
        saveButton.layer.shadowOpacity = 0.1
        
        // Add some padding around the icon
        saveButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    private func setupFooterOld() {
        footerStackView.axis = .vertical
        footerStackView.spacing = 8
        footerStackView.alignment = .center
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        footerStackView.backgroundColor = .white
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        bottomPaddingView.backgroundColor = .white
 
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
        
        footerStackView.addArrangedSubview(copyrightLabel)
        footerStackView.addArrangedSubview(dataSourceLabel)
        footerStackView.addArrangedSubview(disclaimerLabel)
        
        contentView.addSubview(footerStackView)
        contentView.addSubview(bottomPaddingView)
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
            
            // Card view
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Save button - positioned in bottom-right corner of the card
            saveButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -15),
            saveButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -15),
            saveButton.widthAnchor.constraint(equalToConstant: 40),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            
            
            // This example doesn't give width or height constraints, as the ad size gives the banner an
            // intrinsic content size to size the view.
//            NSLayoutConstraint.activate([
          // Align the banner's bottom edge with the safe area's bottom edge
            bannerView.topAnchor.constraint(greaterThanOrEqualTo: cardView.bottomAnchor, constant: 20),
            // banerview padding
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
//              bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            bannerView.bottomAnchor.constraint(equalTo: footerStackView.bottomAnchor),
          // Center the banner horizontally in the view
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            
            // Footer
            // With banner
            footerStackView.topAnchor.constraint(greaterThanOrEqualTo: bannerView.bottomAnchor, constant: 20),
            // Without banner
//            footerStackView.topAnchor.constraint(greaterThanOrEqualTo: cardView.bottomAnchor, constant: 25),
            footerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            footerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            footerStackView.heightAnchor.constraint(equalToConstant: footerViewHeight),
            footerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Bottom Padding
            bottomPaddingView.topAnchor.constraint(equalTo: footerStackView.bottomAnchor, constant: 0),
            bottomPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            bottomPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            bottomPaddingView.heightAnchor.constraint(equalToConstant: 250)
        ])
    }
    
    private func updateContent() {
        guard let analysis = analysis else { return }
    
//        print("Analysis: \(analysis)")
//        print("Updated content with category: \(analysis.category)")
        
        // Clear existing content in card
        cardView.subviews.forEach { subview in
            if subview != saveButton {
                subview.removeFromSuperview()
            }
        }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Overview title
        let overviewLabel = UILabel()
        if self.category == CurrentSearchCategory.politicalLeaning ||
           self.category == CurrentSearchCategory.undefined || self.category == nil {
            overviewLabel.text = "Overview for \(organizationName)"
        } else {
            overviewLabel.text = "\(String(describing: self.category!.rawValue)) Overview for \(organizationName)"
        }
        overviewLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        overviewLabel.textColor = .black
        overviewLabel.numberOfLines = 0
        
        if analysis.category == .leadershipDemographics {
            configureLeadershipDemographicsContent(stackView: stackView, overviewLabel: overviewLabel, analysis: analysis)
            return
        }
        
        // Lean and rating section
        let leanRatingView = UIView()
        
        let leanStackView = UIStackView()
        leanStackView.axis = .vertical
        leanStackView.spacing = 4
        leanStackView.translatesAutoresizingMaskIntoConstraints = false
        
        if self.category == CurrentSearchCategory.politicalLeaning {
            let leanTitleLabel = UILabel()
            leanTitleLabel.text = "Lean:"
            leanTitleLabel.font = UIFont.systemFont(ofSize: 16)
            leanTitleLabel.textColor = .systemGray
            leanStackView.addArrangedSubview(leanTitleLabel)
        }
        
        let leanValueLabel = UILabel()
        leanValueLabel.text = analysis.lean.trimmingCharacters(in: .whitespaces).capitalized
        leanValueLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        leanValueLabel.textColor = .black
        leanStackView.addArrangedSubview(leanValueLabel)
        
        let ratingLabel = UILabel()
        ratingLabel.text = "\(analysis.rating)"
        ratingLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        ratingLabel.textColor = .black
        ratingLabel.textAlignment = .right
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leanRatingView.addSubview(leanStackView)
        leanRatingView.addSubview(ratingLabel)
        
        NSLayoutConstraint.activate([
            leanStackView.leadingAnchor.constraint(equalTo: leanRatingView.leadingAnchor),
            leanStackView.topAnchor.constraint(equalTo: leanRatingView.topAnchor),
            leanStackView.bottomAnchor.constraint(equalTo: leanRatingView.bottomAnchor),
            
            ratingLabel.trailingAnchor.constraint(equalTo: leanRatingView.trailingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: leanRatingView.centerYAnchor)
        ])
        
        // Description
        let descriptionLabel = UILabel()
        descriptionLabel.text = analysis.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .black
        descriptionLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(overviewLabel)
        stackView.addArrangedSubview(leanRatingView)
        stackView.addArrangedSubview(descriptionLabel)
        
        // Citations section (if applicable)
        if analysis.hasFinancialContributions {
            let citationsLabel = UILabel()
            citationsLabel.text = "Citations:"
//            citationsLabel.text = "Data cited:"
            citationsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
            citationsLabel.textColor = .black
            
            let financialButton = UIButton(type: .system)
            financialButton.setTitle("Financial Contributions Overview for \(organizationName)", for: .normal)
            financialButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            financialButton.setTitleColor(.systemBlue, for: .normal)
            financialButton.contentHorizontalAlignment = .left
            financialButton.addTarget(self, action: #selector(financialContributionsButtonTapped), for: .touchUpInside)
            
            // Add underline to make it look like a link
            let buttonTitle = "Financial Contributions Overview" // for \(organizationName)"
            let attributedTitle = NSMutableAttributedString(string: buttonTitle)
            attributedTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributedTitle.length))
            attributedTitle.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: attributedTitle.length))
            financialButton.setAttributedTitle(attributedTitle, for: .normal)
            
            stackView.addArrangedSubview(citationsLabel)
            stackView.addArrangedSubview(financialButton)
        }
        
        cardView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -55)
        ])
    }
    
    private func configureLeadershipDemographicsContent(
        stackView: UIStackView,
        overviewLabel: UILabel,
        analysis: OrganizationAnalysis
    ) {
        stackView.addArrangedSubview(overviewLabel)
        
        guard let demographics = analysis.leadershipDemographicsAnalysis,
              !demographics.segments.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.text = analysis.description
            emptyLabel.font = UIFont.systemFont(ofSize: 16)
            emptyLabel.textColor = .black
            emptyLabel.numberOfLines = 0
            stackView.addArrangedSubview(emptyLabel)
            attachOverviewStackView(stackView)
            return
        }
        
        let subtitleLabel = UILabel()
        if let ticker = demographics.ticker, !ticker.isEmpty {
            subtitleLabel.text = "\(demographics.resolvedCompany ?? organizationName) · \(ticker)"
        } else {
            subtitleLabel.text = demographics.resolvedCompany ?? organizationName
        }
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.numberOfLines = 0
        stackView.addArrangedSubview(subtitleLabel)
        
        let chartView = LeadershipDemographicsPieChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.configure(with: demographics.segments)
        stackView.addArrangedSubview(chartView)
        
        let legendStackView = UIStackView()
        legendStackView.axis = .vertical
        legendStackView.spacing = 12
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        
        for segment in demographics.segments {
            legendStackView.addArrangedSubview(createLeadershipLegendRow(for: segment))
        }
        stackView.addArrangedSubview(legendStackView)
        
        let sampleLabel = UILabel()
        sampleLabel.text = demographics.matchedSummary
        sampleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        sampleLabel.textColor = .systemGray
        sampleLabel.numberOfLines = 0
        stackView.addArrangedSubview(sampleLabel)
        
        if let caveat = demographics.caveat, !caveat.isEmpty {
            let caveatLabel = UILabel()
            caveatLabel.text = caveat
            caveatLabel.font = UIFont.systemFont(ofSize: 13)
            caveatLabel.textColor = .systemGray2
            caveatLabel.numberOfLines = 0
            stackView.addArrangedSubview(caveatLabel)
        }
        
        if let sourceDetail = demographics.sourceDetail, !sourceDetail.isEmpty {
            let sourceLabel = UILabel()
            sourceLabel.text = sourceDetail
            sourceLabel.font = UIFont.systemFont(ofSize: 13)
            sourceLabel.textColor = .systemGray2
            sourceLabel.numberOfLines = 0
            stackView.addArrangedSubview(sourceLabel)
        }
        
        attachOverviewStackView(stackView)
        
        NSLayoutConstraint.activate([
            chartView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }
    
    private func attachOverviewStackView(_ stackView: UIStackView) {
        cardView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -55)
        ])
    }
    
    private func createLeadershipLegendRow(for segment: LeadershipDemographicsSegment) -> UIView {
        let rowStackView = UIStackView()
        rowStackView.axis = .horizontal
        rowStackView.alignment = .center
        rowStackView.spacing = 10
        
        let colorDot = UIView()
        colorDot.backgroundColor = LeadershipDemographicsPieChartView.color(for: segment.group)
        colorDot.layer.cornerRadius = 6
        colorDot.translatesAutoresizingMaskIntoConstraints = false
        
        let groupLabel = UILabel()
        groupLabel.text = segment.group
        groupLabel.font = UIFont.systemFont(ofSize: 16)
        groupLabel.textColor = .black
        groupLabel.numberOfLines = 0
        
        let percentageLabel = UILabel()
        percentageLabel.text = "\(segment.percentage)%"
        percentageLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        percentageLabel.textColor = .black
        percentageLabel.textAlignment = .right
        percentageLabel.setContentHuggingPriority(.required, for: .horizontal)
        percentageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        rowStackView.addArrangedSubview(colorDot)
        rowStackView.addArrangedSubview(groupLabel)
        rowStackView.addArrangedSubview(percentageLabel)
        
        NSLayoutConstraint.activate([
            colorDot.widthAnchor.constraint(equalToConstant: 12),
            colorDot.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        return rowStackView
    }
    
//    @objc private func financialContributionsButtonTapped() {
//        // Fetch financial contributions when user taps the link
//        let financialViewModel = FinancialContributionsViewModel()
//        financialViewModel.coordinator = coordinator
//        
//        // Show the financial contributions screen and start fetching data
//        coordinator?.showFinancialContributionsScreen(organizationName: organizationName, viewModel: financialViewModel)
//        
//        // Trigger the data fetch
//        financialViewModel.fetchFinancialContributions(for: organizationName)
//    }
    @objc private func financialContributionsButtonTapped() {
        guard let analysis = analysis else { return }
        
        let financialViewModel = FinancialContributionsViewModel()
        financialViewModel.coordinator = coordinator
        
        // Check if we have persisted financial data
        // There is a corner case when the user taps save and the financial contributions request is still in flight.
        // That means it won;t be able to pull v
        if isSaved && analysis.financialContributionsOverviewAnalysis != nil {
            // If it is saved the financial info will already be in the organization analysis object.
            
//            let financialContributionsOverviewAnalysisData = analysis.financialContributionsOverviewAnalysis
            let financialResponse = exctractAndConvertOrganizationAnalysisToFinancialContributionsResponse(analysis)
            // Show the financial contributions screen with persisted data THAT WE ALREADY HAVE.
            coordinator?.showFinancialContributionsScreenWithPersistedData(
                organizationName: organizationName,
                viewModel: financialViewModel,
                financialData: financialResponse
            )
            return
        }
        
        // Fallback: Show the screen and fetch from network
        coordinator?.showFinancialContributionsScreen(
            organizationName: organizationName,
            viewModel: financialViewModel
        )
        financialViewModel.fetchFinancialContributions(for: organizationName)
    }
    
    
    private func exctractAndConvertOrganizationAnalysisToFinancialContributionsResponse(_ overviewResponse: OrganizationAnalysis) -> FinancialContributionsResponse {

        // Get the financial data object.
        let financialDataResponse:FinancialContributionsAnalysis? = overviewResponse.financialContributionsOverviewAnalysis
        
        return FinancialContributionsResponse(
            topic: overviewResponse.topic,
            normalizedTopicName: overviewResponse.topic, // Keep this way for now.
            timestamp: "0",
            committeeId: financialDataResponse?.committeeOrPACID ?? "0",
            individualId: 0, // Not stored in Core Data
            fecFinancialContributionsSummaryText: financialDataResponse?.financialContributionsText ?? "",
            upvoteCount:  0, // We aren't doing these yet.
            downvoteCount: 0, // We aren't doing these yet.
            timeRangeOfData: nil,
            cycleEndYear: nil,
            committeeName: nil,
            queryType: nil,
            debug: nil, // Not stored in Core Data
            percentContributions: financialDataResponse?.percentContributions, ////  You'll need to add this if you want to store it
            contributionTotals: financialDataResponse?.contributionTotals, // You'll need to add this if you want to store it
            leadershipContributionsToCommittee: financialDataResponse?.leadershipContributionsToCommittee
        )
    }
    
    // Helper method to convert Core Data object to response model
    private func convertToFinancialContributionsResponse(_ financialData: FinancialContributionsOverview) -> FinancialContributionsResponse {
        // Decode leadership contributions from JSON if available
        var leadershipContributions: [LeadershipContribution]? = nil
//        if let leadershipJSON = financialData.leadership_contributors,
//           let jsonData = leadershipJSON.data(using: .utf8) {
//            leadershipContributions = try? JSONDecoder().decode([LeadershipContribution].self, from: jsonData)
//        }
        
        return FinancialContributionsResponse(
            topic: financialData.topic ?? "",
            normalizedTopicName: financialData.normalized_topic_name ?? "",
            timestamp: financialData.timestamp,
            committeeId: financialData.committee_id ?? "",
            individualId: 0, // Not stored in Core Data
            fecFinancialContributionsSummaryText: financialData.fec_financial_contributions_summary_text ?? "",
            upvoteCount: financialData.upvote_count > 0 ? Int(financialData.upvote_count) : nil,
            downvoteCount: financialData.downvote_count > 0 ? Int(financialData.downvote_count) : nil,
            timeRangeOfData: financialData.time_range_of_data,
            cycleEndYear: financialData.cycle_end_year,
            committeeName: financialData.committee_name,
            queryType: financialData.query_type,
            debug: nil, // Not stored in Core Data
            percentContributions: nil,// financialData.percent_contributions, // You'll need to add this if you want to store it
            contributionTotals: nil, //financialData.contributions_totals_list, // You'll need to add this if you want to store it
            leadershipContributionsToCommittee: nil //financialData.leadership_contributions_list
        )
    }
    
    private func checkIfAlreadySaved() {
        guard !organizationName.isEmpty,
              let category = analysis?.category else { return }
        
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@ AND category == %@", organizationName, category.rawValue)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            isSaved = !results.isEmpty
            updateSaveButtonAppearance()
        } catch {
//            print("Error checking if answer is saved: \(error)")
            isSaved = false
            updateSaveButtonAppearance()
        }
    }
    

    /**
        Persistence Methods.
    */
    @objc private func saveButtonTapped() {
        guard let analysis = analysis, !organizationName.isEmpty else { return }
        let context = CoreDataPersistence().container.viewContext
        
        if isSaved {
            CoreDataHelper.removePersistedQueryAnswer(
                context: context,
                organizationName: self.organizationName,
                category: analysis.category,
                completion: { wasSaved in
                    self.isSaved = !wasSaved
                }
            )
        } else {
            // Save the analysis
            print("Overview will try to be saved with category: \(analysis.category)")
            // TODO: Make sure that the cateogry of each query is saved correctly.
            CoreDataHelper.addPersistedQueryAnswer(
                context: context,
                analysis: analysis,
                organizationName: self.organizationName,
                overviewPageCompletion: {
                    wasSaved in
                    self.isSaved = wasSaved
                    self.updateSaveButtonAppearance()
                }
            )
        }
        
        // Update UI immediately for unsave operation
        if !isSaved {
            updateSaveButtonAppearance()
        }
    }
    
    // MARK: - Google AdMob
    // TODO: Test This!!!
    /*
    *  Google Ad Mob
    *
    *  Test This!!!
    *
    */
    private func setupBannerAdUI() {
        bannerView = BannerView() // Use GADBannerView instead of BannerView
        //
        //
        //TODO: Put in correct adUnitID !!!
        //
        //
        bannerView.adUnitID = AdMobConfiguration.shared.getOverviewBannerAdUnitID()
        // bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // bannerView.adUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX" // Add your ad unit ID
        //
        //  ^^^^^^^^^^ this won't work if this is not correctly set!!
        //
        //
        bannerView.rootViewController = self // Critical!
        bannerView.delegate = self // Set delegate
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
    }
    
    private func setupBannerAdContent() {
        bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: view.frame.width)
        bannerView.load(Request()) // Use GADRequest instead of Request
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Load ad after view has appeared
        setupBannerAdContent()
    }
    
}

// MARK: - Leadership Demographics Pie Chart
private final class LeadershipDemographicsPieChartView: UIView {
    private var segments: [LeadershipDemographicsSegment] = []
    private var segmentLayers: [CAShapeLayer] = []
    private var percentageLabels: [UILabel] = []
    
    func configure(with segments: [LeadershipDemographicsSegment]) {
        self.segments = segments.filter { $0.percentage > 0 }
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        renderChart()
    }
    
    private func renderChart() {
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        percentageLabels.forEach { $0.removeFromSuperview() }
        segmentLayers.removeAll()
        percentageLabels.removeAll()
        
        guard !segments.isEmpty else { return }
        
        let diameter = min(bounds.width, bounds.height)
        let radius = diameter / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var startAngle = -CGFloat.pi / 2
        
        for segment in segments {
            let sliceAngle = CGFloat(segment.percentage) / 100.0 * 2.0 * CGFloat.pi
            let endAngle = startAngle + sliceAngle
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = Self.color(for: segment.group).cgColor
            shapeLayer.strokeColor = UIColor.white.cgColor
            shapeLayer.lineWidth = 2
            layer.addSublayer(shapeLayer)
            segmentLayers.append(shapeLayer)
            
            if segment.percentage >= 5 {
                addPercentageLabel(for: segment, startAngle: startAngle, endAngle: endAngle, center: center, radius: radius)
            }
            
            startAngle = endAngle
        }
    }
    
    private func addPercentageLabel(
        for segment: LeadershipDemographicsSegment,
        startAngle: CGFloat,
        endAngle: CGFloat,
        center: CGPoint,
        radius: CGFloat
    ) {
        let label = UILabel()
        label.text = "\(segment.percentage)%"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.sizeToFit()
        
        let midAngle = (startAngle + endAngle) / 2.0
        let labelRadius = radius * 0.62
        let labelSize = CGSize(width: max(label.bounds.width + 14, 44), height: 26)
        label.frame = CGRect(
            x: center.x + cos(midAngle) * labelRadius - labelSize.width / 2,
            y: center.y + sin(midAngle) * labelRadius - labelSize.height / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        addSubview(label)
        percentageLabels.append(label)
    }
    
    static func color(for group: String) -> UIColor {
        switch group {
        case "White":
            return UIColor.systemBlue
        case "Black or African American":
            return UIColor.systemOrange
        case "Hispanic or Latino":
            return UIColor.systemPink
        case "Asian or Pacific Islander", "East Asian or Pacific Islander":
            return UIColor.systemGreen
        case "Two or more races":
            return UIColor.systemPurple
        case "American Indian or Alaska Native":
            return UIColor.systemTeal
        default:
            return UIColor.systemGray
        }
    }
}

// MARK: - CompassAIHeaderViewDelegate
extension OverviewViewController: CompassAIHeaderViewDelegate {
    func headerViewBackButtonTapped(_ headerView: CompassAIHeaderView) {
        coordinator?.navigateToRoot()
    }
}

//
//extension OverviewViewController:UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//}

// Update the UIGestureRecognizerDelegate extension:
extension OverviewViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.navigationController?.viewControllers.count ?? 0 > 1
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - GADBannerViewDelegate
extension OverviewViewController {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner ad loaded successfully")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner ad failed to load: \(error.localizedDescription)")
    }
}
