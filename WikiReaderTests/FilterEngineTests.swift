import XCTest
@testable import WikiReader

/// Lightweight stand-in so filter/sort logic is tested without a SwiftData stack.
private struct TestCase: Filterable {
    var title: String
    var summary: String?
    var metric: Int?
    var countryName: String?
    var startDate: Date?
}

private func date(_ year: Int) -> Date {
    var c = DateComponents(); c.year = year; c.month = 1; c.day = 1
    return Calendar(identifier: .gregorian).date(from: c)!
}

final class FilterEngineTests: XCTestCase {
    private let sample: [TestCase] = [
        TestCase(title: "Bundy", summary: "Florida", metric: 30, countryName: "United States", startDate: date(1989)),
        TestCase(title: "Shipman", summary: nil, metric: 218, countryName: "United Kingdom", startDate: date(2004)),
        TestCase(title: "Cipher case", summary: "unsolved", metric: nil, countryName: nil, startDate: date(1970)),
        TestCase(title: "Chikatilo", summary: nil, metric: 52, countryName: "Russia", startDate: date(1994)),
    ]

    func testVictimThresholdExcludesUnknownCounts() {
        var criteria = FilterCriteria()
        criteria.minMetric = 10
        let result = FilterEngine.apply(sample, criteria)
        XCTAssertEqual(Set(result.map(\.title)), ["Bundy", "Shipman", "Chikatilo"])
        XCTAssertFalse(result.contains { $0.title == "Cipher case" }, "nil victim count must be excluded, never treated as 0")
    }

    func testCountryMultiSelect() {
        var criteria = FilterCriteria()
        criteria.countries = ["United States", "Russia"]
        let result = FilterEngine.apply(sample, criteria)
        XCTAssertEqual(Set(result.map(\.title)), ["Bundy", "Chikatilo"])
    }

    func testSearchMatchesTitleAndSummary() {
        var byTitle = FilterCriteria(); byTitle.searchText = "ship"
        XCTAssertEqual(FilterEngine.apply(sample, byTitle).map(\.title), ["Shipman"])

        var bySummary = FilterCriteria(); bySummary.searchText = "florida"
        XCTAssertEqual(FilterEngine.apply(sample, bySummary).map(\.title), ["Bundy"])
    }

    func testAlphabeticalSort() {
        var criteria = FilterCriteria(); criteria.sort = .alphaAscending
        XCTAssertEqual(FilterEngine.apply(sample, criteria).map(\.title),
                       ["Bundy", "Chikatilo", "Cipher case", "Shipman"])
    }

    func testChronologicalSortNewestFirst() {
        var criteria = FilterCriteria(); criteria.sort = .chronoNewest
        XCTAssertEqual(FilterEngine.apply(sample, criteria).first?.title, "Shipman")
    }

    func testFiltersCompose() {
        var criteria = FilterCriteria()
        criteria.minMetric = 20
        criteria.countries = ["United States"]
        criteria.sort = .alphaAscending
        XCTAssertEqual(FilterEngine.apply(sample, criteria).map(\.title), ["Bundy"])
    }

    func testActiveFilterCountIgnoresSort() {
        var criteria = FilterCriteria()
        criteria.sort = .chronoNewest
        XCTAssertEqual(criteria.activeFilterCount, 0)
        criteria.minMetric = 5
        XCTAssertEqual(criteria.activeFilterCount, 1)
        criteria.countries = ["Russia"]
        XCTAssertEqual(criteria.activeFilterCount, 2)
    }

    func testAvailableCountriesSortedAndDeduped() {
        XCTAssertEqual(FilterEngine.availableCountries(sample),
                       ["Russia", "United Kingdom", "United States"])
    }
}
