//
//  Models.swift
//  Compass AI V2
//
//  Created by Steve on 8/21/25.
//

import Foundation

// MARK: - Compass Match Quiz
struct SavedQuizResult: Codable, Equatable {
    let id: UUID
    let shareToken: String
    let title: String
    let subtitle: String
    let savedAt: Date
    
    init(id: UUID = UUID(), shareToken: String, title: String, subtitle: String, savedAt: Date = Date()) {
        self.id = id
        self.shareToken = shareToken
        self.title = title
        self.subtitle = subtitle
        self.savedAt = savedAt
    }
}

final class SavedQuizResultStore {
    static let shared = SavedQuizResultStore()
    
    private let storageKey = "CorporateCompass.savedQuizResults"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func load() -> [SavedQuizResult] {
        guard let data = userDefaults.data(forKey: storageKey),
              let results = try? JSONDecoder().decode([SavedQuizResult].self, from: data) else {
            return []
        }
        return results.sorted { $0.savedAt > $1.savedAt }
    }
    
    func contains(shareToken: String?) -> Bool {
        guard let shareToken else { return false }
        return load().contains { $0.shareToken == shareToken }
    }
    
    func save(_ result: SavedQuizResult) {
        var results = load().filter { $0.shareToken != result.shareToken }
        results.insert(result, at: 0)
        persist(results)
    }
    
    func remove(shareToken: String) {
        persist(load().filter { $0.shareToken != shareToken })
    }
    
    func remove(id: UUID) {
        persist(load().filter { $0.id != id })
    }
    
    private func persist(_ results: [SavedQuizResult]) {
        guard let data = try? JSONEncoder().encode(results) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}

enum QuizOptionValue: Codable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            self = .string(try container.decode(String.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .double(let value): return Int(value)
        default: return nil
        }
    }
    
    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}

struct QuizDefinitionResponse: Codable {
    let quizVersion: String
    let importance: QuizImportanceSection
    let stances: [QuizStanceQuestion]
    let categories: QuizCategorySection
    let dealbreakers: QuizDealbreakerSection
    let verification: QuizVerificationSection
    let methodologyNote: String
    let disclaimer: String?
    
    enum CodingKeys: String, CodingKey {
        case quizVersion = "quiz_version"
        case importance
        case stances
        case categories
        case dealbreakers
        case verification
        case methodologyNote = "methodology_note"
        case disclaimer
    }
}

struct QuizImportanceSection: Codable {
    let prompt: String
    let options: [QuizChoice]
    let issues: [QuizIssue]
}

struct QuizIssue: Codable {
    let key: String
    let label: String
    let help: String?
}

struct QuizChoice: Codable {
    let value: QuizOptionValue
    let label: String
}

struct QuizStanceQuestion: Codable {
    let key: String
    let prompt: String
    let help: String?
    let options: [QuizChoice]
}

struct QuizCategorySection: Codable {
    let prompt: String
    let options: [QuizCategoryOption]
}

struct QuizCategoryOption: Codable {
    let value: String
    let label: String
    let companyCount: Int
    let available: Bool
    
    enum CodingKeys: String, CodingKey {
        case value
        case label
        case companyCount = "company_count"
        case available
    }
}

struct QuizDealbreakerSection: Codable {
    let prompt: String
    let help: String
    let max: Int
    let options: [QuizDealbreakerOption]
}

struct QuizDealbreakerOption: Codable {
    let value: String
    let label: String
}

struct QuizVerificationSection: Codable {
    let key: String
    let prompt: String
    let options: [QuizChoice]
}

struct QuizSubmissionRequest: Codable {
    let quizVersion: String
    let weights: [String: Int]
    let stances: [String: QuizOptionValue]
    let categories: [String]
    let dealbreakers: [String]
    
    enum CodingKeys: String, CodingKey {
        case quizVersion = "quiz_version"
        case weights
        case stances
        case categories
        case dealbreakers
    }
}

struct QuizResultResponse: Codable {
    let success: Bool
    let quizVersion: String
    let asOf: String
    let methodologyNote: String
    let disclaimer: String?
    let results: [QuizCategoryResult]
    let shareToken: String?
    let shareWarning: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case quizVersion = "quiz_version"
        case asOf = "as_of"
        case methodologyNote = "methodology_note"
        case disclaimer
        case results
        case shareToken = "share_token"
        case shareWarning = "share_warning"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = (try? container.decodeIfPresent(Bool.self, forKey: .success)) ?? true
        quizVersion = (try? container.decodeIfPresent(String.self, forKey: .quizVersion)) ?? ""
        asOf = (try? container.decodeIfPresent(String.self, forKey: .asOf)) ?? ""
        methodologyNote = (try? container.decodeIfPresent(String.self, forKey: .methodologyNote)) ?? ""
        disclaimer = try? container.decodeIfPresent(String.self, forKey: .disclaimer)
        results = (try? container.decodeIfPresent([QuizCategoryResult].self, forKey: .results)) ?? []
        shareToken = try? container.decodeIfPresent(String.self, forKey: .shareToken)
        shareWarning = try? container.decodeIfPresent(String.self, forKey: .shareWarning)
    }
}

struct QuizCategoryResult: Codable {
    let category: String
    let label: String
    let considered: Int
    let excluded: QuizExcludedCounts
    let recommendations: [QuizRecommendation]
    let alternatives: [QuizAlternative]
    let allLowConfidence: Bool?
    let nothingRated: Bool?
    
    enum CodingKeys: String, CodingKey {
        case category
        case label
        case considered
        case excluded
        case recommendations
        case alternatives
        case allLowConfidence = "all_low_confidence"
        case nothingRated = "nothing_rated"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = (try? container.decodeIfPresent(String.self, forKey: .category)) ?? ""
        label = (try? container.decodeIfPresent(String.self, forKey: .label)) ?? category
        considered = (try? container.decodeIfPresent(Int.self, forKey: .considered)) ?? 0
        excluded = (try? container.decodeIfPresent(QuizExcludedCounts.self, forKey: .excluded)) ?? QuizExcludedCounts(didNotMatch: 0, couldNotVerify: 0)
        recommendations = (try? container.decodeIfPresent([QuizRecommendation].self, forKey: .recommendations)) ?? []
        alternatives = (try? container.decodeIfPresent([QuizAlternative].self, forKey: .alternatives)) ?? []
        allLowConfidence = try? container.decodeIfPresent(Bool.self, forKey: .allLowConfidence)
        nothingRated = try? container.decodeIfPresent(Bool.self, forKey: .nothingRated)
    }
}

struct QuizExcludedCounts: Codable {
    let didNotMatch: Int
    let couldNotVerify: Int
    
    init(didNotMatch: Int, couldNotVerify: Int) {
        self.didNotMatch = didNotMatch
        self.couldNotVerify = couldNotVerify
    }
    
    enum CodingKeys: String, CodingKey {
        case didNotMatch = "did_not_match"
        case couldNotVerify = "could_not_verify"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        didNotMatch = (try? container.decodeIfPresent(Int.self, forKey: .didNotMatch)) ?? 0
        couldNotVerify = (try? container.decodeIfPresent(Int.self, forKey: .couldNotVerify)) ?? 0
    }
}

struct QuizRecommendation: Codable {
    let normalizedTopicName: String
    let topic: String
    let match: Double?
    let coverage: Double
    let band: String?
    let status: String
    let issueRows: [QuizIssueRow]
    let missingIssues: [String]
    let headline: String?
    let bandText: String?
    let lowConfidence: Bool?
    let bestAvailable: Bool?
    let confidenceNote: String?
    let evidence: [QuizEvidence]
    let notKnown: [String]
    
    enum CodingKeys: String, CodingKey {
        case normalizedTopicName = "normalized_topic_name"
        case topic
        case match
        case coverage
        case band
        case status
        case issueRows = "issue_rows"
        case missingIssues = "missing_issues"
        case headline
        case bandText = "band_text"
        case lowConfidence = "low_confidence"
        case bestAvailable = "best_available"
        case confidenceNote = "confidence_note"
        case evidence
        case notKnown = "not_known"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        normalizedTopicName = (try? container.decodeIfPresent(String.self, forKey: .normalizedTopicName)) ?? ""
        topic = (try? container.decodeIfPresent(String.self, forKey: .topic)) ?? normalizedTopicName
        match = try? container.decodeIfPresent(Double.self, forKey: .match)
        coverage = (try? container.decodeIfPresent(Double.self, forKey: .coverage)) ?? 0
        band = try? container.decodeIfPresent(String.self, forKey: .band)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "eligible"
        issueRows = (try? container.decodeIfPresent([QuizIssueRow].self, forKey: .issueRows)) ?? []
        missingIssues = (try? container.decodeIfPresent([String].self, forKey: .missingIssues)) ?? []
        headline = try? container.decodeIfPresent(String.self, forKey: .headline)
        bandText = try? container.decodeIfPresent(String.self, forKey: .bandText)
        lowConfidence = try? container.decodeIfPresent(Bool.self, forKey: .lowConfidence)
        bestAvailable = try? container.decodeIfPresent(Bool.self, forKey: .bestAvailable)
        confidenceNote = try? container.decodeIfPresent(String.self, forKey: .confidenceNote)
        evidence = (try? container.decodeIfPresent([QuizEvidence].self, forKey: .evidence)) ?? []
        notKnown = (try? container.decodeIfPresent([String].self, forKey: .notKnown)) ?? []
    }
}

struct QuizIssueRow: Codable {
    let issue: String
    let label: String
    let weight: Int
    let stance: QuizOptionValue?
    let value: Double?
    let alignment: Double?
    let contribution: Double
    let known: Bool
    let axis: String?
    let asOf: String?
    let stanceText: String?
    let valueText: String?
    let missingNote: String?
    
    enum CodingKeys: String, CodingKey {
        case issue
        case label
        case weight
        case stance
        case value
        case alignment
        case contribution
        case known
        case axis
        case asOf = "as_of"
        case stanceText = "stance_text"
        case valueText = "value_text"
        case missingNote = "missing_note"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        issue = (try? container.decodeIfPresent(String.self, forKey: .issue)) ?? ""
        label = (try? container.decodeIfPresent(String.self, forKey: .label)) ?? issue
        weight = (try? container.decodeIfPresent(Int.self, forKey: .weight)) ?? 0
        stance = try? container.decodeIfPresent(QuizOptionValue.self, forKey: .stance)
        value = try? container.decodeIfPresent(Double.self, forKey: .value)
        alignment = try? container.decodeIfPresent(Double.self, forKey: .alignment)
        contribution = (try? container.decodeIfPresent(Double.self, forKey: .contribution)) ?? 0
        known = (try? container.decodeIfPresent(Bool.self, forKey: .known)) ?? false
        axis = try? container.decodeIfPresent(String.self, forKey: .axis)
        asOf = try? container.decodeIfPresent(String.self, forKey: .asOf)
        stanceText = try? container.decodeIfPresent(String.self, forKey: .stanceText)
        valueText = try? container.decodeIfPresent(String.self, forKey: .valueText)
        missingNote = try? container.decodeIfPresent(String.self, forKey: .missingNote)
    }
}

struct QuizEvidence: Codable {
    let axis: String?
    let axisLabel: String?
    let sourceNote: String?
    let summary: String?
    let context: String?
    let citation: String?
    let answerId: Int?
    let queryType: String?
    let asOf: String?
    
    enum CodingKeys: String, CodingKey {
        case axis
        case axisLabel = "axis_label"
        case sourceNote = "source_note"
        case summary
        case context
        case citation
        case answerId = "answer_id"
        case queryType = "query_type"
        case asOf = "as_of"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        axis = try? container.decodeIfPresent(String.self, forKey: .axis)
        axisLabel = try? container.decodeIfPresent(String.self, forKey: .axisLabel)
        sourceNote = try? container.decodeIfPresent(String.self, forKey: .sourceNote)
        summary = try? container.decodeIfPresent(String.self, forKey: .summary)
        context = try? container.decodeIfPresent(String.self, forKey: .context)
        citation = try? container.decodeIfPresent(String.self, forKey: .citation)
        answerId = (try? container.decodeIfPresent(Int.self, forKey: .answerId)) ?? Int((try? container.decodeIfPresent(String.self, forKey: .answerId)) ?? "")
        queryType = try? container.decodeIfPresent(String.self, forKey: .queryType)
        asOf = try? container.decodeIfPresent(String.self, forKey: .asOf)
    }
}

struct QuizAlternative: Codable {
    let normalizedTopicName: String
    let topic: String
    let match: Double?
    let coverage: Double
    let band: String?
    
    enum CodingKeys: String, CodingKey {
        case normalizedTopicName = "normalized_topic_name"
        case topic
        case match
        case coverage
        case band
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        normalizedTopicName = (try? container.decodeIfPresent(String.self, forKey: .normalizedTopicName)) ?? ""
        topic = (try? container.decodeIfPresent(String.self, forKey: .topic)) ?? normalizedTopicName
        match = try? container.decodeIfPresent(Double.self, forKey: .match)
        coverage = (try? container.decodeIfPresent(Double.self, forKey: .coverage)) ?? 0
        band = try? container.decodeIfPresent(String.self, forKey: .band)
    }
}

// MARK: - Organization Analysis
struct OrganizationAnalysis {
    let topic: String
    let lean: String
    let rating: Int
    let description: String
    let hasFinancialContributions: Bool
    let financialContributionsText: String?
    let financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
    let leadershipDemographicsAnalysis: LeadershipDemographicsAnalysis?
    let category: CurrentSearchCategory
    
    // MARK: - Initializers
    
    /// Full initializer with category
    init(
        topic: String,
        lean: String,
        rating: Int,
        description: String,
        hasFinancialContributions: Bool,
        financialContributionsText: String?,
        financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?,
        leadershipDemographicsAnalysis: LeadershipDemographicsAnalysis? = nil,
        category: CurrentSearchCategory = .politicalLeaning
    ) {
        self.topic = topic
        self.lean = lean
        self.rating = rating
        self.description = description
        self.hasFinancialContributions = hasFinancialContributions
        self.financialContributionsText = financialContributionsText
        self.financialContributionsOverviewAnalysis = financialContributionsOverviewAnalysis
        self.leadershipDemographicsAnalysis = leadershipDemographicsAnalysis
        self.category = category
    }
    
    // MARK: - Computed Properties
    
    /// Returns the appropriate low-end label for the rating scale based on category
    var lowRatingLabel: String {
        return category.lowRatingLabel
    }
    
    /// Returns the appropriate high-end label for the rating scale based on category
    var highRatingLabel: String {
        return category.highRatingLabel
    }
    
    /// Returns whether this category should show the standard rating scale UI
    var shouldShowRatingScale: Bool {
        switch category {
        case .financialContributions, .leadershipDemographics:
            return false // These categories use different UI
        default:
            return true
        }
    }
    
    /// Returns whether this category has additional financial data to display
    var hasFinancialDataToDisplay: Bool {
        return category == .financialContributions && financialContributionsOverviewAnalysis != nil
    }
}

// MARK: - Financial Contributions Analysis
struct FinancialContributionsAnalysis {
    let financialContributionsText: String?
    let committeeOrPACName: String?
    let committeeOrPACID: String?
    let percentContributions: PercentContributions?
    let contributionTotals: [ContributionTotal]?
    let leadershipContributionsToCommittee: [LeadershipContribution]?
}

// MARK: - Leadership Demographics Analysis
struct LeadershipDemographicsAnalysis: Codable {
    let resolvedCompany: String?
    let ticker: String?
    let companyPageURL: String?
    let sourceURL: String?
    let sourceDetail: String?
    let caveat: String?
    let method: String?
    let peopleTotal: Int
    let peopleEstimated: Int
    let peopleUnmatched: Int
    let segments: [LeadershipDemographicsSegment]
    
    var matchedSummary: String {
        let unmatchedText = peopleUnmatched == 1 ? "1 without a surname match" : "\(peopleUnmatched) without a surname match"
        return "Based on \(peopleEstimated) of \(peopleTotal) officers · \(unmatchedText)"
    }
}

struct LeadershipDemographicsSegment: Codable {
    let group: String
    let expected: Double
    let percentage: Int
}

// MARK: - Leadership Demographics Response
struct LeadershipDemographicsResponse: Codable {
    let topic: String
    let normalizedTopicName: String?
    let timestamp: String?
    let officerCount: Int?
    let source: String?
    let sourceDetail: String?
    let sourceURL: String?
    let companyPageURL: String?
    let demographics: LeadershipDemographicsPayload?
    let resolvedCompany: String?
    let ticker: String?
    let isCompany: Bool?
    let reason: String?
    let cached: Bool?
    
    enum CodingKeys: String, CodingKey {
        case topic
        case normalizedTopicName = "normalized_topic_name"
        case timestamp
        case officerCount = "officer_count"
        case source
        case sourceDetail = "source_detail"
        case sourceURL = "source_url"
        case companyPageURL = "company_page_url"
        case demographics
        case resolvedCompany = "resolved_company"
        case ticker
        case isCompany = "is_company"
        case reason
        case cached
    }
    
    var analysis: LeadershipDemographicsAnalysis? {
        guard let demographics else { return nil }
        let counts = demographics.expectedCounts
            .filter { $0.expected > 0 }
            .sorted { $0.expected > $1.expected }
        let percentages = Self.roundedPercentages(for: counts.map(\.expected))
        let segments = zip(counts, percentages).map { count, percentage in
            LeadershipDemographicsSegment(
                group: count.group,
                expected: count.expected,
                percentage: percentage
            )
        }
        
        return LeadershipDemographicsAnalysis(
            resolvedCompany: resolvedCompany,
            ticker: ticker,
            companyPageURL: companyPageURL ?? demographics.companyPageURL,
            sourceURL: demographics.sourceURL ?? sourceURL,
            sourceDetail: sourceDetail,
            caveat: demographics.caveat,
            method: demographics.method,
            peopleTotal: demographics.peopleTotal,
            peopleEstimated: demographics.peopleEstimated,
            peopleUnmatched: demographics.peopleUnmatched,
            segments: segments
        )
    }
    
    private static func roundedPercentages(for values: [Double]) -> [Int] {
        let total = values.reduce(0, +)
        guard total > 0 else { return values.map { _ in 0 } }
        
        let rawPercentages = values.map { ($0 / total) * 100.0 }
        var rounded = rawPercentages.map { Int($0.rounded(.down)) }
        let remaining = 100 - rounded.reduce(0, +)
        
        let remainderIndexes = rawPercentages
            .enumerated()
            .sorted { lhs, rhs in
                let lhsRemainder = lhs.element - Double(Int(lhs.element))
                let rhsRemainder = rhs.element - Double(Int(rhs.element))
                return lhsRemainder > rhsRemainder
            }
            .map(\.offset)
        
        for index in remainderIndexes.prefix(max(remaining, 0)) {
            rounded[index] += 1
        }
        
        return rounded
    }
}

struct LeadershipDemographicsPayload: Codable {
    let caveat: String?
    let method: String?
    let sourceURL: String?
    let companyPageURL: String?
    let isEstimate: Bool?
    let peopleTotal: Int
    let expectedCounts: [LeadershipExpectedCount]
    let peopleEstimated: Int
    let peopleUnmatched: Int
    
    enum CodingKeys: String, CodingKey {
        case caveat
        case method
        case sourceURL = "source_url"
        case companyPageURL = "company_page_url"
        case isEstimate = "is_estimate"
        case peopleTotal = "people_total"
        case expectedCounts = "expected_counts"
        case peopleEstimated = "people_estimated"
        case peopleUnmatched = "people_unmatched"
        case estimatedEthnicity = "estimated_ethnicity"
        case teamSize = "team_size"
        case coverage
    }
    
    enum EstimatedEthnicityKeys: String, CodingKey {
        case caveat
        case method
        case sourceURL = "source_url"
        case isEstimate = "is_estimate"
        case groups
    }
    
    enum CoverageKeys: String, CodingKey {
        case noData = "no_data"
        case estimated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        companyPageURL = try container.decodeIfPresent(String.self, forKey: .companyPageURL)
        
        if let estimatedEthnicity = try? container.nestedContainer(keyedBy: EstimatedEthnicityKeys.self, forKey: .estimatedEthnicity) {
            caveat = try estimatedEthnicity.decodeIfPresent(String.self, forKey: .caveat)
            method = try estimatedEthnicity.decodeIfPresent(String.self, forKey: .method)
            sourceURL = try estimatedEthnicity.decodeIfPresent(String.self, forKey: .sourceURL)
            isEstimate = try estimatedEthnicity.decodeIfPresent(Bool.self, forKey: .isEstimate)
            expectedCounts = try estimatedEthnicity.decodeIfPresent([LeadershipExpectedCount].self, forKey: .groups) ?? []
        } else {
            caveat = try container.decodeIfPresent(String.self, forKey: .caveat)
            method = try container.decodeIfPresent(String.self, forKey: .method)
            sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
            isEstimate = try container.decodeIfPresent(Bool.self, forKey: .isEstimate)
            expectedCounts = try container.decodeIfPresent([LeadershipExpectedCount].self, forKey: .expectedCounts) ?? []
        }
        
        let coverage = try? container.nestedContainer(keyedBy: CoverageKeys.self, forKey: .coverage)
        peopleTotal = try container.decodeIfPresent(Int.self, forKey: .peopleTotal)
            ?? container.decodeIfPresent(Int.self, forKey: .teamSize)
            ?? coverage?.decodeIfPresent(Int.self, forKey: .estimated)
            ?? 0
        peopleEstimated = try container.decodeIfPresent(Int.self, forKey: .peopleEstimated)
            ?? coverage?.decodeIfPresent(Int.self, forKey: .estimated)
            ?? peopleTotal
        peopleUnmatched = try container.decodeIfPresent(Int.self, forKey: .peopleUnmatched)
            ?? coverage?.decodeIfPresent(Int.self, forKey: .noData)
            ?? max(peopleTotal - peopleEstimated, 0)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(caveat, forKey: .caveat)
        try container.encodeIfPresent(method, forKey: .method)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
        try container.encodeIfPresent(companyPageURL, forKey: .companyPageURL)
        try container.encodeIfPresent(isEstimate, forKey: .isEstimate)
        try container.encode(peopleTotal, forKey: .peopleTotal)
        try container.encode(expectedCounts, forKey: .expectedCounts)
        try container.encode(peopleEstimated, forKey: .peopleEstimated)
        try container.encode(peopleUnmatched, forKey: .peopleUnmatched)
    }
}

struct LeadershipExpectedCount: Codable {
    let group: String
    let expected: Double
    
    enum CodingKeys: String, CodingKey {
        case group
        case expected
        case percent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        group = try container.decode(String.self, forKey: .group)
        expected = try container.decodeIfPresent(Double.self, forKey: .expected)
            ?? container.decodeIfPresent(Double.self, forKey: .percent)
            ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(group, forKey: .group)
        try container.encode(expected, forKey: .expected)
    }
}

// MARK: - Political Leaning Response
struct PoliticalLeaningResponse: Codable {
    // Mandatory
    let lean: String
    let rating: FlexibleInt
    let context: String
    let createdWithFinancialContributionsInfo: Bool
    // Optional
    let timestamp: Double?
    let normalizedTopicName: String?
    let topic: String?
    let citation: String?
    let upvoteCount: Int?
    let downvoteCount: Int?
    let queryType: String?
    let debug: DebugInfo?
    let response_error: PoliticalLeaningResponseError?
    
    enum CodingKeys: String, CodingKey {
        case lean
        case rating
        case context
        case createdWithFinancialContributionsInfo = "created_with_financial_contributions_info"
        case timestamp
        case normalizedTopicName = "normalized_topic_name"
        case topic
        case citation
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case queryType = "query_type"
        case debug
        case response_error
        case response
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to get rating, lean, and context from nested response object first
        if let responseObject = try? container.nestedContainer(keyedBy: ResponseKeys.self, forKey: .response) {
            rating = try responseObject.decode(FlexibleInt.self, forKey: .rating)
            lean = try responseObject.decode(String.self, forKey: .lean)
            context = try responseObject.decode(String.self, forKey: .context)
            createdWithFinancialContributionsInfo = try responseObject.decode(Bool.self, forKey: .createdWithFinancialContributionsInfo)
            
            timestamp = nil
            normalizedTopicName = nil
            topic = nil
            citation = nil
            upvoteCount = nil
            downvoteCount = nil
            queryType = nil
            debug = nil
            response_error = nil
            
        } else {
            // Fall back to top-level fields (correct case)
            rating = try container.decode(FlexibleInt.self, forKey: .rating)
            lean = try container.decode(String.self, forKey: .lean)
            context = try container.decode(String.self, forKey: .context)
            createdWithFinancialContributionsInfo = try container.decode(Bool.self, forKey: .createdWithFinancialContributionsInfo)
            timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp)
            normalizedTopicName = try container.decodeIfPresent(String.self, forKey: .normalizedTopicName)
            topic = try container.decodeIfPresent(String.self, forKey: .topic)
            citation = try container.decodeIfPresent(String.self, forKey: .citation)
            upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount)
            downvoteCount = try container.decodeIfPresent(Int.self, forKey: .downvoteCount)
            queryType = try container.decodeIfPresent(String.self, forKey: .queryType)
            debug = try container.decodeIfPresent(DebugInfo.self, forKey: .debug)
            response_error = try container.decodeIfPresent(PoliticalLeaningResponseError.self, forKey: .response_error)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(normalizedTopicName, forKey: .normalizedTopicName)
        try container.encodeIfPresent(topic, forKey: .topic)
        try container.encode(rating, forKey: .rating)
        try container.encode(context, forKey: .context)
        try container.encodeIfPresent(citation, forKey: .citation)
        try container.encode(createdWithFinancialContributionsInfo, forKey: .createdWithFinancialContributionsInfo)
        try container.encode(lean, forKey: .lean)
        try container.encodeIfPresent(upvoteCount, forKey: .upvoteCount)
        try container.encodeIfPresent(downvoteCount, forKey: .downvoteCount)
        try container.encodeIfPresent(queryType, forKey: .queryType)
        try container.encodeIfPresent(debug, forKey: .debug)
    }
    
    private enum ResponseKeys: String, CodingKey {
        case rating
        case lean
        case context
        case createdWithFinancialContributionsInfo = "created_with_financial_contributions_info"
    }
}

// MARK: - Category Analysis Response
// Used for DEI Friendliness, Wokeness, Environmental Impact, Immigration Support, Technology Innovation
struct CategoryAnalysisResponse: Codable {
    let normalizedTopicName: String?
    let timestamp: Double?
    let topic: String?
    let rating: FlexibleInt
    let context: String
    let citation: String?
    let createdWithFinancialContributionsInfo: Bool
    let upvoteCount: Int?
    let downvoteCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case normalizedTopicName = "normalized_topic_name"
        case timestamp
        case topic
        case rating
        case context
        case citation
        case createdWithFinancialContributionsInfo = "created_with_financial_contributions_info"
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
    }
}

// MARK: - Flexible Int (handles String or Int rating)
struct FlexibleInt: Codable {
    let value: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self),
                  let intValue = Int(stringValue) {
            value = intValue
        } else {
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected Int or String that can be converted to Int"
            ))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Debug Info
struct DebugInfo: Codable {
    let persistedResponse: Bool
    let newlyGenerated: Bool
    
    enum CodingKeys: String, CodingKey {
        case persistedResponse = "persisted_response"
        case newlyGenerated = "newly_generated"
    }
}

// MARK: - Political Leaning Response Error
struct PoliticalLeaningResponseError: Codable {
    let error: Bool?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
    }
}

// MARK: - Financial Contributions Response
struct FinancialContributionsResponse: Codable {
    let id: Int?
    let topic: String
    let normalizedTopicName: String?
    let timestamp: String?
    let committeeId: String
    let individualId: Int
    let fecFinancialContributionsSummaryText: String
    let summary: String?
    let message: String?
    let scopeNote: String?
    let sourceURL: String?
    let committeeStatus: String?
    let hasPAC: Bool?
    let resolvedViaParent: String?
    let searchedAs: [String]?
    let cached: Bool?
    let fullAnswerAvailable: Bool?
    let percentContributionsAvailable: Bool?
    let textAvailable: Bool?
    let error: Bool?
    let favorited: Bool?
    let upvoteCount: Int?
    let downvoteCount: Int?
    let timeRangeOfData: String?
    let cycleEndYear: String?
    let committeeName: String?
    let queryType: String?
    let debug: FinancialDebugInfo?
    let percentContributions: PercentContributions?
    var contributionTotals: [ContributionTotal]?
    var leadershipContributionsToCommittee: [LeadershipContribution]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case topic
        case normalizedTopicName = "normalized_topic_name"
        case timestamp
        case committeeId = "committee_id"
        case individualId = "individual_id"
        case fecFinancialContributionsSummaryText = "fec_financial_contributions_summary_text"
        case summary
        case message
        case scopeNote = "scope_note"
        case sourceURL = "source_url"
        case committeeStatus = "committee_status"
        case hasPAC = "has_pac"
        case resolvedViaParent = "resolved_via_parent"
        case searchedAs = "searched_as"
        case cached
        case fullAnswerAvailable = "full_answer_available"
        case percentContributionsAvailable = "percent_contributions_available"
        case textAvailable = "text_available"
        case error
        case favorited
        case upvoteCount = "upvote_count"
        case downvoteCount = "downvote_count"
        case timeRangeOfData = "time_range_of_data"
        case cycleEndYear = "cycle_end_year"
        case committeeName = "committee_name"
        case queryType = "query_type"
        case debug
        case percentContributions = "percent_contributions"
        case contributionTotals = "contribution_totals"
        case leadershipContributionsToCommittee = "leadership_contributors_to_committee"
    }

    init(
        id: Int? = nil,
        topic: String,
        normalizedTopicName: String?,
        timestamp: String?,
        committeeId: String,
        individualId: Int,
        fecFinancialContributionsSummaryText: String,
        summary: String? = nil,
        message: String? = nil,
        scopeNote: String? = nil,
        sourceURL: String? = nil,
        committeeStatus: String? = nil,
        hasPAC: Bool? = nil,
        resolvedViaParent: String? = nil,
        searchedAs: [String]? = nil,
        cached: Bool? = nil,
        fullAnswerAvailable: Bool? = nil,
        percentContributionsAvailable: Bool? = nil,
        textAvailable: Bool? = nil,
        error: Bool? = nil,
        favorited: Bool? = nil,
        upvoteCount: Int?,
        downvoteCount: Int?,
        timeRangeOfData: String?,
        cycleEndYear: String?,
        committeeName: String?,
        queryType: String?,
        debug: FinancialDebugInfo?,
        percentContributions: PercentContributions?,
        contributionTotals: [ContributionTotal]?,
        leadershipContributionsToCommittee: [LeadershipContribution]?
    ) {
        self.id = id
        self.topic = topic
        self.normalizedTopicName = normalizedTopicName
        self.timestamp = timestamp
        self.committeeId = committeeId
        self.individualId = individualId
        self.fecFinancialContributionsSummaryText = fecFinancialContributionsSummaryText
        self.summary = summary
        self.message = message
        self.scopeNote = scopeNote
        self.sourceURL = sourceURL
        self.committeeStatus = committeeStatus
        self.hasPAC = hasPAC
        self.resolvedViaParent = resolvedViaParent
        self.searchedAs = searchedAs
        self.cached = cached
        self.fullAnswerAvailable = fullAnswerAvailable
        self.percentContributionsAvailable = percentContributionsAvailable
        self.textAvailable = textAvailable
        self.error = error
        self.favorited = favorited
        self.upvoteCount = upvoteCount
        self.downvoteCount = downvoteCount
        self.timeRangeOfData = timeRangeOfData
        self.cycleEndYear = cycleEndYear
        self.committeeName = committeeName
        self.queryType = queryType
        self.debug = debug
        self.percentContributions = percentContributions
        self.contributionTotals = contributionTotals
        self.leadershipContributionsToCommittee = leadershipContributionsToCommittee
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        topic = try container.decodeIfPresent(String.self, forKey: .topic) ?? ""
        normalizedTopicName = try container.decodeIfPresent(String.self, forKey: .normalizedTopicName)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        committeeId = try container.decodeIfPresent(String.self, forKey: .committeeId) ?? ""
        individualId = try container.decodeIfPresent(Int.self, forKey: .individualId) ?? 0
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        scopeNote = try container.decodeIfPresent(String.self, forKey: .scopeNote)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        committeeStatus = try container.decodeIfPresent(String.self, forKey: .committeeStatus)
        hasPAC = try container.decodeIfPresent(Bool.self, forKey: .hasPAC)
        resolvedViaParent = try container.decodeIfPresent(String.self, forKey: .resolvedViaParent)
        searchedAs = try container.decodeIfPresent([String].self, forKey: .searchedAs)
        cached = try container.decodeIfPresent(Bool.self, forKey: .cached)
        fullAnswerAvailable = try container.decodeIfPresent(Bool.self, forKey: .fullAnswerAvailable)
        percentContributionsAvailable = try container.decodeIfPresent(Bool.self, forKey: .percentContributionsAvailable)
        textAvailable = try container.decodeIfPresent(Bool.self, forKey: .textAvailable)
        error = try container.decodeIfPresent(Bool.self, forKey: .error)
        favorited = try container.decodeIfPresent(Bool.self, forKey: .favorited)
        upvoteCount = try container.decodeIfPresent(Int.self, forKey: .upvoteCount)
        downvoteCount = try container.decodeIfPresent(Int.self, forKey: .downvoteCount)
        timeRangeOfData = try container.decodeIfPresent(String.self, forKey: .timeRangeOfData)
        cycleEndYear = try container.decodeIfPresent(String.self, forKey: .cycleEndYear)
        committeeName = try container.decodeIfPresent(String.self, forKey: .committeeName)
        queryType = try container.decodeIfPresent(String.self, forKey: .queryType)
        debug = try container.decodeIfPresent(FinancialDebugInfo.self, forKey: .debug)
        percentContributions = try container.decodeIfPresent(PercentContributions.self, forKey: .percentContributions)
        contributionTotals = try container.decodeIfPresent([ContributionTotal].self, forKey: .contributionTotals)
        leadershipContributionsToCommittee = try container.decodeIfPresent([LeadershipContribution].self, forKey: .leadershipContributionsToCommittee)

        let summaryText = try container.decodeIfPresent(String.self, forKey: .fecFinancialContributionsSummaryText)
        fecFinancialContributionsSummaryText = Self.displayText(
            summaryText: summaryText,
            message: message,
            scopeNote: scopeNote,
            searchedAs: searchedAs
        )
    }

    private static func displayText(
        summaryText: String?,
        message: String?,
        scopeNote: String?,
        searchedAs: [String]?
    ) -> String {
        if let summaryText, !summaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return summaryText
        }

        let parts = [message, scopeNote].compactMap { text -> String? in
            guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return text
        }

        if !parts.isEmpty {
            return parts.joined(separator: "\n\n")
        }

        if let searchedAs, !searchedAs.isEmpty {
            return "No political committee matching this company was found in the FEC data.\n\nSearched as: \(searchedAs.joined(separator: ", "))"
        }

        return "No financial contribution details are available for this organization."
    }
}

// MARK: - Financial Debug Info
struct FinancialDebugInfo: Codable {
    let modelUsed: String?
    let automatedEntry: Bool?
    let dateGenerated: String?
    let truncatedData: Bool?
    let percentOfDataWithinTimeRange: Int?
    let persistedResponse: Bool?
    let newlyGenerated: Bool?
    
    enum CodingKeys: String, CodingKey {
        case modelUsed = "model_used"
        case automatedEntry = "automated_entry"
        case dateGenerated = "date_generated"
        case truncatedData = "truncated_data"
        case percentOfDataWithinTimeRange = "precent_of_data_within_time_range"
        case persistedResponse = "persisted_response"
        case newlyGenerated = "newly_generated"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modelUsed = try? container.decodeIfPresent(String.self, forKey: .modelUsed)
        automatedEntry = try? container.decodeIfPresent(Bool.self, forKey: .automatedEntry)
        dateGenerated = try? container.decodeIfPresent(String.self, forKey: .dateGenerated)
        truncatedData = try? container.decodeIfPresent(Bool.self, forKey: .truncatedData)
        percentOfDataWithinTimeRange = try? container.decodeIfPresent(Int.self, forKey: .percentOfDataWithinTimeRange)
        persistedResponse = try? container.decodeIfPresent(Bool.self, forKey: .persistedResponse)
        newlyGenerated = try? container.decodeIfPresent(Bool.self, forKey: .newlyGenerated)
    }

    init(
        modelUsed: String?,
        automatedEntry: Bool?,
        dateGenerated: String?,
        truncatedData: Bool?,
        percentOfDataWithinTimeRange: Int?,
        persistedResponse: Bool?,
        newlyGenerated: Bool?
    ) {
        self.modelUsed = modelUsed
        self.automatedEntry = automatedEntry
        self.dateGenerated = dateGenerated
        self.truncatedData = truncatedData
        self.percentOfDataWithinTimeRange = percentOfDataWithinTimeRange
        self.persistedResponse = persistedResponse
        self.newlyGenerated = newlyGenerated
    }
}

// MARK: - Percent Contributions
struct PercentContributions: Codable {
    let totalToDemocrats: Int
    let totalToRepublicans: Int
    let percentToDemocrats: Float
    let percentToRepublicans: Float
    let totalContributions: Int
    
    enum CodingKeys: String, CodingKey {
        case totalToDemocrats = "total_to_democrats"
        case totalToRepublicans = "total_to_republicans"
        case percentToDemocrats = "percent_to_democrats"
        case percentToRepublicans = "percent_to_republicans"
        case totalContributions = "total_contributions"
    }
}

// MARK: - Contribution Total
struct ContributionTotal: Codable {
    let recipientID: String?
    let recipientName: String?
    let numberOfContributions: Int?
    let totalContributionAmount: Int?
    
    enum CodingKeys: String, CodingKey {
        case recipientID = "recipient_id"
        case recipientName = "recipient_name"
        case numberOfContributions = "number_of_contributions"
        case totalContributionAmount = "total_contribution_amount"
    }
}

// MARK: - Leadership Contribution
struct LeadershipContribution: Codable {
    let occupation: String
    let name: String
    let employer: String
    let transactionAmount: String
    
    enum CodingKeys: String, CodingKey {
        case occupation
        case name
        case employer
        case transactionAmount = "transaction_amount"
    }
}
////
////  Models.swift
////  Compass AI V2
////
////  Created by Steve on 8/21/25.
////
//
//// MARK: - Models
//struct OrganizationAnalysis {
//    let topic: String
//    let lean: String
//    let rating: Int // FlexibleInt // TODO: Remove and replace with int once the backend is correctly updated.
//    let description: String
//    let hasFinancialContributions: Bool
//    let financialContributionsText: String?
//    let financialContributionsOverviewAnalysis: FinancialContributionsAnalysis?
//}
//
//struct FinancialContributionsAnalysis {
//    let financialContributionsText: String?
//    let committeeOrPACName: String?
//    let committeeOrPACID: String?
//    let percentContributions: PercentContributions?
//    let contributionTotals: [ContributionTotal]?
//    let leadershipContributionsToCommittee: [LeadershipContribution]?
//}
//
//struct PoliticalLeaningResponse: Codable {
//    // Mandatory
//    let lean: String
//    let rating: FlexibleInt // TODO: Remove and replace with int once the backend is correctly updated.
//    let context: String
//    let createdWithFinancialContributionsInfo: Bool
//    // Optional
//    let timestamp: Double?
//    let normalizedTopicName: String?
//    let topic: String?
//    let citation: String?
//    let upvoteCount: Int?
//    let downvoteCount: Int?
//    let queryType: String?
//    let debug: DebugInfo?
//    let response_error: PoliticalLeaningResponseError?
//    
//    enum CodingKeys: String, CodingKey {
//        case lean
//        case rating
//        case context
//        case createdWithFinancialContributionsInfo = "created_with_financial_contributions_info"
//        case timestamp
//        case normalizedTopicName = "normalized_topic_name"
//        case topic
//        case citation
//        case upvoteCount = "upvote_count"
//        case downvoteCount = "downvote_count"
//        case queryType = "query_type"
//        case debug
//        case response_error
//        case response
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        // Try to get rating, lean, and context from nested response object first
//        // TODO: Make this never get returned from the backend.
//        if let responseObject = try? container.nestedContainer(keyedBy: ResponseKeys.self, forKey: .response) {
//
//            rating = try responseObject.decode(FlexibleInt.self, forKey: .rating)
////            rating = try responseObject.decode(Int.self, forKey: .rating)
//            lean = try responseObject.decode(String.self, forKey: .lean)
//            context = try responseObject.decode(String.self, forKey: .context)
//            createdWithFinancialContributionsInfo = try responseObject.decode(Bool.self, forKey: .createdWithFinancialContributionsInfo)
//            
//            timestamp = nil
//            normalizedTopicName = nil
//            topic = nil
//            citation = nil
//            upvoteCount = nil
//            downvoteCount = nil
//            queryType = nil
//            debug  = nil
//            response_error = nil
//            
//        } else {
//            // Fall back to top-level fields
//            // This is the correct case.
//            // TODO: Change the backend so that this is the only type we need to account for.
//            rating = try container.decode(FlexibleInt.self, forKey: .rating)
////            rating = try container.decode(Int.self, forKey: .rating)
//            lean = try container.decode(String.self, forKey: .lean)
//            context = try container.decode(String.self, forKey: .context)
//            createdWithFinancialContributionsInfo = try container.decode(Bool.self, forKey: .createdWithFinancialContributionsInfo)
//            timestamp = try container.decode(Double.self, forKey: .timestamp)
//            normalizedTopicName = try container.decode(String.self, forKey: .normalizedTopicName)
//            topic = try container.decode(String.self, forKey: .topic)
//            citation = try container.decode(String.self, forKey: .citation)
//            upvoteCount = try container.decode(Int.self, forKey: .upvoteCount)
//            downvoteCount = try container.decode(Int.self, forKey: .downvoteCount)
//            queryType = try container.decode(String.self, forKey: .queryType)
//            debug = try container.decode(DebugInfo.self, forKey: .debug)
//            response_error = try container.decode(PoliticalLeaningResponseError.self, forKey: .debug)
//        }
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        
//        try container.encode(timestamp, forKey: .timestamp)
//        try container.encode(normalizedTopicName, forKey: .normalizedTopicName)
//        try container.encode(topic, forKey: .topic)
//        try container.encode(rating, forKey: .rating)
//        try container.encode(context, forKey: .context)
//        try container.encode(citation, forKey: .citation)
//        try container.encode(createdWithFinancialContributionsInfo, forKey: .createdWithFinancialContributionsInfo)
//        try container.encode(lean, forKey: .lean)
//        try container.encode(upvoteCount, forKey: .upvoteCount)
//        try container.encode(downvoteCount, forKey: .downvoteCount)
//        try container.encode(queryType, forKey: .queryType)
//        try container.encode(debug, forKey: .debug)
//    }
//    
//    private enum ResponseKeys: String, CodingKey {
//        case rating
//        case lean
//        case context
//        case createdWithFinancialContributionsInfo  = "created_with_financial_contributions_info"
//    }
//}
//
//// The backend could return either a string or in as the rating. This is a workaround. Only temporary.
//struct FlexibleInt: Codable {
//    let value: Int
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        
//        if let intValue = try? container.decode(Int.self) {
//            value = intValue
//        } else if let stringValue = try? container.decode(String.self),
//                  let intValue = Int(stringValue) {
//            value = intValue
//        } else {
//            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(
//                codingPath: decoder.codingPath,
//                debugDescription: "Expected Int or String that can be converted to Int"
//            ))
//        }
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(value)
//    }
//}
//
//struct DebugInfo: Codable {
//    let persistedResponse: Bool
//    let newlyGenerated: Bool
//    
//    enum CodingKeys: String, CodingKey {
//        case persistedResponse = "persisted_response"
//        case newlyGenerated = "newly_generated"
//    }
//}
//
//struct PoliticalLeaningResponseError: Codable {
//    let error: Bool? // Only on errror case
//    let message: String? // Only on errror case
//    enum CodingKeys: String, CodingKey {
//        case error
//        case message
//    }
//}
//
//struct FinancialContributionsResponse: Codable {
//    let topic: String
//    let normalizedTopicName: String
//    let timestamp: String?
//    let committeeId: String
//    let individualId: Int
//    let fecFinancialContributionsSummaryText: String
//    let upvoteCount: Int?
//    let downvoteCount: Int?
//    let timeRangeOfData: String?
//    let cycleEndYear: String?
//    let committeeName: String?
//    let queryType: String?
//    let debug: FinancialDebugInfo?
//    let percentContributions: PercentContributions?
//    var contributionTotals: [ContributionTotal]?
//    var leadershipContributionsToCommittee: [LeadershipContribution]?
//    
//    enum CodingKeys: String, CodingKey {
//        case topic
//        case normalizedTopicName = "normalized_topic_name"
//        case timestamp
//        case committeeId = "committee_id"
//        case individualId = "individual_id"
//        case fecFinancialContributionsSummaryText = "fec_financial_contributions_summary_text"
//        case upvoteCount = "upvote_count"
//        case downvoteCount = "downvote_count"
//        case timeRangeOfData = "time_range_of_data"
//        case cycleEndYear = "cycle_end_year"
//        case committeeName = "committee_name"
//        case queryType = "query_type"
//        case debug
//        case percentContributions = "percent_contributions"
//        case contributionTotals = "contribution_totals"
//        case leadershipContributionsToCommittee = "leadership_contributors_to_committee"
//            
//    }
//}
//
//struct FinancialDebugInfo: Codable {
//    let modelUsed: String
//    let automatedEntry: Bool
//    let dateGenerated: String
//    let truncatedData: Bool
//    let percentOfDataWithinTimeRange: Int
//    let persistedResponse: Bool
//    let newlyGenerated: Bool
//    
//    enum CodingKeys: String, CodingKey {
//        case modelUsed = "model_used"
//        case automatedEntry = "automated_entry"
//        case dateGenerated = "date_generated"
//        case truncatedData = "truncated_data"
//        case percentOfDataWithinTimeRange = "precent_of_data_within_time_range"
//        case persistedResponse = "persisted_response"
//        case newlyGenerated = "newly_generated"
//    }
//}
//
//struct PercentContributions: Codable {
//    let totalToDemocrats: Int
//    let totalToRepublicans: Int
//    let percentToDemocrats: Float
//    let percentToRepublicans: Float
//    let totalContributions: Int
//    
//    enum CodingKeys: String, CodingKey {
//        case totalToDemocrats = "total_to_democrats"
//        case totalToRepublicans = "total_to_republicans"
//        case percentToDemocrats = "percent_to_democrats"
//        case percentToRepublicans = "percent_to_republicans"
//        case totalContributions = "total_contributions"
//    }
//}
//
//struct ContributionTotal: Codable {
//    let recipientID: String?
//    let recipientName: String?
//    let numberOfContributions: Int?
//    let totalContributionAmount: Int?
//    
//    enum CodingKeys: String, CodingKey {
//        case recipientID = "recipient_id"
//        case recipientName = "recipient_name"
//        case numberOfContributions = "number_of_contributions"
//        case totalContributionAmount = "total_contribution_amount"
//    }
//}
//
//struct LeadershipContribution: Codable {
//    let occupation: String
//    let name: String
//    let employer: String
//    let transactionAmount: String
//    
//    enum CodingKeys: String, CodingKey {
//        case occupation
//        case name
//        case employer
//        case transactionAmount = "transaction_amount"
//    }
//}
