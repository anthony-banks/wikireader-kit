import Foundation
import SwiftData

/// Bookmark toggling + cache maintenance. Bookmarks persist in SwiftData and
/// are available offline; clearing the cache never removes them (spec §9.5, §9.6).
@MainActor
final class BookmarkRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func toggle(_ entry: Entry) {
        entry.isBookmarked.toggle()
        try? context.save()
    }
}
