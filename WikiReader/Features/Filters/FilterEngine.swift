import Foundation

/// Minimal surface the filter engine needs. `Entry` conforms for free;
/// tests conform a lightweight struct so filter logic is testable without
/// standing up a SwiftData stack (spec §4 — repositories/filters unit-tested).
protocol Filterable {
    var title: String { get }
    var summary: String? { get }
    var metric: Int? { get }
    var countryName: String? { get }
    var startDate: Date? { get }
}

extension Entry: Filterable {}

enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case alphaAscending
    case alphaDescending
    case chronoNewest
    case chronoOldest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .alphaAscending: return "A → Z"
        case .alphaDescending: return "Z → A"
        case .chronoNewest: return "Newest first"
        case .chronoOldest: return "Oldest first"
        }
    }
}

/// All active filter + sort + search state. Value type so it's easy to diff,
/// reset, and unit-test.
struct FilterCriteria: Equatable, Sendable {
    var minMetric: Int? = nil
    var countries: Set<String> = []
    var sort: SortOption = .alphaAscending
    var searchText: String = ""

    static let none = FilterCriteria()

    /// Count of *filters* applied (sort is not a filter), for the toolbar badge.
    var activeFilterCount: Int {
        var count = 0
        if minMetric != nil { count += 1 }
        if !countries.isEmpty { count += 1 }
        return count
    }

    var isActive: Bool { activeFilterCount > 0 || sort != .alphaAscending }
}

enum FilterEngine {
    /// Applies search → filters → sort. Entries with an unknown metric are
    /// *excluded* from a metric filter, never coerced to 0.
    static func apply<T: Filterable>(_ items: [T], _ criteria: FilterCriteria) -> [T] {
        var result = items

        let query = criteria.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.title.lowercased().contains(query)
                    || (item.summary?.lowercased().contains(query) ?? false)
            }
        }

        if let threshold = criteria.minMetric {
            result = result.filter { ($0.metric ?? Int.min) >= threshold }
        }

        if !criteria.countries.isEmpty {
            result = result.filter { item in
                guard let country = item.countryName else { return false }
                return criteria.countries.contains(country)
            }
        }

        return sort(result, by: criteria.sort)
    }

    static func sort<T: Filterable>(_ items: [T], by option: SortOption) -> [T] {
        switch option {
        case .alphaAscending:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .alphaDescending:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .chronoNewest:
            return items.sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }
        case .chronoOldest:
            return items.sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
        }
    }

    /// Distinct country names present in a set of items, sorted for display.
    static func availableCountries<T: Filterable>(_ items: [T]) -> [String] {
        Set(items.compactMap(\.countryName)).sorted()
    }
}
