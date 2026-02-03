//
//  CurrentConfiguration.swift
//  CompassAI
//
//  Created by Steve on 1/17/26.
//

import Foundation

// MARK: - Search Category Enum
enum CurrentSearchCategory: String, CaseIterable {
    case politicalLeaning = "Political Leaning"
    case deiFriendliness = "DEI Friendliness"
    case wokeness = "Wokeness"
    case environmentalImpact = "Environmental Impact"
    case immigrationSupport = "Immigration Support"
    case technologyInnovation = "Technology Innovation"
    case financialContributions = "Financial Contributions"
//    case epsteinFilesConections = "Epstein Connections"
    case undefined = "Undefined"
    
    /// Returns the question text for the search page based on category
    var searchPromptText: String {
        switch self {
        case .politicalLeaning:
            return "What organization do you want to find the political leaning of?"
        case .deiFriendliness:
            return "What organization do you want to evaluate for DEI friendliness?"
        case .wokeness:
            return "What organization do you want to assess for wokeness?"
        case .environmentalImpact:
            return "What organization do you want to analyze for environmental impact?"
        case .immigrationSupport:
            return "What organization do you want to evaluate for immigration support?"
        case .technologyInnovation:
            return "What organization do you want to assess for technology innovation?"
        case .financialContributions:
            return "What organization do you want to review financial contributions for?"
//        case .epsteinFilesConections:
//            return "What organization do you want to review for connections to Jeffery Epstein?"
        case .undefined:
            return "Undefined query"
        }
    }
    
    /// Returns a short display name for compact UI elements
    var shortName: String {
        return self.rawValue
    }
    
    /// Returns an SF Symbol icon name for the category
    var iconName: String {
        switch self {
        case .politicalLeaning:
            return "building.columns"
        case .deiFriendliness:
            return "person.3"
        case .wokeness:
            return "eye"
        case .environmentalImpact:
            return "leaf"
        case .immigrationSupport:
            return "globe.americas"
        case .technologyInnovation:
            return "lightbulb"
        case .financialContributions:
            return "dollarsign.circle"
//        case .epsteinFilesConections:
//            return "doc.text.magnifyingglass"
        case .undefined:
            return "building.columns"
        }
    }
    
    /// Returns the API endpoint path for this category
    var apiEndpoint: String {
        switch self {
        case .politicalLeaning:
            return "/getPoliticalLeaning"
        case .deiFriendliness:
            return "/getDEIFriendlinessScore"
        case .wokeness:
            return "/getWokenessScore"
        case .environmentalImpact:
            return "/getEnvironmentalImpactScore"
        case .immigrationSupport:
            return "/getImmigrationSupportScore"
        case .technologyInnovation:
            return "/getTechnologyInnovationScore"
        case .financialContributions:
            return "/getFinancialContributionsOverview"
//        case .epsteinFilesConections:
//            return "/getFinancialContributionsOverview" // Obviously change this.
        case .undefined:
            return ""
        }
    }
    
    /// Returns a descriptive label for a given rating value (1-5 scale)
    func ratingDescriptor(for rating: Int) -> String {
        switch self {
        case .politicalLeaning:
            switch rating {
            case 1: return "Very Liberal"
            case 2: return "Liberal"
            case 3: return "Moderate"
            case 4: return "Conservative"
            case 5: return "Very Conservative"
            default: return "Unknown"
            }
            
        case .deiFriendliness:
            switch rating {
            case 1: return "Not DEI Friendly"
            case 2: return "Slightly DEI Friendly"
            case 3: return "Moderately DEI Friendly"
            case 4: return "DEI Friendly"
            case 5: return "Very DEI Friendly"
            default: return "Unknown"
            }
            
        case .wokeness:
            switch rating {
            case 1: return "Not Woke"
            case 2: return "Slightly Woke"
            case 3: return "Moderately Woke"
            case 4: return "Woke"
            case 5: return "Very Woke"
            default: return "Unknown"
            }
            
        case .environmentalImpact:
            switch rating {
            case 1: return "Poor Environmental Record"
            case 2: return "Below Average"
            case 3: return "Average"
            case 4: return "Good Environmental Record"
            case 5: return "Excellent Environmental Record"
            default: return "Unknown"
            }
            
        case .immigrationSupport:
            switch rating {
            case 1: return "Anti-Immigration"
            case 2: return "Immigration Skeptic"
            case 3: return "Moderate on Immigration"
            case 4: return "Pro-Immigration"
            case 5: return "Strongly Pro-Immigration"
            default: return "Unknown"
            }
            
        case .technologyInnovation:
            switch rating {
            case 1: return "Not Innovative"
            case 2: return "Slightly Innovative"
            case 3: return "Moderately Innovative"
            case 4: return "Innovative"
            case 5: return "Highly Innovative"
            default: return "Unknown"
            }
            
//        case .epsteinFilesConections:
//            switch rating {
//            case 1: return "No Connection"
//            case 2: return "Maybe Have Talked With Once"
//            case 3: return "Passing Acquaintance"
//            case 4: return "Met Multiple Times"
//            case 5: return "Closely Connected"
//            default: return "Unknown"
//            }
            
        case .financialContributions:
            // Financial contributions typically don't use the same rating scale
            return "See Details"
            
        case .undefined: return ""
        }
    }
    
    /// Returns the low end label for the rating scale
    var lowRatingLabel: String {
        switch self {
        case .politicalLeaning: return "Liberal"
        case .deiFriendliness: return "Not DEI Friendly"
        case .wokeness: return "Not Woke"
        case .environmentalImpact: return "Poor"
        case .immigrationSupport: return "Anti-Immigration"
        case .technologyInnovation: return "Not Innovative"
        case .financialContributions: return "Democrat"
//        case .epsteinFilesConections: return "No Connection"
        case .undefined: return ""
        }
    }
    
    /// Returns the high end label for the rating scale
    var highRatingLabel: String {
        switch self {
        case .politicalLeaning: return "Conservative"
        case .deiFriendliness: return "Very DEI Friendly"
        case .wokeness: return "Very Woke"
        case .environmentalImpact: return "Excellent"
        case .immigrationSupport: return "Pro-Immigration"
        case .technologyInnovation: return "Highly Innovative"
        case .financialContributions: return "Republican"
//        case .epsteinFilesConections: return "Closely Connected"
        case .undefined: return ""
        }
    }
}

// MARK: - Search Configuration Singleton
final class CurrentConfiguration {
    
    // MARK: - Singleton Instance
    static let shared = CurrentConfiguration()
    
    // MARK: - Properties
    private(set) var currentCategory: CurrentSearchCategory = .politicalLeaning
    
    // MARK: - Notification Name
    static let categoryDidChangeNotification = Notification.Name("SearchConfigurationCategoryDidChange")
    
    // MARK: - Private Init
    private init() {
        // Load saved category from UserDefaults if available
        if let savedCategoryRawValue = UserDefaults.standard.string(forKey: "selectedSearchCategory"),
           let savedCategory = CurrentSearchCategory(rawValue: savedCategoryRawValue) {
            currentCategory = savedCategory
        }
    }
    
    // MARK: - Methods
    func setCategory(_ category: CurrentSearchCategory) {
        currentCategory = category
        
        // Persist to UserDefaults
        UserDefaults.standard.set(category.rawValue, forKey: "selectedSearchCategory")
        
        // Post notification for observers
        NotificationCenter.default.post(
            name: CurrentConfiguration.categoryDidChangeNotification,
            object: self,
            userInfo: ["category": category]
        )
    }
    
    func getAllCategories() -> [CurrentSearchCategory] {
        return CurrentSearchCategory.allCases
    }
}
