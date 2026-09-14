//
//  SearchViewController.swift
//  CompassAI
//
//  Created by Steve on 1/17/26.
//

import UIKit
import Foundation
import CoreData
import GoogleMobileAds  // ← Add this import

// MARK: - Search View Controller
class SearchViewController: BaseViewController, BannerViewDelegate {  // ← Add BannerViewDelegate
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: CompassAIHeaderView!
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let searchTextField = UITextField()
    private let continueButton = UIButton(type: .system)
    private var footerView: CompassAIFooterView!
    
    // AdMob banner
    private var bannerView: BannerView!  // ← Add this
    
    // MARK: - Category Selector
    private var categorySelector: CategorySelectorView!
    
    // MARK: - Company Suggestions Dropdown
    private var companySuggestionDropdown: CompanySuggestionDropdownView!
    
    // MARK: - Hamburger Menu Components
    private let hamburgerButton = UIButton(type: .system)
    private var sidePanel: QueryHistorySidePanelView!
    private var dropdownDismissTapGesture: UITapGestureRecognizer!
    
    // MARK: - Properties
    var viewModel: SearchViewModel!
    private var filteredCompanies: [String] = []
    private var persistedQueryAnswers: [QueryAnswerObject] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategorySelector()
        setupCompanySuggestionDropdown()
        setupHamburgerMenu()
        setupSidePanel()
        setupDropdownDismissTapGesture()
        setupConstraints()
        updateUIForCurrentCategory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPersistedQueryAnswerObjects()
        categorySelector.updateCategoryDisplay()
        updateUIForCurrentCategory()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchPersistedQueryAnswerObjects()
        sidePanel.reloadData()
        loadBannerAd()  // ← Add this
    }
  
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        headerView = addCompassAIHeader(showBackButton: false, showInfoButton: true)
        headerView.delegate = self
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.systemGroupedBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupCard()
        setupBannerAd()  // ← Add this
        setupFooter()
    }
    
    // MARK: - AdMob Setup
    private func setupBannerAd() {
        bannerView = BannerView()
        bannerView.adUnitID = AdMobConfiguration.shared.getOverviewBannerAdUnitID()
        // bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"  // Test ad unit
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bannerView)
    }
    
    private func loadBannerAd() {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: view.frame.width - 40)
        bannerView.adSize = adSize
        bannerView.load(Request())
    }
    
    private func refreshQuizSidePanel() {
        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let answers = try context.fetch(req)
            sidePanel.updateData(answers, quizResults: SavedQuizResultStore.shared.load())
        } catch {
            print("Fetch error:", error)
            sidePanel.updateData([], quizResults: SavedQuizResultStore.shared.load())
        }
    }
    
    private func setupCategorySelector() {
        categorySelector = CategorySelectorView()
        categorySelector.translatesAutoresizingMaskIntoConstraints = false
        categorySelector.delegate = self
        contentView.addSubview(categorySelector)
    }
    
    private func setupCompanySuggestionDropdown() {
        companySuggestionDropdown = CompanySuggestionDropdownView()
        companySuggestionDropdown.translatesAutoresizingMaskIntoConstraints = false
        companySuggestionDropdown.delegate = self
        view.addSubview(companySuggestionDropdown)
    }
    
    private func setupHamburgerMenu() {
        hamburgerButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
        hamburgerButton.tintColor = .black
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        hamburgerButton.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
        view.addSubview(hamburgerButton)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToOpenPanel))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    private func setupSidePanel() {
        sidePanel = QueryHistorySidePanelView()
        sidePanel.translatesAutoresizingMaskIntoConstraints = false
        sidePanel.delegate = self
        view.addSubview(sidePanel)
        
        NSLayoutConstraint.activate([
            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
            sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupDropdownDismissTapGesture() {
        dropdownDismissTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        dropdownDismissTapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(dropdownDismissTapGesture)
    }
    
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 0  // Already squared
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOpacity = 0.1
        cardView.clipsToBounds = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "What organization do you want to find the political leaning of?"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        searchTextField.placeholder = "Type here..."
        searchTextField.font = UIFont.systemFont(ofSize: 16)
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.cornerRadius = 8
        searchTextField.backgroundColor = .white
        searchTextField.autocorrectionType = .no
        searchTextField.spellCheckingType = .no
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        searchTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 8
        continueButton.isEnabled = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(searchTextField)
        cardView.addSubview(continueButton)
        contentView.addSubview(cardView)
    }
    
    private func setupFooter() {
        footerView = addCompassAIFooter(to: scrollView, below: bannerView.bottomAnchor)  // ← Changed from cardView.bottomAnchor
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            categorySelector.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            categorySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categorySelector.heightAnchor.constraint(equalToConstant: 300),
            
            cardView.topAnchor.constraint(equalTo: categorySelector.topAnchor, constant: 75),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            searchTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 50),
            
            continueButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30),
            
            bannerView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 30),
            bannerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
        ])
        
        // Dropdown constraints
        NSLayoutConstraint.activate([
            companySuggestionDropdown.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            companySuggestionDropdown.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            companySuggestionDropdown.heightAnchor.constraint(equalToConstant: 350)
        ])
    }
    
    private var dropdownTopConstraint: NSLayoutConstraint?
    
    private func updateDropdownPosition() {
        let textFieldFrameInView = searchTextField.convert(searchTextField.bounds, to: view)
        dropdownTopConstraint?.isActive = false
        dropdownTopConstraint = companySuggestionDropdown.topAnchor.constraint(equalTo: view.topAnchor, constant: textFieldFrameInView.maxY + 8)
        dropdownTopConstraint?.isActive = true
    }
    
    // MARK: - Actions
    @objc private func hamburgerButtonTapped() {
        dismissAllDropdowns()
        fetchPersistedQueryAnswerObjects()
        sidePanel.toggle()
    }
    
    @objc private func textFieldDidChange() {
        updateContinueButton()
        updateCompanySuggestions()
    }
    
    @objc private func textFieldDidBeginEditing() {
        categorySelector.hideDropdown()
        updateCompanySuggestions()
    }
    
    @objc private func continueButtonTapped() {
        guard let text = searchTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        dismissAllDropdowns()
        let currentCategory = CurrentConfiguration.shared.currentCategory
        viewModel.searchOrganization(topic: text, category: currentCategory, from: self)
    }
    
    @objc private func dismissAllDropdowns() {
        searchTextField.resignFirstResponder()
        companySuggestionDropdown.hide()
        categorySelector.hideDropdown()
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let pointInCategorySelector = gesture.location(in: categorySelector)
        if !categorySelector.point(inside: pointInCategorySelector, with: nil) {
            categorySelector.hideDropdown()
        }
    }
    
    private func showAboutSheet() {
        dismissAllDropdowns()

        let aboutViewController = AboutCorporateCompassViewController()
        aboutViewController.modalPresentationStyle = .pageSheet

        if let sheet = aboutViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        present(aboutViewController, animated: true)
    }
    
    @objc private func handleSwipeToOpenPanel() {
        if !sidePanel.isVisible {
            dismissAllDropdowns()
            sidePanel.show()
        }
    }
    
    @objc private func handleEdgeSwipeToOpenPanel() {
        if !sidePanel.isVisible {
            dismissAllDropdowns()
            sidePanel.show()
        }
    }
    
    // MARK: - Helper Methods
    private func updateUIForCurrentCategory() {
        let currentCategory = CurrentConfiguration.shared.currentCategory
        titleLabel.text = currentCategory.searchPromptText
    }
    
    func prefillCompanyForSearch(_ company: String) {
        searchTextField.text = company
        updateContinueButton()
        updateCompanySuggestions()
        searchTextField.becomeFirstResponder()
    }
    
    func openSharedAnswer(topic: String, category: CurrentSearchCategory) {
        dismissAllDropdowns()
        CurrentConfiguration.shared.setCategory(category)
        searchTextField.text = topic
        updateUIForCurrentCategory()
        updateContinueButton()
        viewModel.searchOrganization(topic: topic, category: category, from: self)
    }
    
    private func updateContinueButton() {
        let hasText = !(searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        continueButton.isEnabled = hasText
        continueButton.backgroundColor = hasText ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.3)
    }
    
    private func updateCompanySuggestions() {
        let searchText = searchTextField.text ?? ""
        filteredCompanies = viewModel.getFilteredCompanies(for: searchText)
        companySuggestionDropdown.updateSuggestions(filteredCompanies)
        
        if !filteredCompanies.isEmpty && searchTextField.isFirstResponder {
            updateDropdownPosition()
            companySuggestionDropdown.show()
        } else {
            companySuggestionDropdown.hide()
        }
    }
    
    private func fetchPersistedQueryAnswerObjects() {
        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            self.persistedQueryAnswers = try context.fetch(req)
            sidePanel.updateData(persistedQueryAnswers, quizResults: SavedQuizResultStore.shared.load())
        } catch {
            print("Fetch error:", error)
        }
    }
    
    func openFavoriteAnswer(objectID: NSManagedObjectID) {
        sidePanelDidSelectItem(objectID)
    }
    
    func refreshFavoritesPanel() {
        fetchPersistedQueryAnswerObjects()
    }
}

// MARK: - BannerViewDelegate
extension SearchViewController {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner ad loaded successfully")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner ad failed to load: \(error.localizedDescription)")
    }
}

// MARK: - CategorySelectorViewDelegate
extension SearchViewController: CategorySelectorViewDelegate {
    func categorySelectorDidSelectCategory(_ category: CurrentSearchCategory) {
        updateUIForCurrentCategory()
    }
    func categorySelectorWillShowDropdown() {
        companySuggestionDropdown.hide()
    }
}

// MARK: - CompanySuggestionDropdownDelegate
extension SearchViewController: CompanySuggestionDropdownDelegate {
    func companySuggestionDidSelect(_ company: String) {
        searchTextField.text = company
        updateContinueButton()
        companySuggestionDropdown.hide()
        searchTextField.resignFirstResponder()
    }
}

// MARK: - CompassAIHeaderViewDelegate
extension SearchViewController: CompassAIHeaderViewDelegate {
    func headerViewInfoButtonTapped(_ headerView: CompassAIHeaderView) {
        showAboutSheet()
    }
}

// MARK: - SidePanelViewDelegate
extension SearchViewController: QueryHistorySidePanelViewDelegate {
    
    func sidePanelDidSelectItem(_ objectID: NSManagedObjectID) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: objectID) as! QueryAnswerObject
            
            if let topic = freshObject.topic {
                let analysis = createOrganizationAnalysis(from: freshObject)
                print("Tapped side panel with category: \(analysis.category)")
                viewModel.navigateToOverviewWithPersistedData(analysis: analysis, organizationName: topic, from: self)
                sidePanel.hide()
            }
        } catch {
            print("Error getting fresh object: \(error)")
        }
    }
    
    func sidePanelDidSelectQuizResult(_ savedQuizResult: SavedQuizResult) {
        sidePanel.hide()
        if let tabBarController,
           let quizVC = tabBarController.viewControllers?.compactMap({ $0 as? QuizViewController }).first {
            tabBarController.selectedIndex = 0
            quizVC.loadSavedQuizResult(savedQuizResult)
        }
    }
    
    func sidePanelDidDeleteItem(_ objectID: NSManagedObjectID, at indexPath: IndexPath) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: objectID) as! QueryAnswerObject
            
            if let topicToDelete = freshObject.topic,
               let category = CurrentSearchCategory(rawValue: freshObject.category ?? "") {
                CoreDataHelper.removePersistedQueryAnswer(context: context, organizationName: topicToDelete, category: category) { _ in
                    DispatchQueue.main.async {
                        if let index = self.persistedQueryAnswers.firstIndex(where: { $0.objectID == objectID }) {
                            self.persistedQueryAnswers.remove(at: index)
                        }
                        self.sidePanel.removeItem(at: indexPath.row)
                    }
                }
            }
        } catch {
            print("Error getting fresh object: \(error)")
        }
    }
    
    func sidePanelDidDeleteQuizResult(_ savedQuizResult: SavedQuizResult, at indexPath: IndexPath) {
        SavedQuizResultStore.shared.remove(id: savedQuizResult.id)
        sidePanel.removeQuizResult(at: indexPath.row)
    }
    
    private func createOrganizationAnalysis(from freshObject: QueryAnswerObject) -> OrganizationAnalysis {
        var financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
        
        if let financialContributions = freshObject.finanicial_contributions_overview {
            var percentContributions: PercentContributions?
            if let pcMO = financialContributions.percent_contributions {
                percentContributions = PercentContributions(
                    totalToDemocrats: Int(pcMO.total_to_democrats),
                    totalToRepublicans: Int(pcMO.total_to_republicans),
                    percentToDemocrats: pcMO.percent_to_democrats,
                    percentToRepublicans: pcMO.percent_to_republicans,
                    totalContributions: Int(pcMO.total_contributions)
                )
            }
            
            var contributionTotalsList = [ContributionTotal]()
            if let ctListMO = financialContributions.contributions_totals_list {
                for case let item as FinancialContribution_ContributionTotals_ListItem in ctListMO {
                    contributionTotalsList.append(ContributionTotal(
                        recipientID: item.recipient_id,
                        recipientName: item.recipient_name,
                        numberOfContributions: Int(item.number_of_contributions),
                        totalContributionAmount: Int(item.total_contribution_amount)
                    ))
                }
            }
            
            var leadershipContributionsList = [LeadershipContribution]()
            if let lcListMO = financialContributions.leadership_contributions_list {
                for case let item as FinancialContribution_LeadershipContributorsToCommittee_ListItem in lcListMO {
                    leadershipContributionsList.append(LeadershipContribution(
                        occupation: item.occupation ?? "",
                        name: item.name ?? "",
                        employer: item.employer ?? "",
                        transactionAmount: item.transaction_amount ?? ""
                    ))
                }
            }
            
            financialContributionsOverviewAnalysis = FinancialContributionsAnalysis(
                financialContributionsText: financialContributions.fec_financial_contributions_summary_text,
                committeeOrPACName: financialContributions.committee_name,
                committeeOrPACID: financialContributions.committee_id,
                percentContributions: percentContributions,
                contributionTotals: contributionTotalsList,
                leadershipContributionsToCommittee: leadershipContributionsList
            )
        }
        
        let category = CurrentSearchCategory(rawValue: freshObject.category ?? "") ?? CurrentSearchCategory.undefined
        let leadershipDemographicsAnalysis = category == .leadershipDemographics
            ? CoreDataHelper.decodeLeadershipDemographicsAnalysis(from: freshObject.context)
            : nil
        
        return OrganizationAnalysis(
            topic: freshObject.topic ?? "",
            lean: freshObject.lean ?? "Unknown",
            rating: Int(freshObject.rating),
            description: leadershipDemographicsAnalysis?.caveat ?? freshObject.context ?? "No description available",
            hasFinancialContributions: freshObject.created_with_financial_contributions_info,
            financialContributionsText: "No description available",
            financialContributionsOverviewAnalysis: financialContributionsOverviewAnalysis,
            leadershipDemographicsAnalysis: leadershipDemographicsAnalysis,
            category: category
        )
    }
}

// MARK: - About Sheet
private final class AboutCorporateCompassViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.accessibilityLabel = "Close"
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.spacing = 18
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        let titleLabel = UILabel()
        titleLabel.text = "About \(AppConfiguration.displayName)"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = aboutText
        bodyLabel.font = UIFont.systemFont(ofSize: 17)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(bodyLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    private var aboutText: String {
        return """
        \(AppConfiguration.displayName) helps you understand companies through public data, with the quiz as a leading feature for finding companies you may want to support.

        The quiz compares your stated priorities with public records and model-generated company assessments, then recommends companies to investigate. It is a buy-oriented matching tool, not advice to avoid or boycott any company.

        You can also search an organization directly to see how its associated political contributions are distributed, which recipients or committees appear in public records, and what aggregate demographic signals are available for company leadership. Leadership demographic analysis uses population-level surname data and should be understood as an estimate, not as a statement about any individual person.

        \(AppConfiguration.displayName) also includes additional exploratory categories, such as political leaning, environmental impact, DEI friendliness, technology innovation, immigration support, and wokeness. These are secondary analysis tools meant to add context, comparison, and perspective.

        Results are based on public records, regulatory filings, company sources, and available datasets. \(AppConfiguration.displayName) does not endorse any company, candidate, party, policy position, or demographic conclusion.
        """
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Quiz View Controller
final class QuizViewController: BaseViewController {
    private enum Step {
        case loading
        case importance
        case stances
        case categories
        case results
        case error(String)
    }

    var onCompanySelected: ((String) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: CompassAIHeaderView!
    private let cardView = UIView()
    private let stackView = UIStackView()
    private let buttonStackView = UIStackView()
    private let backButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let hamburgerButton = UIButton(type: .system)
    private let favoriteButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private var bannerView: BannerView!
    private var footerView: CompassAIFooterView!
    private var sidePanel: QueryHistorySidePanelView!

    private var step: Step = .loading
    private var definition: QuizDefinitionResponse?
    private var result: QuizResultResponse?
    private var weights: [String: Int] = [:]
    private var stances: [String: QuizOptionValue] = [:]
    private var selectedCategories = Set<String>()
    private var selectedDealbreakers = Set<String>()
    private var requireVerified = false
    private var isCurrentResultSaved = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        renderLoading()
        loadDefinition()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBannerAd()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        headerView = addCompassAIHeader(showBackButton: false, showInfoButton: true)
        headerView.delegate = self
        
        hamburgerButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
        hamburgerButton.tintColor = .black
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        hamburgerButton.addTarget(self, action: #selector(quizHamburgerButtonTapped), for: .touchUpInside)
        view.addSubview(hamburgerButton)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .systemGroupedBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 0
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOpacity = 0.1
        cardView.clipsToBounds = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        setupBannerAd()
        setupFooter()
        setupQuizSidePanel()

        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stackView)
        
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.addTarget(self, action: #selector(favoriteQuizResultTapped), for: .touchUpInside)
        favoriteButton.isHidden = true
        updateFavoriteButtonAppearance()
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.addTarget(self, action: #selector(shareQuizResultTapped), for: .touchUpInside)
        shareButton.isHidden = true
        updateShareButtonAppearance()

        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 12

        var backConfiguration = UIButton.Configuration.bordered()
        backConfiguration.title = "Back"
        backButton.configuration = backConfiguration
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        var nextConfiguration = UIButton.Configuration.filled()
        nextConfiguration.title = "Next"
        nextConfiguration.baseBackgroundColor = .systemBlue
        nextConfiguration.baseForegroundColor = .white
        nextButton.configuration = nextConfiguration
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    private func setupQuizSidePanel() {
        sidePanel = QueryHistorySidePanelView()
        sidePanel.translatesAutoresizingMaskIntoConstraints = false
        sidePanel.delegate = self
        view.addSubview(sidePanel)
    }
    
    private func setupBannerAd() {
        bannerView = BannerView()
        bannerView.adUnitID = AdMobConfiguration.shared.getOverviewBannerAdUnitID()
        bannerView.rootViewController = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bannerView)
    }
    
    private func setupFooter() {
        footerView = CompassAIFooterView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(footerView)
    }
    
    private func loadBannerAd() {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: view.frame.width - 40)
        bannerView.adSize = adSize
        bannerView.load(Request())
    }
    
    private func refreshQuizSidePanel() {
        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let answers = try context.fetch(req)
            sidePanel.updateData(answers, quizResults: SavedQuizResultStore.shared.load())
        } catch {
            print("Fetch error:", error)
            sidePanel.updateData([], quizResults: SavedQuizResultStore.shared.load())
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -26),

            bannerView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 24),
            bannerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            footerView.topAnchor.constraint(equalTo: bannerView.bottomAnchor, constant: 30),
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 400),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
            sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadDefinition() {
        NetworkManager.shared.getQuizDefinition { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let definition):
                    self?.definition = definition
                    self?.weights = [:]
                    let availableCategories = definition.categories.options.filter(\.available)
                    if availableCategories.count == 1, let category = availableCategories.first {
                        self?.selectedCategories.insert(category.value)
                    }
                    self?.step = availableCategories.isEmpty ? .error("The quiz is not ready yet. No recommendation categories currently have company data.") : .importance
                case .failure(let error):
                    self?.step = .error(error.localizedDescription)
                }
                self?.renderCurrentStep()
            }
        }
    }

    private func renderCurrentStep(resetScroll: Bool = true) {
        let previousOffset = scrollView.contentOffset
        favoriteButton.isHidden = true
        shareButton.isHidden = true
        clearStack()
        switch step {
        case .loading:
            renderLoading()
        case .importance:
            renderImportance()
        case .stances:
            renderStances()
        case .categories:
            renderCategories()
        case .results:
            renderResults()
        case .error(let message):
            renderError(message)
        }
        if resetScroll {
            scrollView.setContentOffset(.zero, animated: false)
        } else {
            view.layoutIfNeeded()
            let maxY = max(-scrollView.adjustedContentInset.top, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
            let restoredY = min(max(previousOffset.y, -scrollView.adjustedContentInset.top), maxY)
            scrollView.setContentOffset(CGPoint(x: previousOffset.x, y: restoredY), animated: false)
        }
    }

    private func renderLoading() {
        clearStack()
        stackView.addArrangedSubview(makeTitleLabel("Quiz"))
        let label = makeBodyLabel("Loading quiz questions...")
        stackView.addArrangedSubview(label)
    }

    private func renderImportance() {
        guard let definition else { return }
        stackView.addArrangedSubview(makeTitleLabel("Quiz"))
        stackView.addArrangedSubview(makeBodyLabel(definition.importance.prompt))
        let note = makeBodyLabel("Weights are relative. Marking every issue high is the same as marking every issue low.")
        note.textColor = .secondaryLabel
        stackView.addArrangedSubview(note)
        addQuizDisclaimerIfAvailable()

        for issue in definition.importance.issues {
            let section = makeSectionStack(title: issue.label, subtitle: issue.help)
            section.addArrangedSubview(makeImportanceChoiceGrid(for: issue.key, options: definition.importance.options))
            stackView.addArrangedSubview(section)
        }
        addNavigationButtons(backHidden: true, nextTitle: "Next")
    }

    private func renderStances() {
        guard let definition else { return }
        let visibleStances = definition.stances.filter { (weights[$0.key] ?? 0) > 0 }
        stackView.addArrangedSubview(makeTitleLabel("Your Preferences"))
        stackView.addArrangedSubview(makeBodyLabel("Answer the direction questions for the issues you marked as important."))

        if visibleStances.isEmpty {
            stackView.addArrangedSubview(makeBodyLabel("No direction questions are needed because no issue has been marked as important."))
        }

        for question in visibleStances {
            let section = makeSectionStack(title: question.prompt, subtitle: question.help)
            section.addArrangedSubview(makeStanceChoiceList(for: question.key, options: question.options))
            stackView.addArrangedSubview(section)
        }
        addQuizDisclaimerIfAvailable()
        addNavigationButtons(backHidden: false, nextTitle: "Next")
    }

    private func renderCategories() {
        guard let definition else { return }
        stackView.addArrangedSubview(makeTitleLabel("Where Should We Match?"))
        stackView.addArrangedSubview(makeBodyLabel(definition.categories.prompt))

        for category in definition.categories.options {
            let control = makeCheckboxButton(
                title: "\(category.label) (\(category.companyCount))",
                selected: selectedCategories.contains(category.value),
                enabled: category.available,
                action: #selector(categoryTapped(_:))
            )
            control.accessibilityIdentifier = category.value
            stackView.addArrangedSubview(control)
        }

        stackView.addArrangedSubview(makeDivider())
        stackView.addArrangedSubview(makeSectionTitle(definition.dealbreakers.prompt))
        stackView.addArrangedSubview(makeBodyLabel(definition.dealbreakers.help))
        for option in definition.dealbreakers.options {
            let control = makeCheckboxButton(
                title: option.label,
                selected: selectedDealbreakers.contains(option.value),
                enabled: true,
                action: #selector(dealbreakerTapped(_:))
            )
            control.accessibilityIdentifier = option.value
            stackView.addArrangedSubview(control)
        }

        stackView.addArrangedSubview(makeDivider())
        stackView.addArrangedSubview(makeSectionTitle(definition.verification.prompt))
        stackView.addArrangedSubview(makeVerificationChoiceList(options: definition.verification.options))
        addQuizDisclaimerIfAvailable()
        addNavigationButtons(backHidden: false, nextTitle: "See Results")
    }

    private func renderResults() {
        guard let result else { return }
        isCurrentResultSaved = SavedQuizResultStore.shared.contains(shareToken: result.shareToken)
        updateFavoriteButtonAppearance()
        favoriteButton.isHidden = result.shareToken == nil
        stackView.addArrangedSubview(makeTitleLabel("Quiz Results"))

        for category in result.results {
            let categoryStack = makeSectionStack(
                title: category.label,
                subtitle: "\(category.considered) considered · \(category.excluded.didNotMatch) did not match · \(category.excluded.couldNotVerify) could not be verified"
            )
            if category.allLowConfidence == true {
                categoryStack.addArrangedSubview(makeMutedBodyLabel("This list is provisional because data coverage is thin for this category."))
            }
            if category.nothingRated == true {
                categoryStack.addArrangedSubview(makeMutedBodyLabel("We do not hold ratings on the issues you weighted for this category, so these are companies on the shelf rather than scored matches."))
            }
            if category.recommendations.isEmpty {
                categoryStack.addArrangedSubview(makeBodyLabel("Nothing cleared your rules. Try relaxing a dealbreaker or allowing unverified companies."))
            }
            for recommendation in category.recommendations {
                categoryStack.addArrangedSubview(makeRecommendationView(recommendation))
            }
            if !category.alternatives.isEmpty {
                let alternativeNames = category.alternatives.prefix(5).map { alternative in
                    let band = alternative.band ?? "listed"
                    return "\(alternative.topic) (\(band))"
                }.joined(separator: "\n")
                categoryStack.addArrangedSubview(makeBodyLabel("More in this category:\n\(alternativeNames)"))
            }
            stackView.addArrangedSubview(categoryStack)
        }

        stackView.addArrangedSubview(makeDivider())
        stackView.addArrangedSubview(makeSectionTitle("Methodology"))
        stackView.addArrangedSubview(makeBodyLabel(result.methodologyNote))
        stackView.addArrangedSubview(makeMutedBodyLabel("As of \(result.asOf)"))
        if let disclaimer = result.disclaimer ?? definition?.disclaimer {
            stackView.addArrangedSubview(makeMutedBodyLabel(disclaimer))
        }
        addResultActionButtonRowIfAvailable()
        if let shareWarning = result.shareWarning, result.shareToken != nil {
            stackView.addArrangedSubview(makeMutedBodyLabel(shareWarning))
        }
        addNavigationButtons(backHidden: false, nextTitle: "Start Over")
    }

    private func renderError(_ message: String) {
        stackView.addArrangedSubview(makeTitleLabel("Quiz Unavailable"))
        stackView.addArrangedSubview(makeBodyLabel(message))
        addQuizDisclaimerIfAvailable()
        addNavigationButtons(backHidden: true, nextTitle: "Retry")
    }

    private func makeRecommendationView(_ recommendation: QuizRecommendation) -> UIView {
        let coverageText = "Coverage \(Int((recommendation.coverage * 100).rounded()))%"
        let matchText = recommendation.match.map { "Match \(Int($0.rounded()))" } ?? "No match score"
        let leadingText: String
        if recommendation.bestAvailable == true && (recommendation.band == "mixed" || recommendation.band == "poor" || recommendation.match == nil) {
            leadingText = "Best match in this category"
        } else {
            leadingText = recommendation.bandText ?? "Match"
        }
        let section = makeSectionStack(
            title: recommendation.topic,
            subtitle: "\(leadingText) · \(matchText) · \(coverageText)"
        )
        if let headline = recommendation.headline, !headline.isEmpty {
            section.addArrangedSubview(makeBodyLabel(headline))
        }
        if recommendation.lowConfidence == true, let note = recommendation.confidenceNote {
            section.addArrangedSubview(makeMutedBodyLabel(note))
        }
        for row in recommendation.issueRows {
            let explanation: String
            if row.known {
                explanation = "\(row.label): \(row.valueText ?? "Known") · \(row.stanceText ?? "")"
            } else {
                explanation = "\(row.label): \(row.missingNote ?? "Not known")"
            }
            section.addArrangedSubview(makeBodyLabel(explanation))
        }
        if !recommendation.notKnown.isEmpty {
            section.addArrangedSubview(makeBodyLabel("Not known: \(recommendation.notKnown.joined(separator: ", "))"))
        }
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = "Search \(recommendation.topic)"
        configuration.image = UIImage(systemName: "magnifyingglass")
        configuration.imagePadding = 8
        button.configuration = configuration
        button.addTarget(self, action: #selector(resultCompanyTapped(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = recommendation.topic
        section.addArrangedSubview(button)
        return section
    }

    private func submitQuiz() {
        guard let definition else { return }
        var dealbreakers = Array(selectedDealbreakers)
        if requireVerified {
            dealbreakers.append(definition.verification.key)
        }
        let submission = QuizSubmissionRequest(
            quizVersion: definition.quizVersion,
            weights: weights,
            stances: stances,
            categories: Array(selectedCategories),
            dealbreakers: dealbreakers
        )
        clearStack()
        stackView.addArrangedSubview(makeTitleLabel("Scoring Matches"))
        stackView.addArrangedSubview(makeBodyLabel("Calculating recommendations..."))
        NetworkManager.shared.submitQuiz(submission) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):
                    self?.result = result
                    self?.isCurrentResultSaved = SavedQuizResultStore.shared.contains(shareToken: result.shareToken)
                    self?.step = .results
                case .failure(let error):
                    self?.step = .error(error.localizedDescription)
                }
                self?.renderCurrentStep()
            }
        }
    }

    private func validateCurrentStep() -> String? {
        guard let definition else { return "The quiz has not loaded yet." }
        switch step {
        case .importance:
            return weights.values.contains(where: { $0 > 0 }) ? nil : "At least one issue must matter to you."
        case .stances:
            let missing = definition.stances.filter { (weights[$0.key] ?? 0) > 0 && stances[$0.key] == nil }
            return missing.isEmpty ? nil : "Please answer every visible preference question."
        case .categories:
            return selectedCategories.isEmpty ? "Choose at least one available category." : nil
        default:
            return nil
        }
    }

    private func showValidationAlert(_ message: String) {
        let alert = UIAlertController(title: "Quiz", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func nextTapped() {
        if case .error = step {
            step = .loading
            renderLoading()
            loadDefinition()
            return
        }
        if case .results = step {
            result = nil
            isCurrentResultSaved = false
            weights = [:]
            stances.removeAll()
            selectedCategories.removeAll()
            selectedDealbreakers.removeAll()
            requireVerified = false
            step = .importance
            renderCurrentStep()
            return
        }
        if let validationMessage = validateCurrentStep() {
            showValidationAlert(validationMessage)
            return
        }
        switch step {
        case .importance:
            step = .stances
            renderCurrentStep()
        case .stances:
            step = .categories
            renderCurrentStep()
        case .categories:
            submitQuiz()
        default:
            break
        }
    }

    @objc private func backTapped() {
        switch step {
        case .stances:
            step = .importance
        case .categories:
            step = .stances
        case .results:
            step = .categories
        default:
            break
        }
        renderCurrentStep()
    }

    @objc private func importanceOptionTapped(_ sender: UIButton) {
        guard
            let definition,
            let selection = parseSelectionIdentifier(sender.accessibilityIdentifier),
            definition.importance.options.indices.contains(selection.index),
            let value = definition.importance.options[selection.index].value.intValue
        else {
            return
        }
        
        weights[selection.key] = value
        if value == 0 {
            stances.removeValue(forKey: selection.key)
        }
        renderCurrentStep(resetScroll: false)
    }

    @objc private func stanceOptionTapped(_ sender: UIButton) {
        guard
            let definition,
            let selection = parseSelectionIdentifier(sender.accessibilityIdentifier),
            let question = definition.stances.first(where: { $0.key == selection.key }),
            question.options.indices.contains(selection.index)
        else {
            return
        }
        
        stances[selection.key] = question.options[selection.index].value
        renderCurrentStep(resetScroll: false)
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier else { return }
        if selectedCategories.contains(key) {
            selectedCategories.remove(key)
        } else {
            selectedCategories.insert(key)
        }
        renderCurrentStep(resetScroll: false)
    }

    @objc private func dealbreakerTapped(_ sender: UIButton) {
        guard let definition, let key = sender.accessibilityIdentifier else { return }
        if selectedDealbreakers.contains(key) {
            selectedDealbreakers.remove(key)
        } else if selectedDealbreakers.count < definition.dealbreakers.max {
            selectedDealbreakers.insert(key)
        } else {
            showValidationAlert("Pick up to \(definition.dealbreakers.max) dealbreakers.")
            return
        }
        renderCurrentStep(resetScroll: false)
    }

    @objc private func verificationOptionTapped(_ sender: UIButton) {
        guard
            let definition,
            let selection = parseSelectionIdentifier(sender.accessibilityIdentifier),
            definition.verification.options.indices.contains(selection.index),
            let value = definition.verification.options[selection.index].value.boolValue
        else {
            return
        }
        
        requireVerified = value
        renderCurrentStep(resetScroll: false)
    }

    @objc private func resultCompanyTapped(_ sender: UIButton) {
        guard let company = sender.accessibilityIdentifier else { return }
        onCompanySelected?(company)
    }
    
    @objc private func quizHamburgerButtonTapped() {
        refreshQuizSidePanel()
        sidePanel.toggle()
    }
    
    @objc private func favoriteQuizResultTapped() {
        guard let result, let shareToken = result.shareToken else {
            showValidationAlert("This quiz result cannot be saved because it does not include a share token.")
            return
        }
        
        if SavedQuizResultStore.shared.contains(shareToken: shareToken) {
            SavedQuizResultStore.shared.remove(shareToken: shareToken)
            isCurrentResultSaved = false
        } else {
            let savedResult = SavedQuizResult(
                shareToken: shareToken,
                title: quizResultTitle(for: result),
                subtitle: quizResultSubtitle(for: result)
            )
            SavedQuizResultStore.shared.save(savedResult)
            isCurrentResultSaved = true
        }
        
        refreshQuizSidePanel()
        updateFavoriteButtonAppearance()
    }
    
    @objc private func shareQuizResultTapped() {
        guard let shareToken = result?.shareToken,
              let url = CompassDeepLink.quizResultURL(token: shareToken) else {
            showValidationAlert("This quiz result cannot be shared because it does not include a share link.")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = shareButton
        present(activityViewController, animated: true)
    }
    
    func loadSavedQuizResult(_ savedQuizResult: SavedQuizResult) {
        sidePanel.hide()
        loadQuizResult(token: savedQuizResult.shareToken, loadingTitle: "Loading Saved Quiz", markAsSaved: true)
    }
    
    func loadSharedQuizResult(token: String) {
        loadQuizResult(token: token, loadingTitle: "Loading Shared Quiz", markAsSaved: SavedQuizResultStore.shared.contains(shareToken: token))
    }
    
    private func loadQuizResult(token: String, loadingTitle: String, markAsSaved: Bool) {
        sidePanel.hide()
        clearStack()
        stackView.addArrangedSubview(makeTitleLabel(loadingTitle))
        stackView.addArrangedSubview(makeBodyLabel("Fetching quiz result..."))
        
        NetworkManager.shared.getQuizResult(token: token) { [weak self] response in
            DispatchQueue.main.async {
                switch response {
                case .success(let result):
                    self?.result = result
                    self?.isCurrentResultSaved = markAsSaved
                    self?.step = .results
                case .failure(let error):
                    self?.step = .error(error.localizedDescription)
                }
                self?.renderCurrentStep()
            }
        }
    }

    private func showAboutSheet() {
        let aboutViewController = AboutCorporateCompassViewController()
        aboutViewController.modalPresentationStyle = .pageSheet

        if let sheet = aboutViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        present(aboutViewController, animated: true)
    }
    
    private func updateFavoriteButtonAppearance() {
        let heartImageName = isCurrentResultSaved ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: heartImageName), for: .normal)
        favoriteButton.tintColor = isCurrentResultSaved ? .black : .systemGray
        favoriteButton.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        favoriteButton.layer.cornerRadius = 22
        favoriteButton.layer.shadowColor = UIColor.black.cgColor
        favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        favoriteButton.layer.shadowRadius = 4
        favoriteButton.layer.shadowOpacity = 0.1
        favoriteButton.accessibilityLabel = isCurrentResultSaved ? "Unsave quiz result" : "Save quiz result"
    }
    
    private func updateShareButtonAppearance() {
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareButton.tintColor = .systemBlue
        shareButton.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        shareButton.layer.cornerRadius = 22
        shareButton.layer.shadowColor = UIColor.black.cgColor
        shareButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        shareButton.layer.shadowRadius = 4
        shareButton.layer.shadowOpacity = 0.1
        shareButton.accessibilityLabel = "Share quiz result"
    }
    
    private func addResultActionButtonRowIfAvailable() {
        guard result?.shareToken != nil else { return }
        
        favoriteButton.isHidden = false
        shareButton.isHidden = false
        
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fill
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        row.addArrangedSubview(favoriteButton)
        row.addArrangedSubview(shareButton)
        
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 46),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        stackView.addArrangedSubview(row)
    }
    
    private func quizResultTitle(for result: QuizResultResponse) -> String {
        let labels = result.results.map { $0.label }
        guard !labels.isEmpty else { return "Quiz Result" }
        if labels.count == 1 {
            return labels[0]
        }
        return "\(labels[0]) + \(labels.count - 1) more"
    }
    
    private func quizResultSubtitle(for result: QuizResultResponse) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let savedDate = formatter.string(from: Date())
        return "Quiz result · Saved \(savedDate)"
    }

    private func addNavigationButtons(backHidden: Bool, nextTitle: String) {
        buttonStackView.arrangedSubviews.forEach { view in
            buttonStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        backButton.isHidden = backHidden
        nextButton.configuration?.title = nextTitle
        buttonStackView.addArrangedSubview(backButton)
        buttonStackView.addArrangedSubview(nextButton)
        stackView.addArrangedSubview(buttonStackView)
    }

    private func makeImportanceChoiceGrid(for issueKey: String, options: [QuizChoice]) -> UIStackView {
        let outerStackView = UIStackView()
        outerStackView.axis = .vertical
        outerStackView.spacing = 8
        
        for rowStart in stride(from: 0, to: options.count, by: 2) {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = 8
            
            for index in rowStart..<min(rowStart + 2, options.count) {
                let option = options[index]
                let selected = weights[issueKey].map { option.value.intValue == $0 } ?? false
                let button = makeChoiceButton(
                    title: option.label,
                    selected: selected,
                    action: #selector(importanceOptionTapped(_:))
                )
                button.accessibilityIdentifier = selectionIdentifier(key: issueKey, index: index)
                rowStackView.addArrangedSubview(button)
            }
            
            if rowStackView.arrangedSubviews.count == 1 {
                let spacer = UIView()
                rowStackView.addArrangedSubview(spacer)
            }
            
            outerStackView.addArrangedSubview(rowStackView)
        }
        
        return outerStackView
    }

    private func makeStanceChoiceList(for questionKey: String, options: [QuizChoice]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        
        for (index, option) in options.enumerated() {
            let button = makeChoiceButton(
                title: option.label,
                selected: option.value == stances[questionKey],
                action: #selector(stanceOptionTapped(_:))
            )
            button.accessibilityIdentifier = selectionIdentifier(key: questionKey, index: index)
            stackView.addArrangedSubview(button)
        }
        
        return stackView
    }

    private func makeVerificationChoiceList(options: [QuizChoice]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        
        for (index, option) in options.enumerated() {
            let selected = option.value.boolValue == requireVerified
            let button = makeChoiceButton(
                title: option.label,
                selected: selected,
                action: #selector(verificationOptionTapped(_:))
            )
            button.accessibilityIdentifier = selectionIdentifier(key: "verification", index: index)
            stackView.addArrangedSubview(button)
        }
        
        return stackView
    }

    private func makeChoiceButton(title: String, selected: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        configuration.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        configuration.imagePadding = 8
        configuration.imagePlacement = .leading
        configuration.baseForegroundColor = selected ? .systemBlue : .label
        configuration.background.strokeColor = selected ? .systemBlue : .systemGray4
        configuration.background.strokeWidth = selected ? 1.5 : 1
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func selectionIdentifier(key: String, index: Int) -> String {
        return "\(key)|\(index)"
    }

    private func parseSelectionIdentifier(_ identifier: String?) -> (key: String, index: Int)? {
        guard let identifier else { return nil }
        let parts = identifier.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, let index = Int(parts[1]) else { return nil }
        return (parts[0], index)
    }

    private func makeCheckboxButton(title: String, selected: Bool, enabled: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
        configuration.imagePadding = 8
        configuration.imagePlacement = .leading
        configuration.baseForegroundColor = enabled ? (selected ? .systemBlue : .label) : .tertiaryLabel
        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.isEnabled = enabled
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }
    
    private func makeMutedBodyLabel(_ text: String) -> UILabel {
        let label = makeBodyLabel(text)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func addQuizDisclaimerIfAvailable() {
        guard let disclaimer = definition?.disclaimer else { return }
        stackView.addArrangedSubview(makeMutedBodyLabel(disclaimer))
    }

    private func makeSectionStack(title: String, subtitle: String?) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.addArrangedSubview(makeSectionTitle(title))
        if let subtitle, !subtitle.isEmpty {
            let label = makeBodyLabel(subtitle)
            label.textColor = .secondaryLabel
            stack.addArrangedSubview(label)
        }
        return stack
    }

    private func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    private func clearStack() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

extension QuizViewController: CompassAIHeaderViewDelegate {
    func headerViewInfoButtonTapped(_ headerView: CompassAIHeaderView) {
        showAboutSheet()
    }
}

extension QuizViewController: QueryHistorySidePanelViewDelegate {
    func sidePanelDidSelectItem(_ objectID: NSManagedObjectID) {
        sidePanel.hide()
        guard let tabBarController,
              let searchVC = tabBarController.viewControllers?.compactMap({ $0 as? SearchViewController }).first else {
            return
        }
        tabBarController.selectedIndex = 1
        searchVC.openFavoriteAnswer(objectID: objectID)
    }
    
    func sidePanelDidDeleteItem(_ objectID: NSManagedObjectID, at indexPath: IndexPath) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: objectID) as! QueryAnswerObject
            if let topicToDelete = freshObject.topic,
               let category = CurrentSearchCategory(rawValue: freshObject.category ?? "") {
                CoreDataHelper.removePersistedQueryAnswer(context: context, organizationName: topicToDelete, category: category) { _ in
                    DispatchQueue.main.async {
                        self.sidePanel.removeItem(at: indexPath.row)
                        if let tabBarController = self.tabBarController,
                           let searchVC = tabBarController.viewControllers?.compactMap({ $0 as? SearchViewController }).first {
                            searchVC.refreshFavoritesPanel()
                        }
                    }
                }
            }
        } catch {
            print("Error deleting favorited answer from quiz menu: \(error)")
        }
    }
    
    func sidePanelDidSelectQuizResult(_ savedQuizResult: SavedQuizResult) {
        loadSavedQuizResult(savedQuizResult)
    }
    
    func sidePanelDidDeleteQuizResult(_ savedQuizResult: SavedQuizResult, at indexPath: IndexPath) {
        SavedQuizResultStore.shared.remove(id: savedQuizResult.id)
        sidePanel.removeQuizResult(at: indexPath.row)
        if result?.shareToken == savedQuizResult.shareToken {
            isCurrentResultSaved = false
            renderCurrentStep(resetScroll: false)
        }
    }
}

/*
import UIKit
import Foundation
import CoreData

// MARK: - Search View Controller
class SearchViewController: BaseViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var headerView: CompassAIHeaderView!
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let searchTextField = UITextField()
    private let continueButton = UIButton(type: .system)
    private var footerView: CompassAIFooterView!
    
    // MARK: - Category Selector
    private var categorySelector: CategorySelectorView!
    
    // MARK: - Company Suggestions Dropdown
    private var companySuggestionDropdown: CompanySuggestionDropdownView!
    
    // MARK: - Hamburger Menu Components
    private let hamburgerButton = UIButton(type: .system)
    private var sidePanel: QueryHistorySidePanelView!
    
    // MARK: - Properties
    var viewModel: SearchViewModel!
    private var filteredCompanies: [String] = []
    private var persistedQueryAnswers: [QueryAnswerObject] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategorySelector()
        setupCompanySuggestionDropdown()
        setupHamburgerMenu()
        setupSidePanel()
        setupConstraints()
        updateUIForCurrentCategory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPersistedQueryAnswerObjects()
        categorySelector.updateCategoryDisplay()
        updateUIForCurrentCategory()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchPersistedQueryAnswerObjects()
        sidePanel.reloadData()
    }
  
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        headerView = addCompassAIHeader(showBackButton: false)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.systemGroupedBackground
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupCard()
        setupFooter()
        
    }
    
    private func setupCategorySelector() {
        categorySelector = CategorySelectorView()
        categorySelector.translatesAutoresizingMaskIntoConstraints = false
        categorySelector.delegate = self
        contentView.addSubview(categorySelector)
    }
    
    private func setupCompanySuggestionDropdown() {
        companySuggestionDropdown = CompanySuggestionDropdownView()
        companySuggestionDropdown.translatesAutoresizingMaskIntoConstraints = false
        companySuggestionDropdown.delegate = self
        // Add to main view (not contentView) so it appears above everything including footer
        view.addSubview(companySuggestionDropdown)
    }
    
    private func setupHamburgerMenu() {
        hamburgerButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
        hamburgerButton.tintColor = .black
        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
        hamburgerButton.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
        view.addSubview(hamburgerButton)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToOpenPanel))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        // Enable edge swipe gesture (like back gesture)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false // Disable default back gesture
//        let edgeSwipe = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgeSwipeToOpenPanel))
//        edgeSwipe.edges = .left
//        view.addGestureRecognizer(edgeSwipe)
    }
    
    private func setupSidePanel() {
        sidePanel = QueryHistorySidePanelView()
        sidePanel.translatesAutoresizingMaskIntoConstraints = false
        sidePanel.delegate = self
        view.addSubview(sidePanel)
        
        NSLayoutConstraint.activate([
            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
            sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sidePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 0  // ← Changed from 16 to 0
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.layer.shadowRadius = 16
        cardView.layer.shadowOpacity = 0.1
        cardView.clipsToBounds = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "What organization do you want to find the political leaning of?"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Search text field - original style
        searchTextField.placeholder = "Type here..."
        searchTextField.font = UIFont.systemFont(ofSize: 16)
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.cornerRadius = 8
        searchTextField.backgroundColor = .white
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        searchTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 8
        continueButton.isEnabled = false
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(searchTextField)
        cardView.addSubview(continueButton)
        contentView.addSubview(cardView)
    }
    
    
    private func setupFooter() {
        footerView = addCompassAIFooter(to: scrollView, below: cardView.bottomAnchor)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            categorySelector.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            categorySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categorySelector.heightAnchor.constraint(equalToConstant: 300),
            
            cardView.topAnchor.constraint(equalTo: categorySelector.topAnchor, constant: 75),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            searchTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            searchTextField.heightAnchor.constraint(equalToConstant: 50),
            
            continueButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 50),
            continueButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30),
            
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
        ])
        
        // Dropdown constraints - positioned in main view coordinate space
        // We'll update the position dynamically when showing
        NSLayoutConstraint.activate([
            companySuggestionDropdown.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            companySuggestionDropdown.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            companySuggestionDropdown.heightAnchor.constraint(equalToConstant: 350)
        ])
    }
    
    // Store the dropdown top constraint so we can update it
    private var dropdownTopConstraint: NSLayoutConstraint?
    
    private func updateDropdownPosition() {
        // Convert the text field's frame to the main view's coordinate space
        let textFieldFrameInView = searchTextField.convert(searchTextField.bounds, to: view)
        
        // Remove old constraint if exists
        dropdownTopConstraint?.isActive = false
        
        // Create new constraint positioning dropdown below text field
        dropdownTopConstraint = companySuggestionDropdown.topAnchor.constraint(equalTo: view.topAnchor, constant: textFieldFrameInView.maxY + 8)
        dropdownTopConstraint?.isActive = true
    }
    
    // MARK: - Actions
    @objc private func hamburgerButtonTapped() {
        dismissAllDropdowns()
        sidePanel.toggle()
    }
    
    @objc private func textFieldDidChange() {
        updateContinueButton()
        updateCompanySuggestions()
    }
    
    @objc private func textFieldDidBeginEditing() {
        categorySelector.hideDropdown()
        updateCompanySuggestions()
    }
    
    @objc private func continueButtonTapped() {
        guard let text = searchTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        dismissAllDropdowns()
        let currentCategory = CurrentConfiguration.shared.currentCategory
        viewModel.searchOrganization(topic: text, category: currentCategory, from: self)
    }
    
    @objc private func dismissAllDropdowns() {
        searchTextField.resignFirstResponder()
        companySuggestionDropdown.hide()
        categorySelector.hideDropdown()
    }
    
    @objc private func handleSwipeToOpenPanel() {
        if !sidePanel.isVisible {
            dismissAllDropdowns()
            sidePanel.show()
        }
    }
    
    // TODO: Probably delete this.
    @objc private func handleEdgeSwipeToOpenPanel() {
        if !sidePanel.isVisible {
            dismissAllDropdowns()
            sidePanel.show()
        }
    }
    
    // MARK: - Helper Methods
    private func updateUIForCurrentCategory() {
        let currentCategory = CurrentConfiguration.shared.currentCategory
        titleLabel.text = currentCategory.searchPromptText
    }
    
    private func updateContinueButton() {
        let hasText = !(searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        continueButton.isEnabled = hasText
        continueButton.backgroundColor = hasText ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.3)
    }
    
    private func updateCompanySuggestions() {
        let searchText = searchTextField.text ?? ""
        filteredCompanies = viewModel.getFilteredCompanies(for: searchText)
        companySuggestionDropdown.updateSuggestions(filteredCompanies)
        
        if !filteredCompanies.isEmpty && searchTextField.isFirstResponder {
            // Update dropdown position before showing
            updateDropdownPosition()
            companySuggestionDropdown.show()
        } else {
            companySuggestionDropdown.hide()
        }
    }
    
    private func fetchPersistedQueryAnswerObjects() {
        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            self.persistedQueryAnswers = try context.fetch(req)
            sidePanel.updateData(persistedQueryAnswers)
        } catch {
            print("Fetch error:", error)
        }
    }
}

// MARK: - CategorySelectorViewDelegate
extension SearchViewController: CategorySelectorViewDelegate {
    func categorySelectorDidSelectCategory(_ category: CurrentSearchCategory) {
        updateUIForCurrentCategory()
    }
    func categorySelectorWillShowDropdown() {
        companySuggestionDropdown.hide()
    }
}

// MARK: - CompanySuggestionDropdownDelegate
extension SearchViewController: CompanySuggestionDropdownDelegate {
    func companySuggestionDidSelect(_ company: String) {
        searchTextField.text = company
        updateContinueButton()
        companySuggestionDropdown.hide()
        searchTextField.resignFirstResponder()
    }
}

// MARK: - SidePanelViewDelegate
extension SearchViewController: QueryHistorySidePanelViewDelegate {
    
    func sidePanelDidSelectItem(_ objectID: NSManagedObjectID) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: objectID) as! QueryAnswerObject
            
            if let topic = freshObject.topic {
                let analysis = createOrganizationAnalysis(from: freshObject)
                print("Tapped side panel with category: \(analysis.category)")
                viewModel.navigateToOverviewWithPersistedData(analysis: analysis, organizationName: topic, from: self)
                sidePanel.hide()
            }
        } catch {
            print("Error getting fresh object: \(error)")
        }
    }
    
    func sidePanelDidDeleteItem(_ objectID: NSManagedObjectID, at indexPath: IndexPath) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: objectID) as! QueryAnswerObject
            
            if let topicToDelete = freshObject.topic {
                CoreDataHelper.removePersistedQueryAnswer(context: context, organizationName: topicToDelete) { _ in
                    DispatchQueue.main.async {
                        if let index = self.persistedQueryAnswers.firstIndex(where: { $0.objectID == objectID }) {
                            self.persistedQueryAnswers.remove(at: index)
                        }
                        self.sidePanel.removeItem(at: indexPath.row)
                    }
                }
            }
        } catch {
            print("Error getting fresh object: \(error)")
        }
    }
    
    private func createOrganizationAnalysis(from freshObject: QueryAnswerObject) -> OrganizationAnalysis {
        var financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
        
        if let financialContributions = freshObject.finanicial_contributions_overview {
            var percentContributions: PercentContributions?
            if let pcMO = financialContributions.percent_contributions {
                percentContributions = PercentContributions(
                    totalToDemocrats: Int(pcMO.total_to_democrats),
                    totalToRepublicans: Int(pcMO.total_to_republicans),
                    percentToDemocrats: pcMO.percent_to_democrats,
                    percentToRepublicans: pcMO.percent_to_republicans,
                    totalContributions: Int(pcMO.total_contributions)
                )
            }
            
            var contributionTotalsList = [ContributionTotal]()
            if let ctListMO = financialContributions.contributions_totals_list {
                for case let item as FinancialContribution_ContributionTotals_ListItem in ctListMO {
                    contributionTotalsList.append(ContributionTotal(
                        recipientID: item.recipient_id,
                        recipientName: item.recipient_name,
                        numberOfContributions: Int(item.number_of_contributions),
                        totalContributionAmount: Int(item.total_contribution_amount)
                    ))
                }
            }
            
            var leadershipContributionsList = [LeadershipContribution]()
            if let lcListMO = financialContributions.leadership_contributions_list {
                for case let item as FinancialContribution_LeadershipContributorsToCommittee_ListItem in lcListMO {
                    leadershipContributionsList.append(LeadershipContribution(
                        occupation: item.occupation ?? "",
                        name: item.name ?? "",
                        employer: item.employer ?? "",
                        transactionAmount: item.transaction_amount ?? ""
                    ))
                }
            }
            
            financialContributionsOverviewAnalysis = FinancialContributionsAnalysis(
                financialContributionsText: financialContributions.fec_financial_contributions_summary_text,
                committeeOrPACName: financialContributions.committee_name,
                committeeOrPACID: financialContributions.committee_id,
                percentContributions: percentContributions,
                contributionTotals: contributionTotalsList,
                leadershipContributionsToCommittee: leadershipContributionsList
            )
        }
        
        return OrganizationAnalysis(
            topic: freshObject.topic ?? "",
            lean: freshObject.lean ?? "Unknown",
            rating: Int(freshObject.rating),
            description: freshObject.context ?? "No description available",
            hasFinancialContributions: freshObject.created_with_financial_contributions_info,
            financialContributionsText: "No description available",
            financialContributionsOverviewAnalysis: financialContributionsOverviewAnalysis,
            category: CurrentSearchCategory(rawValue: freshObject.category ?? "") ?? CurrentSearchCategory.undefined
        )
    }
}
*/
