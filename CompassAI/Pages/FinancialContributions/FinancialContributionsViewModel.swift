//
//  FinancialContributionsViewModel.swift
//  Compass AI V2
//
//  Created by Steve on 8/23/25.
//
import Foundation

// MARK: - Financial Contributions ViewModel
class FinancialContributionsViewModel {
    weak var coordinator: AppCoordinator?
    private let networkManager = NetworkManager.shared
    
    // Published properties for the view to observe
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onDataLoaded: ((String) -> Void)?
    var onFullDataLoaded: ((FinancialContributionsResponse) -> Void)? // NEW: Full data callback
    var onError: ((String) -> Void)?
    
//    func fetchFinancialContributions(for organizationName: String) {
//        onLoadingStateChanged?(true)
//        
//        networkManager.getFinancialContributionsOverview(for: organizationName) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.onLoadingStateChanged?(false)
//                
//                switch result {
//                case .success(let financialResponse):
//                    // Send both the text and full response
//                    // TODO: consolidate these. No need to call both. (i think..)
//                    self?.onDataLoaded?(financialResponse.fecFinancialContributionsSummaryText)
//                    self?.onFullDataLoaded?(financialResponse) // NEW: Pass full response
//                case .failure(let error):
//                    self?.onError?(error.localizedDescription)
//                }
//            }
//        }
//    }
    func fetchFinancialContributions(for organizationName: String) {
        onLoadingStateChanged?(true)
        
        networkManager.getFinancialContributionsOverview(for: organizationName) { [weak self] result in
            DispatchQueue.main.async {
                self?.onLoadingStateChanged?(false)
                
                switch result {
                case .success(let financialResponse):
                    self?.onFullDataLoaded?(financialResponse)
                    self?.onDataLoaded?(financialResponse.fecFinancialContributionsSummaryText)
                case .failure(let error):
                    self?.onError?(error.localizedDescription)
                }
            }
        }
    }
    
//    func navigateToOverviewWithPersistedData(analysis: OrganizationAnalysis, organizationName: String, from viewController: UIViewController) {
//        // Assuming you have a coordinator pattern similar to OverviewViewController
//        // You'll need to adapt this to your actual navigation setup
//        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil) // Adjust storyboard name as needed
//        let overviewVC = FinancialContributionsOverview()
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
    
    func loadPersistedData(_ financialData: FinancialContributionsResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingStateChanged?(false)
            self?.onFullDataLoaded?(financialData)
            self?.onDataLoaded?(financialData.fecFinancialContributionsSummaryText)
        }
    }

    
}
