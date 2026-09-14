import Foundation

enum CompassDeepLink {
    case quizResult(token: String)
    case answer(topic: String, category: CurrentSearchCategory)
    
    private static let appScheme = "corporatecompass"
    private static let universalLinkHost = "compass-ai.ai"
    private static let universalLinkPrefix = "/app"
    
    static func quizResultURL(token: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = universalLinkHost
        components.path = "\(universalLinkPrefix)/quiz/result"
        components.queryItems = [URLQueryItem(name: "a", value: token)]
        return components.url
    }
    
    static func answerURL(topic: String, category: CurrentSearchCategory) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = universalLinkHost
        components.path = "\(universalLinkPrefix)/answer"
        components.queryItems = [
            URLQueryItem(name: "topic", value: topic),
            URLQueryItem(name: "category", value: category.rawValue)
        ]
        return components.url
    }
    
    static func parse(_ url: URL) -> CompassDeepLink? {
        if url.scheme == appScheme {
            return parseCustomSchemeURL(url)
        }
        
        guard url.scheme == "https", url.host == universalLinkHost else {
            return nil
        }
        
        let path = normalizedPath(from: url.path)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return parse(path: path, queryItems: components?.queryItems ?? [])
    }
    
    private static func parseCustomSchemeURL(_ url: URL) -> CompassDeepLink? {
        let host = url.host ?? ""
        let path = "/\(host)\(url.path)"
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return parse(path: path, queryItems: components?.queryItems ?? [])
    }
    
    private static func parse(path: String, queryItems: [URLQueryItem]) -> CompassDeepLink? {
        switch path {
        case "/quiz/result":
            guard let token = value(named: "a", in: queryItems), !token.isEmpty else { return nil }
            return .quizResult(token: token)
        case "/answer":
            guard
                let topic = value(named: "topic", in: queryItems),
                !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let categoryValue = value(named: "category", in: queryItems),
                let category = CurrentSearchCategory(rawValue: categoryValue)
            else {
                return nil
            }
            return .answer(topic: topic, category: category)
        default:
            return nil
        }
    }
    
    private static func normalizedPath(from path: String) -> String {
        if path.hasPrefix(universalLinkPrefix + "/") {
            return String(path.dropFirst(universalLinkPrefix.count))
        }
        return path
    }
    
    private static func value(named name: String, in queryItems: [URLQueryItem]) -> String? {
        return queryItems.first(where: { $0.name == name })?.value
    }
}
