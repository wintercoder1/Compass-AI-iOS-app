//
//  NetworkManager.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//

import UIKit
import Foundation

//// MARK: - Network Error
//enum NetworkError: Error {
//    case invalidURL
//    case httpError(Int)
//    case noData
//    case decodingError
//    
//    var localizedDescription: String {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .httpError(let code):
//            return "HTTP Error: \(code)"
//        case .noData:
//            return "No data received"
//        case .decodingError:
//            return "Failed to decode response"
//        }
//    }
//}

// MARK: - Network Manager
class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "https://compass-ai-internal-api.com"
//    private let baseURL = "http://127.0.0.1:8000"
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func makeRequest<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Making request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.httpError(0)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.httpError(0)))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    // MARK: - Political Leaning
    func getPoliticalLeaning(
        for topic: String,
        completion: @escaping (Result<PoliticalLeaningResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getPoliticalLeaning/\(encodedTopic)",
            responseType: PoliticalLeaningResponse.self,
            completion: completion
        )
    }
    
    // MARK: - DEI Friendliness
    func getDEIFriendlinessScore(
        for topic: String,
        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getDEIFriendlinessScore/\(encodedTopic)",
            responseType: CategoryAnalysisResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Wokeness
    func getWokenessScore(
        for topic: String,
        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getWokenessScore/\(encodedTopic)",
            responseType: CategoryAnalysisResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Environmental Impact
    func getEnvironmentalImpactScore(
        for topic: String,
        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getEnvironmentalImpactScore/\(encodedTopic)",
            responseType: CategoryAnalysisResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Immigration Support
    func getImmigrationSupportScore(
        for topic: String,
        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getImmigrationSupportScore/\(encodedTopic)",
            responseType: CategoryAnalysisResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Technology Innovation
    func getTechnologyInnovationScore(
        for topic: String,
        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getTechnologyInnovationScore/\(encodedTopic)",
            responseType: CategoryAnalysisResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Financial Contributions
    func getFinancialContributionsOverview(
        for topic: String,
        completion: @escaping (Result<FinancialContributionsResponse, NetworkError>) -> Void
    ) {
        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        makeRequest(
            endpoint: "/getFinancialContributionsOverview/\(encodedTopic)",
            responseType: FinancialContributionsResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Generic Category Analysis
    /// Fetches analysis for any category type
    /// - Parameters:
    ///   - category: The CurrentSearchCategory to fetch
    ///   - topic: The organization/topic to analyze
    ///   - completion: Completion handler with the result
    func getAnalysis(
        for category: CurrentSearchCategory,
        topic: String,
        completion: @escaping (Result<OrganizationAnalysis, NetworkError>) -> Void
    ) {
        switch category {
        case .politicalLeaning:
            getPoliticalLeaning(for: topic) { result in
                switch result {
                case .success(let response):
                    let analysis = OrganizationAnalysis(
                        topic: response.topic ?? topic,
                        lean: response.lean,
                        rating: response.rating.value,
                        description: response.context,
                        hasFinancialContributions: response.createdWithFinancialContributionsInfo,
                        financialContributionsText: nil,
                        financialContributionsOverviewAnalysis: nil,
                        category: category
                    )
                    completion(.success(analysis))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
        case .deiFriendliness:
            getDEIFriendlinessScore(for: topic) { result in
                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
            }
            
        case .wokeness:
            getWokenessScore(for: topic) { result in
                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
            }
            
        case .environmentalImpact:
            getEnvironmentalImpactScore(for: topic) { result in
                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
            }
            
        case .immigrationSupport:
            getImmigrationSupportScore(for: topic) { result in
                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
            }
            
        case .technologyInnovation:
            getTechnologyInnovationScore(for: topic) { result in
                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
            }
            
        case .financialContributions:
            getFinancialContributionsOverview(for: topic) { result in
                switch result {
                case .success(let response):
                    // Build the financial contributions analysis object
                    let financialAnalysis = FinancialContributionsAnalysis(
                        financialContributionsText: response.fecFinancialContributionsSummaryText,
                        committeeOrPACName: response.committeeName,
                        committeeOrPACID: response.committeeId,
                        percentContributions: response.percentContributions,
                        contributionTotals: response.contributionTotals,
                        leadershipContributionsToCommittee: response.leadershipContributionsToCommittee
                    )
                    
                    let analysis = OrganizationAnalysis(
                        topic: topic,
                        lean: "Financial Data",
                        rating: 0, // Financial contributions don't have a simple rating
                        description: response.fecFinancialContributionsSummaryText,
                        hasFinancialContributions: true,
                        financialContributionsText: response.fecFinancialContributionsSummaryText,
                        financialContributionsOverviewAnalysis: financialAnalysis,
                        category: category
                    )
                    completion(.success(analysis))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleCategoryResponse(
        _ result: Result<CategoryAnalysisResponse, NetworkError>,
        topic: String,
        category: CurrentSearchCategory,
        completion: @escaping (Result<OrganizationAnalysis, NetworkError>) -> Void
    ) {
        switch result {
        case .success(let response):
            let ratingDescriptor = category.ratingDescriptor(for: response.rating.value)
            let analysis = OrganizationAnalysis(
                topic: response.topic ?? topic,
                lean: ratingDescriptor,
                rating: response.rating.value,
                description: response.context,
                hasFinancialContributions: response.createdWithFinancialContributionsInfo,
                financialContributionsText: nil,
                financialContributionsOverviewAnalysis: nil,
                category: category
            )
            completion(.success(analysis))
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

//import UIKit
//import Foundation
////
////// MARK: - Network Error
////enum NetworkError: Error {
////    case invalidURL
////    case httpError(Int)
////    case noData
////    case decodingError
////    
////    var localizedDescription: String {
////        switch self {
////        case .invalidURL:
////            return "Invalid URL"
////        case .httpError(let code):
////            return "HTTP Error: \(code)"
////        case .noData:
////            return "No data received"
////        case .decodingError:
////            return "Failed to decode response"
////        }
////    }
////}
//
//// MARK: - Network Manager
//class NetworkManager {
//    static let shared = NetworkManager()
//    private let baseURL = "https://compass-ai-internal-api.com"
////    private let baseURL = "http://127.0.0.1:8000"
//    
//    private init() {}
//    
//    // MARK: - Generic Request Method
//    private func makeRequest<T: Codable>(
//        endpoint: String,
//        responseType: T.Type,
//        completion: @escaping (Result<T, NetworkError>) -> Void
//    ) {
//        guard let url = URL(string: baseURL + endpoint) else {
//            completion(.failure(.invalidURL))
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        print("Making request to: \(url.absoluteString)")
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Network error: \(error.localizedDescription)")
//                completion(.failure(.httpError(0)))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(.httpError(0)))
//                return
//            }
//            
//            guard 200...299 ~= httpResponse.statusCode else {
//                print("HTTP error: \(httpResponse.statusCode)")
//                completion(.failure(.httpError(httpResponse.statusCode)))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(.noData))
//                return
//            }
//            
//            do {
//                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
//                completion(.success(decodedResponse))
//            } catch {
//                print("Decoding error: \(error)")
//                completion(.failure(.decodingError))
//            }
//        }.resume()
//    }
//    
//    // MARK: - Political Leaning
//    func getPoliticalLeaning(
//        for topic: String,
//        completion: @escaping (Result<PoliticalLeaningResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getPoliticalLeaning/\(encodedTopic)",
//            responseType: PoliticalLeaningResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - DEI Friendliness
//    func getDEIFriendlinessScore(
//        for topic: String,
//        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getDEIFriendlinessScore/\(encodedTopic)",
//            responseType: CategoryAnalysisResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Wokeness
//    func getWokenessScore(
//        for topic: String,
//        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getWokenessScore/\(encodedTopic)",
//            responseType: CategoryAnalysisResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Environmental Impact
//    func getEnvironmentalImpactScore(
//        for topic: String,
//        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getEnvironmentalImpactScore/\(encodedTopic)",
//            responseType: CategoryAnalysisResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Immigration Support
//    func getImmigrationSupportScore(
//        for topic: String,
//        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getImmigrationSupportScore/\(encodedTopic)",
//            responseType: CategoryAnalysisResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Technology Innovation
//    func getTechnologyInnovationScore(
//        for topic: String,
//        completion: @escaping (Result<CategoryAnalysisResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getTechnologyInnovationScore/\(encodedTopic)",
//            responseType: CategoryAnalysisResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Financial Contributions
//    func getFinancialContributionsOverview(
//        for topic: String,
//        completion: @escaping (Result<FinancialContributionsResponse, NetworkError>) -> Void
//    ) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getFinancialContributionsOverview/\(encodedTopic)",
//            responseType: FinancialContributionsResponse.self,
//            completion: completion
//        )
//    }
//    
//    // MARK: - Generic Category Analysis
//    /// Fetches analysis for any category type
//    /// - Parameters:
//    ///   - category: The SearchCategory to fetch
//    ///   - topic: The organization/topic to analyze
//    ///   - completion: Completion handler with the result
//    func getAnalysis(
//        for category: CurrentSearchCategory,
//        topic: String,
//        completion: @escaping (Result<OrganizationAnalysis, NetworkError>) -> Void
//    ) {
//        switch category {
//        case .politicalLeaning:
//            getPoliticalLeaning(for: topic) { result in
//                switch result {
//                case .success(let response):
//                    let analysis = OrganizationAnalysis(
//                        topic: response.topic ?? topic,
//                        lean: response.lean,
//                        rating: response.rating.value,
//                        description: response.context,
//                        hasFinancialContributions: response.createdWithFinancialContributionsInfo,
//                        financialContributionsText: nil,
//                        financialContributionsOverviewAnalysis: nil,
//                        category: category
//                    )
//                    completion(.success(analysis))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//            
//        case .deiFriendliness:
//            getDEIFriendlinessScore(for: topic) { result in
//                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
//            }
//            
//        case .wokeness:
//            getWokenessScore(for: topic) { result in
//                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
//            }
//            
//        case .environmentalImpact:
//            getEnvironmentalImpactScore(for: topic) { result in
//                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
//            }
//            
//        case .immigrationSupport:
//            getImmigrationSupportScore(for: topic) { result in
//                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
//            }
//            
//        case .technologyInnovation:
//            getTechnologyInnovationScore(for: topic) { result in
//                self.handleCategoryResponse(result, topic: topic, category: category, completion: completion)
//            }
//            
//        case .financialContributions:
//            getFinancialContributionsOverview(for: topic) { result in
//                switch result {
//                case .success(let response):
//                    // Build the financial contributions analysis object
//                    let financialAnalysis = FinancialContributionsAnalysis(
//                        financialContributionsText: response.fecFinancialContributionsSummaryText,
//                        committeeOrPACName: response.committeeName,
//                        committeeOrPACID: response.committeeId,
//                        percentContributions: response.percentContributions,
//                        contributionTotals: response.contributionTotals,
//                        leadershipContributionsToCommittee: response.leadershipContributions
//                    )
//                    
//                    let analysis = OrganizationAnalysis(
//                        topic: topic,
//                        lean: "Financial Data",
//                        rating: 0, // Financial contributions don't have a simple rating
//                        description: response.fecFinancialContributionsSummaryText ?? "Financial contributions data available.",
//                        hasFinancialContributions: true,
//                        financialContributionsText: response.fecFinancialContributionsSummaryText,
//                        financialContributionsOverviewAnalysis: financialAnalysis,
//                        category: category
//                    )
//                    completion(.success(analysis))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private func handleCategoryResponse(
//        _ result: Result<CategoryAnalysisResponse, NetworkError>,
//        topic: String,
//        category: CurrentSearchCategory,
//        completion: @escaping (Result<OrganizationAnalysis, NetworkError>) -> Void
//    ) {
//        switch result {
//        case .success(let response):
//            let ratingDescriptor = category.ratingDescriptor(for: response.rating)
//            let analysis = OrganizationAnalysis(
//                topic: response.topic ?? topic,
//                lean: ratingDescriptor,
//                rating: response.rating,
//                description: response.context,
//                hasFinancialContributions: response.createdWithFinancialContributionsInfo,
//                financialContributionsText: nil,
//                financialContributionsOverviewAnalysis: nil,
//                category: category
//            )
//            completion(.success(analysis))
//        case .failure(let error):
//            completion(.failure(error))
//        }
//    }
//}
////
////  NetworkManager.swift
////  Compass AI V2
////
////  Created by Steve on 8/21/25.
////
//import UIKit
//import Foundation
//
//// MARK: - Network Manager
//class NetworkManager {
//    static let shared = NetworkManager()
//    private let baseURL = "https://compass-ai-internal-api.com"
////    private let baseURL = "YOUR_VITE_BASE_URL_HERE" // Replace with your actual base URL
////    private let baseURL = "http://127.0.0.1:8000"
//    
//    private init() {}
//    
//    private func makeRequest<T: Codable>(
//        endpoint: String,
//        responseType: T.Type,
//        completion: @escaping (Result<T, NetworkError>) -> Void
//    ) {
//        guard let url = URL(string: baseURL + endpoint) else {
//            completion(.failure(.invalidURL))
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
////                print("Network error: \(error.localizedDescription)")
//                completion(.failure(.httpError(0)))
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(.httpError(0)))
//                return
//            }
//            
//            guard 200...299 ~= httpResponse.statusCode else {
//                completion(.failure(.httpError(httpResponse.statusCode)))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(.noData))
//                return
//            }
//            
//            do {
//                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
////                print("Raw decodedResponse: \(decodedResponse)\n")
//                completion(.success(decodedResponse))
//            } catch {
////                print("Decoding error: \(error)")
//                completion(.failure(.decodingError))
//            }
//        }.resume()
//    }
//    
//    func getPoliticalLeaning(for topic: String, completion: @escaping (Result<PoliticalLeaningResponse, NetworkError>) -> Void) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getPoliticalLeaning/\(encodedTopic)",
//            responseType: PoliticalLeaningResponse.self,
//            completion: completion
//        )
//    }
//    
//    func getFinancialContributionsOverview(for topic: String, completion: @escaping (Result<FinancialContributionsResponse, NetworkError>) -> Void) {
//        let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
//        makeRequest(
//            endpoint: "/getFinancialContributionsOverview/\(encodedTopic)",
//            responseType: FinancialContributionsResponse.self,
//            completion: completion
//        )
//    }
//}
