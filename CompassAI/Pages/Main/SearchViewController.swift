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
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissAllDropdowns))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
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
            
            categorySelector.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            categorySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            categorySelector.heightAnchor.constraint(equalToConstant: 300),
            
            cardView.topAnchor.constraint(equalTo: categorySelector.topAnchor, constant: 60),
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
    
    func sidePanelDidSelectItem(_ item: QueryAnswerObject) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
            
            if let topic = freshObject.topic {
                let analysis = createOrganizationAnalysis(from: freshObject)
                viewModel.navigateToOverviewWithPersistedData(analysis: analysis, organizationName: topic, from: self)
                sidePanel.hide()
            }
        } catch {
            print("Error getting fresh object: \(error)")
        }
    }
    
    func sidePanelDidDeleteItem(_ item: QueryAnswerObject, at indexPath: IndexPath) {
        let persistence = CoreDataPersistence()
        let context = persistence.container.viewContext
        
        do {
            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
            
            if let topicToDelete = freshObject.topic {
                CoreDataHelper.removePersistedQueryAnswer(context: context, organizationName: topicToDelete) { _ in
                    DispatchQueue.main.async {
                        if let index = self.persistedQueryAnswers.firstIndex(where: { $0.objectID == item.objectID }) {
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
            category: .politicalLeaning
        )
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Edge case. IDK.
        let locationInCategorySelectorCard = touch.location(in: cardView)
        if cardView.bounds.contains(locationInCategorySelectorCard) {
            return true
        }// ^^ Maybe find a better way to do this?
        
        // Don't intercept touches on the text field
        if touch.view == searchTextField {
            return false
        }
        
        // Don't intercept touches on category selector
        let locationInCategorySelector = touch.location(in: categorySelector)
        if categorySelector.bounds.contains(locationInCategorySelector) {
            return false
        }
        
        // Allow gesture to proceed for touches outside dropdown (so dismissAllDropdowns gets called)
        return true
    }
}

////
////  SearchViewController.swift
////  CompassAI
////
////  Created by Steve on 1/17/26.
////
//
//import UIKit
//import Foundation
//import CoreData
//
//// MARK: - Search View Controller
//class SearchViewController: BaseViewController {
//    
//    // MARK: - UI Components
//    private let scrollView = UIScrollView()
//    private let contentView = UIView()
//    private var headerView: CompassAIHeaderView!
//    private let cardView = UIView()
//    private let titleLabel = UILabel()
//    private let searchTextField = UITextField()
//    private let continueButton = UIButton(type: .system)
//    private var footerView: CompassAIFooterView!
//    
//    // MARK: - Category Selector
//    private var categorySelector: CategorySelectorView!
//    
//    // MARK: - Company Suggestions Dropdown
//    private var companySuggestionDropdown: CompanySuggestionDropdownView!
//    
//    // MARK: - Hamburger Menu Components
//    private let hamburgerButton = UIButton(type: .system)
//    private var sidePanel: QueryHistorySidePanelView!
//    
//    // MARK: - Properties
//    var viewModel: SearchViewModel!
//    private var filteredCompanies: [String] = []
//    private var persistedQueryAnswers: [QueryAnswerObject] = []
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCategorySelector()
//        setupCompanySuggestionDropdown()
//        setupHamburgerMenu()
//        setupSidePanel()
//        setupConstraints()
//        updateUIForCurrentCategory()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        fetchPersistedQueryAnswerObjects()
//        categorySelector.updateCategoryDisplay()
//        updateUIForCurrentCategory()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        fetchPersistedQueryAnswerObjects()
//        sidePanel.reloadData()
//    }
//  
//    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = UIColor.systemGroupedBackground
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        headerView = addCompassAIHeader(title: "Compass AI", showBackButton: false)
//        
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.backgroundColor = UIColor.systemGroupedBackground
//        scrollView.contentInsetAdjustmentBehavior = .never
//        scrollView.isScrollEnabled = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        
//        setupCard()
//        setupFooter()
//        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissAllDropdowns))
//        tapGestureRecognizer.cancelsTouchesInView = false
//        tapGestureRecognizer.delegate = self
//        view.addGestureRecognizer(tapGestureRecognizer)
//    }
//    
//    private func setupCategorySelector() {
//        categorySelector = CategorySelectorView()
//        categorySelector.translatesAutoresizingMaskIntoConstraints = false
//        categorySelector.delegate = self
//        contentView.addSubview(categorySelector)
//    }
//    
//    private func setupCompanySuggestionDropdown() {
//        companySuggestionDropdown = CompanySuggestionDropdownView()
//        companySuggestionDropdown.translatesAutoresizingMaskIntoConstraints = false
//        companySuggestionDropdown.delegate = self
//        cardView.addSubview(companySuggestionDropdown)
//    }
//    
//    private func setupHamburgerMenu() {
//        hamburgerButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
//        hamburgerButton.tintColor = .black
//        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
//        hamburgerButton.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
//        view.addSubview(hamburgerButton)
//        
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToOpenPanel))
//        swipeRight.direction = .right
//        view.addGestureRecognizer(swipeRight)
//    }
//    
//    private func setupSidePanel() {
//        sidePanel = QueryHistorySidePanelView()
//        sidePanel.translatesAutoresizingMaskIntoConstraints = false
//        sidePanel.delegate = self
//        view.addSubview(sidePanel)
//        
//        NSLayoutConstraint.activate([
//            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
//            sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            sidePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    private func setupCard() {
//        cardView.backgroundColor = .white
//        cardView.layer.cornerRadius = 16
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
//        cardView.layer.shadowRadius = 16
//        cardView.layer.shadowOpacity = 0.1
//        cardView.clipsToBounds = false
//        cardView.translatesAutoresizingMaskIntoConstraints = false
//        
//        titleLabel.text = "What organization do you want to find the political leaning of?"
//        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
//        titleLabel.textColor = .black
//        titleLabel.numberOfLines = 0
//        titleLabel.textAlignment = .center
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Search text field - styled to match website
//        searchTextField.placeholder = "Type here..."
//        searchTextField.font = UIFont.systemFont(ofSize: 16)
//        searchTextField.borderStyle = .none
//        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
//        searchTextField.layer.borderWidth = 1
//        searchTextField.layer.cornerRadius = 25
//        searchTextField.backgroundColor = .white
//        searchTextField.translatesAutoresizingMaskIntoConstraints = false
//        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
//        searchTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
//        
//        // Add padding to text field
//        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
//        searchTextField.leftView = paddingView
//        searchTextField.leftViewMode = .always
//        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
//        searchTextField.rightView = rightPaddingView
//        searchTextField.rightViewMode = .always
//        
//        continueButton.setTitle("Continue", for: .normal)
//        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
//        continueButton.setTitleColor(.white, for: .normal)
//        continueButton.layer.cornerRadius = 8
//        continueButton.isEnabled = false
//        continueButton.translatesAutoresizingMaskIntoConstraints = false
//        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
//        
//        cardView.addSubview(titleLabel)
//        cardView.addSubview(searchTextField)
//        cardView.addSubview(continueButton)
//        contentView.addSubview(cardView)
//    }
//    
//    private func setupFooter() {
//        footerView = addCompassAIFooter(to: scrollView, below: cardView.bottomAnchor)
//    }
//    
//    // MARK: - Constraints
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
//            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
//            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),
//            
//            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//            
//            categorySelector.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
//            categorySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            categorySelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//            categorySelector.heightAnchor.constraint(equalToConstant: 300),
//            
//            cardView.topAnchor.constraint(equalTo: categorySelector.topAnchor, constant: 60),
//            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//            
//            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
//            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            
//            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
//            searchTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            searchTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            searchTextField.heightAnchor.constraint(equalToConstant: 50),
//            
//            // Company suggestion dropdown - positioned directly below text field
//            companySuggestionDropdown.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
//            companySuggestionDropdown.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
//            companySuggestionDropdown.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
//            companySuggestionDropdown.heightAnchor.constraint(equalToConstant: 350), // Max height for dropdown
//            
//            continueButton.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 24),
//            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            continueButton.heightAnchor.constraint(equalToConstant: 50),
//            continueButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30),
//            
//            contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
//        ])
//    }
//    
//    // MARK: - Actions
//    @objc private func hamburgerButtonTapped() {
//        dismissAllDropdowns()
//        sidePanel.toggle()
//    }
//    
//    @objc private func textFieldDidChange() {
//        updateContinueButton()
//        updateCompanySuggestions()
//    }
//    
//    @objc private func textFieldDidBeginEditing() {
//        categorySelector.hideDropdown()
//        updateCompanySuggestions()
//    }
//    
//    @objc private func continueButtonTapped() {
//        guard let text = searchTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
//        dismissAllDropdowns()
//        let currentCategory = CurrentConfiguration.shared.currentCategory
//        viewModel.searchOrganization(topic: text, category: currentCategory, from: self)
//    }
//    
//    @objc private func dismissAllDropdowns() {
//        searchTextField.resignFirstResponder()
//        companySuggestionDropdown.hide()
//        categorySelector.hideDropdown()
//    }
//    
//    @objc private func handleSwipeToOpenPanel() {
//        if !sidePanel.isVisible {
//            dismissAllDropdowns()
//            sidePanel.show()
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private func updateUIForCurrentCategory() {
//        let currentCategory = CurrentConfiguration.shared.currentCategory
//        titleLabel.text = currentCategory.searchPromptText
//    }
//    
//    private func updateContinueButton() {
//        let hasText = !(searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
//        continueButton.isEnabled = hasText
//        continueButton.backgroundColor = hasText ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.3)
//    }
//    
//    private func updateCompanySuggestions() {
//        let searchText = searchTextField.text ?? ""
//        filteredCompanies = viewModel.getFilteredCompanies(for: searchText)
//        companySuggestionDropdown.updateSuggestions(filteredCompanies)
//        
//        if !filteredCompanies.isEmpty && searchTextField.isFirstResponder {
//            companySuggestionDropdown.show()
//        } else {
//            companySuggestionDropdown.hide()
//        }
//    }
//    
//    private func fetchPersistedQueryAnswerObjects() {
//        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
//        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            self.persistedQueryAnswers = try context.fetch(req)
//            sidePanel.updateData(persistedQueryAnswers)
//        } catch {
//            print("Fetch error:", error)
//        }
//    }
//}
//
//// MARK: - CategorySelectorViewDelegate
//extension SearchViewController: CategorySelectorViewDelegate {
//    func categorySelectorDidSelectCategory(_ category: CurrentSearchCategory) {
//        updateUIForCurrentCategory()
//    }
//}
//
//// MARK: - CompanySuggestionDropdownDelegate
//extension SearchViewController: CompanySuggestionDropdownDelegate {
//    func companySuggestionDidSelect(_ company: String) {
//        searchTextField.text = company
//        updateContinueButton()
//        companySuggestionDropdown.hide()
//        searchTextField.resignFirstResponder()
//    }
//}
//
//// MARK: - SidePanelViewDelegate
//extension SearchViewController: QueryHistorySidePanelViewDelegate {
//    
//    func sidePanelDidSelectItem(_ item: QueryAnswerObject) {
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
//            
//            if let topic = freshObject.topic {
//                let analysis = createOrganizationAnalysis(from: freshObject)
//                viewModel.navigateToOverviewWithPersistedData(analysis: analysis, organizationName: topic, from: self)
//                sidePanel.hide()
//            }
//        } catch {
//            print("Error getting fresh object: \(error)")
//        }
//    }
//    
//    func sidePanelDidDeleteItem(_ item: QueryAnswerObject, at indexPath: IndexPath) {
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
//            
//            if let topicToDelete = freshObject.topic {
//                CoreDataHelper.removePersistedQueryAnswer(context: context, organizationName: topicToDelete) { _ in
//                    DispatchQueue.main.async {
//                        if let index = self.persistedQueryAnswers.firstIndex(where: { $0.objectID == item.objectID }) {
//                            self.persistedQueryAnswers.remove(at: index)
//                        }
//                        self.sidePanel.removeItem(at: indexPath.row)
//                    }
//                }
//            }
//        } catch {
//            print("Error getting fresh object: \(error)")
//        }
//    }
//    
//    private func createOrganizationAnalysis(from freshObject: QueryAnswerObject) -> OrganizationAnalysis {
//        var financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
//        
//        if let financialContributions = freshObject.finanicial_contributions_overview {
//            var percentContributions: PercentContributions?
//            if let pcMO = financialContributions.percent_contributions {
//                percentContributions = PercentContributions(
//                    totalToDemocrats: Int(pcMO.total_to_democrats),
//                    totalToRepublicans: Int(pcMO.total_to_republicans),
//                    percentToDemocrats: pcMO.percent_to_democrats,
//                    percentToRepublicans: pcMO.percent_to_republicans,
//                    totalContributions: Int(pcMO.total_contributions)
//                )
//            }
//            
//            var contributionTotalsList = [ContributionTotal]()
//            if let ctListMO = financialContributions.contributions_totals_list {
//                for case let item as FinancialContribution_ContributionTotals_ListItem in ctListMO {
//                    contributionTotalsList.append(ContributionTotal(
//                        recipientID: item.recipient_id,
//                        recipientName: item.recipient_name,
//                        numberOfContributions: Int(item.number_of_contributions),
//                        totalContributionAmount: Int(item.total_contribution_amount)
//                    ))
//                }
//            }
//            
//            var leadershipContributionsList = [LeadershipContribution]()
//            if let lcListMO = financialContributions.leadership_contributions_list {
//                for case let item as FinancialContribution_LeadershipContributorsToCommittee_ListItem in lcListMO {
//                    leadershipContributionsList.append(LeadershipContribution(
//                        occupation: item.occupation ?? "",
//                        name: item.name ?? "",
//                        employer: item.employer ?? "",
//                        transactionAmount: item.transaction_amount ?? ""
//                    ))
//                }
//            }
//            
//            financialContributionsOverviewAnalysis = FinancialContributionsAnalysis(
//                financialContributionsText: financialContributions.fec_financial_contributions_summary_text,
//                committeeOrPACName: financialContributions.committee_name,
//                committeeOrPACID: financialContributions.committee_id,
//                percentContributions: percentContributions,
//                contributionTotals: contributionTotalsList,
//                leadershipContributionsToCommittee: leadershipContributionsList
//            )
//        }
//        
//        return OrganizationAnalysis(
//            topic: freshObject.topic ?? "",
//            lean: freshObject.lean ?? "Unknown",
//            rating: Int(freshObject.rating),
//            description: freshObject.context ?? "No description available",
//            hasFinancialContributions: freshObject.created_with_financial_contributions_info,
//            financialContributionsText: "No description available",
//            financialContributionsOverviewAnalysis: financialContributionsOverviewAnalysis,
//            category: .politicalLeaning
//        )
//    }
//}
//
//// MARK: - UIGestureRecognizerDelegate
//extension SearchViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        // Don't intercept touches on the text field
//        if touch.view == searchTextField {
//            return false
//        }
//        
//        // Don't intercept touches on company suggestion dropdown
//        let locationInDropdown = touch.location(in: companySuggestionDropdown)
//        if companySuggestionDropdown.bounds.contains(locationInDropdown) && companySuggestionDropdown.isVisible {
//            return false
//        }
//        
//        // Don't intercept touches on category selector
//        let locationInCategorySelector = touch.location(in: categorySelector)
//        if categorySelector.bounds.contains(locationInCategorySelector) {
//            return false
//        }
//        
//        return true
//    }
//}

//import UIKit
//import Foundation
//import CoreData
////import CurrentConfiguration
//
//// MARK: - Search View Controller
//class SearchViewController: BaseViewController {
//    
//    // MARK: - UI Components
//    private let scrollView = UIScrollView()
//    private let contentView = UIView()
//    private var headerView: CompassAIHeaderView!
//    private let cardView = UIView()
//    private let titleLabel = UILabel()
//    private let searchTextField = UITextField()
//    private let tableView = UITableView()
//    private let continueButton = UIButton(type: .system)
//    private var footerView: CompassAIFooterView!
//    
//    // MARK: - Category Selector
//    private var categorySelector: CategorySelectorView!
//    
//    // MARK: - Hamburger Menu Components
//    private let hamburgerButton = UIButton(type: .system)
//    private var sidePanel: QueryHistorySidePanelView!
//    
//    // MARK: - Properties
//    var viewModel: SearchViewModel!
//    private var filteredCompanies: [String] = []
//    private var persistedQueryAnswers: [QueryAnswerObject] = []
//    private var isDropdownVisible = false
//    private var tableViewHeightConstraint: NSLayoutConstraint!
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCategorySelector()
//        setupHamburgerMenu()
//        setupSidePanel()
//        setupConstraints()
//        updateUIForCurrentCategory()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        fetchPersistedQueryAnswerObjects()
//        // Update category display in case it changed elsewhere
//        categorySelector.updateCategoryDisplay()
//        updateUIForCurrentCategory()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        fetchPersistedQueryAnswerObjects()
//        sidePanel.reloadData()
//    }
//  
//    // MARK: - UI Setup
//    private func setupUI() {
//        view.backgroundColor = UIColor.systemGroupedBackground
//        
//        // Hide the navigation bar since we're using our custom header
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        
//        // Add the custom header with larger font size and no back button
//        headerView = addCompassAIHeader(title: "Compass AI", showBackButton: false)
//        
//        // Configure scroll view
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.backgroundColor = UIColor.systemGroupedBackground
//        scrollView.contentInsetAdjustmentBehavior = .never
//        scrollView.isScrollEnabled = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        
//        // Main card
//        setupCard()
//        
//        // Footer
//        setupFooter()
//        
//        // Dropdown table
//        setupDropdown()
//        
//        // Tap gesture to dismiss dropdown
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissDropdown))
//        tapGestureRecognizer.cancelsTouchesInView = false
//        tapGestureRecognizer.delegate = self
//        view.addGestureRecognizer(tapGestureRecognizer)
//    }
//    
//    private func setupCategorySelector() {
//        categorySelector = CategorySelectorView()
//        categorySelector.translatesAutoresizingMaskIntoConstraints = false
//        categorySelector.delegate = self
//        contentView.addSubview(categorySelector)
//    }
//    
//    private func setupHamburgerMenu() {
//        // Hamburger button
//        hamburgerButton.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
//        hamburgerButton.tintColor = .black
//        hamburgerButton.translatesAutoresizingMaskIntoConstraints = false
//        hamburgerButton.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
//        view.addSubview(hamburgerButton)
//        
//        // Swipe gesture to open side panel (swipe right to open left panel)
//        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToOpenPanel))
//        swipeRight.direction = .right
//        view.addGestureRecognizer(swipeRight)
//    }
//    
//    private func setupSidePanel() {
//        sidePanel = QueryHistorySidePanelView()
//        sidePanel.translatesAutoresizingMaskIntoConstraints = false
//        sidePanel.delegate = self
//        view.addSubview(sidePanel)
//        
//        NSLayoutConstraint.activate([
//            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
//            sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            sidePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    private func setupCard() {
//        cardView.backgroundColor = .white
//        cardView.layer.cornerRadius = 16
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
//        cardView.layer.shadowRadius = 16
//        cardView.layer.shadowOpacity = 0.1
//        cardView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Title
//        titleLabel.text = "What organization do you want to find the political leaning of?"
//        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
//        titleLabel.textColor = .black
//        titleLabel.numberOfLines = 0
//        titleLabel.textAlignment = .center
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Search text field
//        searchTextField.placeholder = "Type here..."
//        searchTextField.font = UIFont.systemFont(ofSize: 16)
//        searchTextField.borderStyle = .roundedRect
//        searchTextField.layer.borderColor = UIColor.systemGray4.cgColor
//        searchTextField.layer.borderWidth = 1
//        searchTextField.layer.cornerRadius = 8
//        searchTextField.backgroundColor = .white
//        searchTextField.translatesAutoresizingMaskIntoConstraints = false
//        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
//        searchTextField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
//        
//        // Continue button
//        continueButton.setTitle("Continue", for: .normal)
//        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
//        continueButton.setTitleColor(.white, for: .normal)
//        continueButton.layer.cornerRadius = 8
//        continueButton.isEnabled = false
//        continueButton.translatesAutoresizingMaskIntoConstraints = false
//        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
//        
//        cardView.addSubview(titleLabel)
//        cardView.addSubview(searchTextField)
//        cardView.addSubview(continueButton)
//        contentView.addSubview(cardView)
//    }
//    
//    private func setupDropdown() {
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.backgroundColor = .white
//        tableView.layer.cornerRadius = 8
//        tableView.layer.borderColor = UIColor.systemGray4.cgColor
//        tableView.layer.borderWidth = 1
//        tableView.layer.shadowColor = UIColor.black.cgColor
//        tableView.layer.shadowOffset = CGSize(width: 0, height: 4)
//        tableView.layer.shadowRadius = 8
//        tableView.layer.shadowOpacity = 0.1
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.isUserInteractionEnabled = true
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CompanyCell")
//        tableView.isHidden = true
//        
//        cardView.addSubview(tableView)
//        
//        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
//        tableViewHeightConstraint.isActive = true
//    }
//    
//    private func setupFooter() {
//        footerView = addCompassAIFooter(
//            to: scrollView,
//            below: cardView.bottomAnchor
//        )
//    }
//    
//    // MARK: - Constraints
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // Hamburger button
//            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            hamburgerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
//            hamburgerButton.widthAnchor.constraint(equalToConstant: 30),
//            hamburgerButton.heightAnchor.constraint(equalToConstant: 30),
//            
//            // Scroll view - positioned flush against the header
//            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            // Content view - with spacing from scroll view top
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//            
//            // Category selector - at the top of content
//            categorySelector.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
//            categorySelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            categorySelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//            categorySelector.heightAnchor.constraint(equalToConstant: 350), // Extra height for dropdown
//            
//            // Card view - below category selector
//            cardView.topAnchor.constraint(equalTo: categorySelector.topAnchor, constant: 80),
//            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
//            
//            // Title
//            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
//            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            
//            // Search text field
//            searchTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
//            searchTextField.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            searchTextField.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            searchTextField.heightAnchor.constraint(equalToConstant: 50),
//            
//            // Table view (dropdown)
//            tableView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
//            tableView.leadingAnchor.constraint(equalTo: searchTextField.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor),
//            
//            // Continue button
//            continueButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
//            continueButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
//            continueButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
//            continueButton.heightAnchor.constraint(equalToConstant: 50),
//            continueButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -30),
//            
//            // Content view height
//            contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
//        ])
//    }
//    
//    // MARK: - Actions
//    @objc private func hamburgerButtonTapped() {
//        categorySelector.hideDropdown()
//        sidePanel.toggle()
//    }
//    
//    @objc private func textFieldDidChange() {
//        updateContinueButton()
//        updateDropdown()
//    }
//    
//    @objc private func textFieldDidBeginEditing() {
//        categorySelector.hideDropdown()
//        updateDropdown()
//    }
//    
//    @objc private func continueButtonTapped() {
//        guard let text = searchTextField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            return
//        }
//        
//        // Pass the current category to the view model
//        let currentCategory =  CurrentConfiguration.shared.currentCategory
//        //
//        // TODO: Make this work with all the other categories.
//        //       For now it only work with Political leaning.
//        // TODO: Fix the endpoints for the other types of analyses.
//        //       I think the iOS client  code is mostly ok tbh. While test further.
//        viewModel.searchOrganization(topic: text, category: currentCategory, from: self)
//    }
//    
//    @objc private func dismissDropdown() {
//        searchTextField.resignFirstResponder()
//        hideDropdown()
//        categorySelector.hideDropdown()
//    }
//    
//    @objc private func handleSwipeToOpenPanel() {
//        if !sidePanel.isVisible {
//            categorySelector.hideDropdown()
//            sidePanel.show()
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private func updateUIForCurrentCategory() {
//        let currentCategory = CurrentConfiguration.shared.currentCategory
//        titleLabel.text = currentCategory.searchPromptText
//    }
//    
//    private func updateContinueButton() {
//        let hasText = !(searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
//        continueButton.isEnabled = hasText
//        continueButton.backgroundColor = hasText ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.3)
//    }
//    
//    private func updateDropdown() {
//        let searchText = searchTextField.text ?? ""
//        filteredCompanies = viewModel.getFilteredCompanies(for: searchText)
//        
//        if !filteredCompanies.isEmpty && searchTextField.isFirstResponder {
//            showDropdown()
//        } else {
//            hideDropdown()
//        }
//        
//        tableView.reloadData()
//    }
//    
//    private func showDropdown() {
//        isDropdownVisible = true
//        tableView.isHidden = false
//        
//        let maxHeight: CGFloat = 200
//        let calculatedHeight = min(CGFloat(filteredCompanies.count * 44), maxHeight)
//        
//        tableViewHeightConstraint.constant = calculatedHeight
//        
//        UIView.animate(withDuration: 0.3) {
//            self.view.layoutIfNeeded()
//        }
//    }
//    
//    private func hideDropdown() {
//        isDropdownVisible = false
//        tableViewHeightConstraint.constant = 0
//        
//        UIView.animate(withDuration: 0.3) {
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//            self.tableView.isHidden = true
//        }
//    }
//    
//    private func fetchPersistedQueryAnswerObjects() {
//        let req: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
//        req.sortDescriptors = [NSSortDescriptor(key: #keyPath(QueryAnswerObject.date_persisted), ascending: false)]
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            self.persistedQueryAnswers = try context.fetch(req)
//            // Update the side panel with the fetched data
//            sidePanel.updateData(persistedQueryAnswers)
//            
//            // Debug: Check if relationships are loaded
//            for qa in self.persistedQueryAnswers {
//                if qa.created_with_financial_contributions_info {
//                    print("Topic: \(qa.topic ?? "nil")")
//                    print("Has financial relationship: \(qa.finanicial_contributions_overview != nil)")
//                    if let financial = qa.finanicial_contributions_overview {
//                        print("  - Committee: \(financial.committee_name ?? "nil")")
//                        print("  - Summary preview: \(financial.fec_financial_contributions_summary_text?.prefix(50) ?? "nil")")
//                    }
//                }
//            }
//        } catch {
//            print("Fetch error:", error)
//        }
//    }
//}
//
//// MARK: - CategorySelectorViewDelegate
//extension SearchViewController: CategorySelectorViewDelegate {
//    func categorySelectorDidSelectCategory(_ category:  CurrentSearchCategory) {
//        updateUIForCurrentCategory()
//    }
//}
//
//// MARK: - SidePanelViewDelegate
//extension SearchViewController: QueryHistorySidePanelViewDelegate {
//    
//    func sidePanelDidSelectItem(_ item: QueryAnswerObject) {
//        // Get a fresh copy of the object
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
//            
//            if let topic = freshObject.topic {
//                let analysis = createOrganizationAnalysis(from: freshObject)
//                
//                print("\n\nPersisted freshObject for topic: \(topic)")
//                print("Persisted freshObject:\n\n      \(freshObject)\n\n")
//                print("Analysis object for topic: \(topic)")
//                print("Analysis:\n\n      \(analysis)")
//                
//                // Navigate to overview page
//                viewModel.navigateToOverviewWithPersistedData(
//                    analysis: analysis,
//                    organizationName: topic,
//                    from: self
//                )
//                
//                sidePanel.hide()
//            }
//        } catch {
//            print("Error getting fresh object: \(error)")
//        }
//    }
//    
//    func sidePanelDidDeleteItem(_ item: QueryAnswerObject, at indexPath: IndexPath) {
//        let persistence = CoreDataPersistence()
//        let context = persistence.container.viewContext
//        
//        do {
//            let freshObject = try context.existingObject(with: item.objectID) as! QueryAnswerObject
//            
//            if let topicToDelete = freshObject.topic {
//                CoreDataHelper.removePersistedQueryAnswer(
//                    context: context,
//                    organizationName: topicToDelete,
//                    completion: { _ in
//                        DispatchQueue.main.async {
//                            // Remove from local array
//                            if let index = self.persistedQueryAnswers.firstIndex(where: { $0.objectID == item.objectID }) {
//                                self.persistedQueryAnswers.remove(at: index)
//                            }
//                            // Update side panel
//                            self.sidePanel.removeItem(at: indexPath.row)
//                        }
//                    }
//                )
//            }
//        } catch {
//            print("Error getting fresh object: \(error)")
//        }
//    }
//    
//    // MARK: - Helper to create OrganizationAnalysis
//    private func createOrganizationAnalysis(from freshObject: QueryAnswerObject) -> OrganizationAnalysis {
//        var financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
//        
//        if let financialContributions = freshObject.finanicial_contributions_overview {
//            // Percent contributions
//            var percentContributions: PercentContributions?
//            if let percentContributionsManagedObject = financialContributions.percent_contributions {
//                percentContributions = PercentContributions(
//                    totalToDemocrats: Int(percentContributionsManagedObject.total_to_democrats),
//                    totalToRepublicans: Int(percentContributionsManagedObject.total_to_republicans),
//                    percentToDemocrats: percentContributionsManagedObject.percent_to_democrats,
//                    percentToRepublicans: percentContributionsManagedObject.percent_to_republicans,
//                    totalContributions: Int(percentContributionsManagedObject.total_contributions)
//                )
//            }
//            
//            // Contribution totals
//            var contributionTotalsList = [ContributionTotal]()
//            if let contributionTotalsListManagedObject = financialContributions.contributions_totals_list {
//                for case let item as FinancialContribution_ContributionTotals_ListItem in contributionTotalsListManagedObject {
//                    let contributionTotal = ContributionTotal(
//                        recipientID: item.recipient_id,
//                        recipientName: item.recipient_name,
//                        numberOfContributions: Int(item.number_of_contributions),
//                        totalContributionAmount: Int(item.total_contribution_amount)
//                    )
//                    contributionTotalsList.append(contributionTotal)
//                }
//            }
//            
//            // Leadership contributions
//            var leadershipContributionsList = [LeadershipContribution]()
//            if let leadershipContributionsListManagedObject = financialContributions.leadership_contributions_list {
//                for case let item as FinancialContribution_LeadershipContributorsToCommittee_ListItem in leadershipContributionsListManagedObject {
//                    let leadershipContribution = LeadershipContribution(
//                        occupation: item.occupation ?? "",
//                        name: item.name ?? "",
//                        employer: item.employer ?? "",
//                        transactionAmount: item.transaction_amount ?? ""
//                    )
//                    leadershipContributionsList.append(leadershipContribution)
//                }
//            }
//            
//            financialContributionsOverviewAnalysis = FinancialContributionsAnalysis(
//                financialContributionsText: financialContributions.fec_financial_contributions_summary_text,
//                committeeOrPACName: financialContributions.committee_name,
//                committeeOrPACID: financialContributions.committee_id,
//                percentContributions: percentContributions,
//                contributionTotals: contributionTotalsList,
//                leadershipContributionsToCommittee: leadershipContributionsList
//            )
//        }
//        
//        return OrganizationAnalysis(
//            topic: freshObject.topic ?? "",
//            lean: freshObject.lean ?? "Unknown",
//            rating: Int(freshObject.rating),
//            description: freshObject.context ?? "No description available",
//            hasFinancialContributions: freshObject.created_with_financial_contributions_info,
//            financialContributionsText: "No description available",
//            financialContributionsOverviewAnalysis: financialContributionsOverviewAnalysis
//        )
//    }
//}
//
//// MARK: - TableView DataSource & Delegate (for dropdown only)
//extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return filteredCompanies.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "CompanyCell", for: indexPath)
//        cell.textLabel?.text = filteredCompanies[indexPath.row]
//        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
//        cell.selectionStyle = .default
//        cell.isUserInteractionEnabled = true
//        cell.contentView.isUserInteractionEnabled = true
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 44
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        DispatchQueue.main.async { [self] in
//            tableView.deselectRow(at: indexPath, animated: true)
//            self.searchTextField.text = self.filteredCompanies[indexPath.row]
//            self.updateContinueButton()
//            self.hideDropdown()
//            self.searchTextField.resignFirstResponder()
//        }
//    }
//}
//
//// MARK: - UIGestureRecognizerDelegate
//extension SearchViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        // Don't intercept touches on table view cells or category selector
//        if touch.view?.superview is UITableViewCell {
//            return false
//        }
//        
//        // Check if touch is within category selector
//        let locationInCategorySelector = touch.location(in: categorySelector)
//        if categorySelector.bounds.contains(locationInCategorySelector) {
//            return false
//        }
//        
//        return true
//    }
//}
