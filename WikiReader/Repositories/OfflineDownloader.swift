import Foundation
import Observation

/// Pre-caches every article body so the whole catalog is readable offline,
/// driven by the Settings "Download all articles" toggle. Fetches sequentially
/// with a small inter-request delay to stay polite to Wikimedia (spec §6.4);
/// the underlying HTTPClient already backs off on 429s.
@MainActor
@Observable
final class OfflineDownloader {
    enum State: Equatable {
        case idle
        case downloading
        case completed
        case cancelled
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var total = 0
    private(set) var completed = 0
    /// Articles that couldn't be fetched (e.g. dead/redirected links). Skipped, not fatal.
    private(set) var failures = 0

    private let articles: ArticleRepository
    private var task: Task<Void, Never>?

    /// Pause between requests — gentle on the API, still finishes a few hundred
    /// articles in a reasonable time.
    private let requestSpacing: Duration = .milliseconds(150)

    init(articles: ArticleRepository) {
        self.articles = articles
    }

    var isRunning: Bool { state == .downloading }

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    /// Downloads any not-yet-cached articles. Safe to call repeatedly — it only
    /// fetches what's missing, so it doubles as a "top up" after new entries
    /// arrive from a catalog refresh. No-op while already running.
    func start() {
        guard task == nil else { return }

        let pending = articles.entriesNeedingBody()
        total = pending.count
        completed = 0
        failures = 0

        guard !pending.isEmpty else {
            state = .completed
            return
        }

        state = .downloading
        task = Task { [weak self] in
            guard let self else { return }
            for entry in pending {
                if Task.isCancelled { break }
                do {
                    try await self.articles.ensureBody(for: entry, markViewed: false)
                } catch {
                    self.failures += 1
                }
                self.completed += 1
                try? await Task.sleep(for: self.requestSpacing)
            }
            let wasCancelled = Task.isCancelled
            self.task = nil
            self.state = wasCancelled ? .cancelled : .completed
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if state == .downloading { state = .cancelled }
    }
}
