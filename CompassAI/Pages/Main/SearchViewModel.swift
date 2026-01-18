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
//import UIKit
//import Foundation
//
//// MARK: - Search ViewModel Delegate
//protocol SearchViewModelDelegate: AnyObject {
//    func searchDidStart()
//    func searchDidComplete(with analysis: OrganizationAnalysis)
//    func searchDidFail(with error: String)
//}
//
//// MARK: - Search ViewModel
//class SearchViewModel {
//    weak var coordinator: AppCoordinator?
//    weak var delegate: SearchViewModelDelegate?
//    private let networkManager = NetworkManager.shared
//    
//    let suggestedCompanies = organizationSuggestions
//    
//    // MARK: - Filtering
//    func getFilteredCompanies(for searchText: String) -> [String] {
//        if searchText.isEmpty {
//            return suggestedCompanies
//        }
//        return suggestedCompanies.filter {
//            $0.localizedCaseInsensitiveContains(searchText)
//        }
//    }
//    
//    // MARK: - Search Methods
//    
//    /// Search for an organization using the currently selected category
//    /// - Parameters:
//    ///   - topic: The organization name to search
//    ///   - category: The SearchCategory to use for the analysis
//    ///   - viewController: The presenting view controller (for error display)
//    func searchOrganization(topic: String, category: SearchCategory, from viewController: UIViewController) {
//        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            return
//        }
//        
//        coordinator?.showLoadingScreen()
//        delegate?.searchDidStart()
//        
//        // Use the generic getAnalysis method that handles all categories
//        networkManager.getAnalysis(for: category, topic: topic) { [weak self] result in
//            switch result {
//            case .success(let analysis):
//                DispatchQueue.main.async {
//                    self?.delegate?.searchDidComplete(with: analysis)
//                    self?.coordinator?.showResultsScreen(with: analysis, organizationName: topic)
//                }
//                
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self?.delegate?.searchDidFail(with: error.localizedDescription)
//                    self?.coordinator?.showError(message: error.localizedDescription, from: viewController)
//                }
//            }
//        }
//    }
//    
//    /// Legacy method for backward compatibility - uses Political Leaning by default
//    /// - Parameters:
//    ///   - topic: The organization name to search
//    ///   - viewController: The presenting view controller
//    func searchOrganization(topic: String, from viewController: UIViewController) {
//        // Default to political leaning for backward compatibility
//        searchOrganization(topic: topic, category: .politicalLeaning, from: viewController)
//    }
//    
//    // MARK: - Navigation with Persisted Data
//    
//    /// Navigate to overview screen with previously persisted data
//    /// - Parameters:
//    ///   - analysis: The OrganizationAnalysis object
//    ///   - organizationName: The name of the organization
//    ///   - viewController: The presenting view controller
//    func navigateToOverviewWithPersistedData(
//        analysis: OrganizationAnalysis,
//        organizationName: String,
//        from viewController: UIViewController
//    ) {
//        let overviewVC = OverviewViewController()
//        
//        if let coordinator = self.coordinator {
//            // Configure with persisted data instead of making network request
//            overviewVC.configureWithPersistedData(
//                analysis: analysis,
//                organizationName: organizationName,
//                coordinator: coordinator
//            )
//            
//            viewController.navigationController?.pushViewController(overviewVC, animated: true)
//        }
//    }
//}


////
////  SearchViewModelDelegate.swift
////  Compass AI V2
////
////  Created by Steve on 8/21/25.
////
//import UIKit
//import Foundation
//
//// MARK: - Search ViewModel
//protocol SearchViewModelDelegate: AnyObject {
//    func searchDidStart()
//    func searchDidComplete(with analysis: OrganizationAnalysis)
//    func searchDidFail(with error: String)
//}
//
//// MARK: - Search ViewModel
//class SearchViewModel {
//    weak var coordinator: AppCoordinator?
//    private let networkManager = NetworkManager.shared
//    
////    let suggestedCompanies = [
////        "Microsoft",
////        "Alpha and Omega Semiconductor Limited",
////        "Lattice Semiconductor Corporation",
////        "indie Semiconductor, Inc.",
////        "NXP Semiconductors N.V.",
////        "Microchip Technology Incorporated",
////        "Microsoft Corporation"
////    ]
//    
//    let suggestedCompanies = organizationSuggestions
//    
//    func getFilteredCompanies(for searchText: String) -> [String] {
//        if searchText.isEmpty {
//            return suggestedCompanies
//        }
//        return suggestedCompanies.filter {
//            $0.localizedCaseInsensitiveContains(searchText)
//        }
//    }
//    
//    func searchOrganization(topic: String, from viewController: UIViewController) {
//        guard !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            return
//        }
//        
//        coordinator?.showLoadingScreen()
//        
//        networkManager.getPoliticalLeaning(for: topic) { [weak self] result in
////            print("Political Leaning Result: \(result)\n")
//            switch result {
//            case .success(let politicalResponse):
////                print("Political Leaning Response: \(politicalResponse)\n")
//                // Check if we need financial contributions
//                // TODO: Maybe bring this back. This could be helpful potentially.
////                if politicalResponse.createdWithFinancialContributionsInfo == true {
////                    self?.fetchFinancialContributions(
////                        for: topic,
////                        politicalResponse: politicalResponse
////                    )
////                } else {
//                
//                    let analysis = OrganizationAnalysis(
//                        topic: politicalResponse.topic ?? "", // The json calls it topic, but this is the name.
//                        lean: politicalResponse.lean,
//                        rating: politicalResponse.rating.value, // TODO: Remove value (and flexible in as a while) and replace with int once the backend code is correctly updated.
//                        description: politicalResponse.context,
//                        hasFinancialContributions: politicalResponse.createdWithFinancialContributionsInfo,
//                        financialContributionsText: nil,
//                        financialContributionsOverviewAnalysis: nil
//                    )
//                    DispatchQueue.main.async {
//                        self?.coordinator?.showResultsScreen(with: analysis, organizationName: topic)
//                    }
//                
////                }
//                
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self?.coordinator?.showError(message: error.localizedDescription, from: viewController)
//                }
//            }
//        }
//    }
//    
//    private func fetchFinancialContributions(for topic: String, politicalResponse: PoliticalLeaningResponse) {
//        networkManager.getFinancialContributionsOverview(for: topic) { [weak self] result in
////            print("Financial Result: \(result)\n")
//            let analysis: OrganizationAnalysis
//            switch result {
//            case .success(let financialResponse):
////                print("Financial Response: \(financialResponse)\n")
//                analysis = OrganizationAnalysis(
//                    topic: politicalResponse.topic ?? "", // The json calls it topic, but this is the name.
//                    lean: politicalResponse.lean,
//                    rating: politicalResponse.rating.value, // TODO: Remove value (and flexible in as a while) and replace with int once the backend code is correctly updated.
//                    description: politicalResponse.context,
//                    hasFinancialContributions: true,
//                    financialContributionsText: financialResponse.fecFinancialContributionsSummaryText,
//                    financialContributionsOverviewAnalysis: nil
//                )
//                
//            case .failure:
//                // If financial contributions fail, still show the political data
//                analysis = OrganizationAnalysis(
//                    topic: politicalResponse.topic ?? "", // The json calls it topic, but this is the name.
//                    lean: politicalResponse.lean,
//                    rating: politicalResponse.rating.value, // TODO: Remove value (and flexible in as a while) and replace with int once the backend code is correctly updated.
//                    description: politicalResponse.context,
//                    hasFinancialContributions: false,
//                    financialContributionsText: nil,
//                    financialContributionsOverviewAnalysis: nil
//                )
//            }
//            
//            DispatchQueue.main.async {
//                self?.coordinator?.showResultsScreen(with: analysis, organizationName: topic)
//            }
//        }
//    }
//    
//    // Add this method to your SearchViewModel class
//    func navigateToOverviewWithPersistedData(analysis: OrganizationAnalysis, organizationName: String, from viewController: UIViewController) {
//        // Assuming you have a coordinator pattern similar to OverviewViewController
//        // You'll need to adapt this to your actual navigation setup
//        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Adjust storyboard name as needed
//        let overviewVC = OverviewViewController()
//        
//        if let coordinator = self.coordinator {
//            // Configure with persisted data instead of making network request
//            overviewVC.configureWithPersistedData(analysis: analysis,
//                                                  organizationName: organizationName,
//                                                  coordinator: coordinator)
//            
//            viewController.navigationController?.pushViewController(overviewVC, animated: true)
//        }
//    }
//}
