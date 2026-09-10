//
//  AdMobConfiguration.swift
//  CompassAI
//
//  Created by Steve on 2/4/26.
//
 

import Foundation

/// Centralized configuration for Google AdMob ad units
struct AdMobConfiguration {
    
    // MARK: - Singleton
    static let shared = AdMobConfiguration()
    
    private init() {}
    
    // MARK: - Ad Unit IDs
    
    /// Test ad unit ID for development (Google's official test ID)
    private let testAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    /// Production ad unit ID for the Compass AI iOS app
    private let compassAIBannerAdUnitID = "ca-app-pub-2088930087138715/3826211315"
    
//    /// Production ad unit ID for Overview screen banner
//    private let overviewBannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
//    
//    /// Production ad unit ID for Financial Contributions screen - first banner
//    private let financialBanner1AdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
//    
//    /// Production ad unit ID for Financial Contributions screen - second banner
//    private let financialBanner2AdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
//    
//    /// Production ad unit ID for Search screen banner
//    private let searchBannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    
    // MARK: - Environment
    
    /// Set to false when ready for production
    private let isTestMode = false //true
    
    // MARK: - Public Methods
    
    /// Returns the appropriate ad unit ID for the Compass AI iOS app
    func getOverviewBannerAdUnitID() -> String {
        return isTestMode ? testAdUnitID : compassAIBannerAdUnitID
    }
    
    /*
    /// Returns the appropriate ad unit ID for the Overview screen
    func getOverviewBannerAdUnitID() -> String {
        return isTestMode ? testAdUnitID : overviewBannerAdUnitID
    }
    
    /// Returns the appropriate ad unit ID for the Financial Contributions screen (first banner)
    func getFinancialBanner1AdUnitID() -> String {
        return isTestMode ? testAdUnitID : financialBanner1AdUnitID
    }
    
    /// Returns the appropriate ad unit ID for the Financial Contributions screen (second banner)
    func getFinancialBanner2AdUnitID() -> String {
        return isTestMode ? testAdUnitID : financialBanner2AdUnitID
    }
    
    /// Returns the appropriate ad unit ID for the Search screen
    func getSearchBannerAdUnitID() -> String {
        return isTestMode ? testAdUnitID : searchBannerAdUnitID
    }
    */
}
