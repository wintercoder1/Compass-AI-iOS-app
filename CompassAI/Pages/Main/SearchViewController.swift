//
//  SearchViewController.swift
//  CompassAI
//
//  Created by Steve on 1/17/26.
//

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
        headerView = addCompassAIHeader(title: "Compass AI", showBackButton: false)
        
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
    /*
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
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
    */
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
