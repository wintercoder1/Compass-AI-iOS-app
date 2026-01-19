//
//  SearchViewModel.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//

import UIKit
import Foundation

// MARK: - Search ViewModel Delegate
protocol SearchViewModelDelegate: AnyObject {
    func searchDidStart()
    func searchDidComplete(with analysis: OrganizationAnalysis)
    func searchDidFail(with error: String)
}

// MARK: - Search ViewModel
class SearchViewModel {
    weak var coordinator: AppCoordinator?
    weak var delegate: SearchViewModelDelegate?
    private let networkManager = NetworkManager.shared
    
    let suggestedCompanies = organizationSuggestions
    
    // MARK: - Filtering
    func getFilteredCompanies(for searchText: String) -> [String] {
        if searchText.isEmpty {
            return suggestedCompanies
        }
        return suggestedCompanies.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Search Methods
    
    /// Search for an organization using the specified category
    /// - Parameters:
    ///   - topic: The organization name to search
    ///   - category: The CurrentSearchCategory to use for the analysis
    ///   - viewController: The presenting view controller (for error display)
    func searchOrganization(topic: String, category: CurrentSearchCategory, from viewController: UIViewController) {
        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        coordinator?.showLoadingScreen()
        delegate?.searchDidStart()
        
        // Use the generic getAnalysis method that handles all categories
        networkManager.getAnalysis(for: category, topic: topic) { [weak self] result in
            switch result {
            case .success(let analysis):
                DispatchQueue.main.async {
                    self?.delegate?.searchDidComplete(with: analysis)
                    self?.coordinator?.showResultsScreen(with: analysis, organizationName: topic)
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.delegate?.searchDidFail(with: error.localizedDescription)
                    self?.coordinator?.showError(message: error.localizedDescription, from: viewController)
                }
            }
        }
    }
    
    /// Search using the currently selected category from CurrentConfiguration
    /// - Parameters:
    ///   - topic: The organization name to search
    ///   - viewController: The presenting view controller
    func searchOrganization(topic: String, from viewController: UIViewController) {
        let currentCategory = CurrentConfiguration.shared.currentCategory
        searchOrganization(topic: topic, category: currentCategory, from: viewController)
    }
    
    // MARK: - Navigation with Persisted Data
    
    /// Navigate to overview screen with previously persisted data
    /// - Parameters:
    ///   - analysis: The OrganizationAnalysis object
    ///   - organizationName: The name of the organization
    ///   - viewController: The presenting view controller
    func navigateToOverviewWithPersistedData(
        analysis: OrganizationAnalysis,
        organizationName: String,
        from viewController: UIViewController
    ) {
        let overviewVC = OverviewViewController()
        
        if let coordinator = self.coordinator {
            // Configure with persisted data instead of making network request
            overviewVC.configureWithPersistedData(
                analysis: analysis,
                organizationName: organizationName,
                coordinator: coordinator
            )
            
            viewController.navigationController?.pushViewController(overviewVC, animated: true)
        }
    }
}
