import Foundation

enum HTTPError: LocalizedError {
    case badURL
    case offline
    case rateLimited
    case server(Int)
    case decoding
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "The request address was invalid."
        case .offline: return "You appear to be offline."
        case .rateLimited: return "The source is busy. Try again shortly."
        case .server(let code): return "The source returned an error (\(code))."
        case .decoding: return "The source returned unexpected data."
        case .transport(let message): return message
        }
    }
}

/// Thin URLSession wrapper. Sends the descriptive User-Agent Wikimedia policy
/// requires, decodes JSON, and backs off on HTTP 429 respecting Retry-After
/// (spec §6.4). Sendable so it can be shared across actors.
struct HTTPClient: Sendable {
    /// Identify the app + a contact, per Wikimedia etiquette. Configure the real
    /// contact in `TopicConfig` before shipping.
    static var userAgent: String { TopicConfig.wikimediaUserAgent }

    private let session: URLSession
    private let maxRetries = 3

    init(session: URLSession = .shared) {
        self.session = session
    }

    func getJSON<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        let data = try await getData(url: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPError.decoding
        }
    }

    func getData(url: URL) async throws -> Data {
        var attempt = 0
        while true {
            var request = URLRequest(url: url)
            request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 30

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw HTTPError.transport("No HTTP response.")
                }
                switch http.statusCode {
                case 200...299:
                    return data
                case 429:
                    attempt += 1
                    guard attempt <= maxRetries else { throw HTTPError.rateLimited }
                    let retryAfter = Self.retryAfterSeconds(http) ?? backoffSeconds(attempt)
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                case 500...599:
                    attempt += 1
                    guard attempt <= maxRetries else { throw HTTPError.server(http.statusCode) }
                    try await Task.sleep(nanoseconds: UInt64(backoffSeconds(attempt) * 1_000_000_000))
                default:
                    throw HTTPError.server(http.statusCode)
                }
            } catch let error as HTTPError {
                throw error
            } catch let error as URLError where error.code == .notConnectedToInternet {
                throw HTTPError.offline
            } catch {
                throw HTTPError.transport(error.localizedDescription)
            }
        }
    }

    private func backoffSeconds(_ attempt: Int) -> Double {
        // Exponential: 1s, 2s, 4s ...
        pow(2.0, Double(attempt - 1))
    }

    private static func retryAfterSeconds(_ response: HTTPURLResponse) -> Double? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return Double(value)
    }
}
