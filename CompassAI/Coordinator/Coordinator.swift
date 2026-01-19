//
//  Coordinator.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//
import UIKit

// MARK: - Coordinator Protocol
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

// MARK: - App Coordinator
class AppCoordinator: Coordinator {
    let navigationController: UINavigationController
    private var searchViewModel: SearchViewModel?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.navigationController.setNavigationBarHidden(true, animated: false)
    }
    
    func start() {
        showSearchScreen()
    }
    
    private func showSearchScreen() {
        let viewModel = SearchViewModel()
        viewModel.coordinator = self
        self.searchViewModel = viewModel
        
        let searchVC = SearchViewController()
        searchVC.viewModel = viewModel
        
        navigationController.setViewControllers([searchVC], animated: false)
    }
    
    func showLoadingScreen() {
        let loadingVC = LoadingViewController()
        navigationController.pushViewController(loadingVC, animated: true)
    }
    
    func showResultsScreen(with analysis: OrganizationAnalysis, organizationName: String) {
        let resultsVC = OverviewViewController()
        resultsVC.configure(with: analysis, organizationName: organizationName,coordinator: self)
        // Replace loading screen with results view controller.
        // If we pop the loadinf screen and then add the results vc it creates weird UI jank.
        navigationController.replaceTopViewController(with: resultsVC, animated: true)
    }
    
    func showFinancialContributionsScreen(organizationName: String, viewModel: FinancialContributionsViewModel) {
        let financialVC = FinancialContributionsViewController()
        financialVC.configure(organizationName: organizationName, viewModel: viewModel, coordinator: self)
        
        // NEW: Bind the full data callback to update the view controller
        viewModel.onFullDataLoaded = { [weak financialVC] financialResponse in
            financialVC?.setFinancialContributions(financialResponse)
        }
        
        navigationController.pushViewController(financialVC, animated: true)
    }
    
    func showError(message: String, from viewController: UIViewController) {
        // Remove loading screen if present
        if navigationController.topViewController is LoadingViewController {
            navigationController.popViewController(animated: false)
        }
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    func navigateBack() {
        navigationController.popViewController(animated: true)
    }
    
    func navigateToRoot() {
        navigationController.popToRootViewController(animated: true)
    }
    
    func showFinancialContributionsScreenWithPersistedData(organizationName: String, viewModel: FinancialContributionsViewModel, financialData: FinancialContributionsResponse) {
        let financialVC = FinancialContributionsViewController()
        financialVC.configure(organizationName: organizationName, viewModel: viewModel, coordinator: self)
        
        // Bind the callbacks
        viewModel.onFullDataLoaded = { [weak financialVC] financialResponse in
            financialVC?.setFinancialContributions(financialResponse)
        }
        
        // Immediately load the persisted data
        viewModel.loadPersistedData(financialData)
        
        navigationController.pushViewController(financialVC, animated: true)
    }
}

// MARK: - App Coordinator
//class AppCoordinator: Coordinator {
//    let navigationController: UINavigationController
//    private var searchViewModel: SearchViewModel?
//    
//    init(navigationController: UINavigationController) {
//        self.navigationController = navigationController
//        self.navigationController.setNavigationBarHidden(true, animated: false)
//    }
//    
//    func start() {
//        showSearchScreen()
//    }
//    
//    private func showSearchScreen() {
//        let viewModel = SearchViewModel()
//        viewModel.coordinator = self
//        self.searchViewModel = viewModel
//        
//        let searchVC = SearchViewController()
//        searchVC.viewModel = viewModel
//        
//        navigationController.setViewControllers([searchVC], animated: false)
//    }
//    
//    func showLoadingScreen() {
//        let loadingVC = LoadingViewController()
//        navigationController.pushViewController(loadingVC, animated: true)
//    }
//    
//    func showResultsScreen(with analysis: OrganizationAnalysis, organizationName: String) {
//        // Remove loading screen if present
//        if navigationController.topViewController is LoadingViewController {
//            navigationController.popViewController(animated: false)
//        }
//        
//        let resultsVC = ResultsViewController()
//        resultsVC.configure(with: analysis, organizationName: organizationName, coordinator: self)
//        navigationController.pushViewController(resultsVC, animated: true)
//    }
//    
//    func showFinancialContributionsScreen(organizationName: String, financialText: String) {
//        let financialVC = FinancialContributionsViewController()
//        financialVC.configure(organizationName: organizationName, financialText: financialText, coordinator: self)
//        navigationController.pushViewController(financialVC, animated: true)
//    }
//    
//    func showError(message: String, from viewController: UIViewController) {
//        // Remove loading screen if present
//        if navigationController.topViewController is LoadingViewController {
//            navigationController.popViewController(animated: false)
//        }
//        
//        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        viewController.present(alert, animated: true)
//    }
//    
//    func navigateBack() {
//        navigationController.popViewController(animated: true)
//    }
//    
//    func navigateToRoot() {
//        navigationController.popToRootViewController(animated: true)
//    }
//}
