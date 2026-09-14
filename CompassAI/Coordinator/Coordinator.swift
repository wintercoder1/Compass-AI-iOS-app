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
    private weak var tabBarController: UITabBarController?
    private weak var searchViewController: SearchViewController?
    private weak var quizViewController: QuizViewController?
    private var pendingDeepLink: CompassDeepLink?
    
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
        searchViewController = searchVC
        searchVC.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        let quizVC = QuizViewController()
        quizViewController = quizVC
        quizVC.tabBarItem = UITabBarItem(
            title: "Quiz",
            image: UIImage(systemName: "questionmark.circle"),
            selectedImage: UIImage(systemName: "questionmark.circle.fill")
        )
        
        let tabBarController = UITabBarController()
        self.tabBarController = tabBarController
        tabBarController.viewControllers = [quizVC, searchVC]
        tabBarController.selectedIndex = 0
        tabBarController.tabBar.backgroundColor = .systemBackground
        tabBarController.tabBar.tintColor = .systemBlue
        tabBarController.tabBar.unselectedItemTintColor = .secondaryLabel
        
        quizVC.onCompanySelected = { [weak tabBarController, weak searchVC] company in
            tabBarController?.selectedIndex = 1
            searchVC?.prefillCompanyForSearch(company)
        }
        
        navigationController.setViewControllers([tabBarController], animated: false)
        
        if let pendingDeepLink {
            self.pendingDeepLink = nil
            handleDeepLink(pendingDeepLink)
        }
    }
    
    func handleIncomingURL(_ url: URL) {
        guard let deepLink = CompassDeepLink.parse(url) else {
            return
        }
        handleDeepLink(deepLink)
    }
    
    private func handleDeepLink(_ deepLink: CompassDeepLink) {
        guard let tabBarController else {
            pendingDeepLink = deepLink
            return
        }
        
        navigationController.popToRootViewController(animated: false)
        
        switch deepLink {
        case .quizResult(let token):
            tabBarController.selectedIndex = 0
            quizViewController?.loadSharedQuizResult(token: token)
        case .answer(let topic, let category):
            tabBarController.selectedIndex = 1
            searchViewController?.openSharedAnswer(topic: topic, category: category)
        }
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
    
    func showFinancialContributionsScreenReplacingLoading(organizationName: String, viewModel: FinancialContributionsViewModel, financialData: FinancialContributionsResponse) {
        let financialVC = FinancialContributionsViewController()
        financialVC.configure(organizationName: organizationName, viewModel: viewModel, coordinator: self)
        financialVC.loadViewIfNeeded()
        viewModel.loadPersistedData(financialData)
        navigationController.replaceTopViewController(with: financialVC, animated: true)
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
        
        financialVC.loadViewIfNeeded()
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
