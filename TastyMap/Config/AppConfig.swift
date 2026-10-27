import Foundation

enum AppConfig {
    static let defaultAPIBaseURL = URL(
        string: "https://quinn.eastasia.cloudapp.azure.com:8443"
    )!

    static var apiBaseURL: URL {
        guard
            let override = ProcessInfo.processInfo.environment["TASTYMAP_API_BASE_URL"],
            let url = URL(string: override)
        else {
            return defaultAPIBaseURL
        }
        return url
    }
}
