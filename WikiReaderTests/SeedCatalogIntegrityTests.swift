import XCTest
@testable import WikiReader

/// Structural sanity checks on the *actual* bundled SeedCatalog.json — the data
/// that ships. Offline and deterministic: it decodes the real file and asserts
/// invariants, but never touches the network (live link-checking lives in
/// Scripts/validate_catalog.py). Loads the seed from the source tree via
/// #filePath so it needs no test-bundle resource wiring.
final class SeedCatalogIntegrityTests: XCTestCase {

    private func loadSeed() throws -> SeedCatalogFile {
        let thisFile = URL(fileURLWithPath: #filePath)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let seedURL = repoRoot
            .appendingPathComponent("WikiReader")
            .appendingPathComponent("Resources")
            .appendingPathComponent("SeedCatalog.json")

        guard FileManager.default.fileExists(atPath: seedURL.path) else {
            throw XCTSkip("SeedCatalog.json not found at \(seedURL.path)")
        }
        let data = try Data(contentsOf: seedURL)
        return try JSONDecoder().decode(SeedCatalogFile.self, from: data)
    }

    func testSeedDecodesAndIsNonEmpty() throws {
        let seed = try loadSeed()
        XCTAssertFalse(seed.entries.isEmpty, "seed catalog should ship with entries")
    }

    func testEntryIDsAreUnique() throws {
        let ids = try loadSeed().entries.map(\.id)
        let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.keys
        XCTAssertTrue(duplicates.isEmpty, "duplicate ids would collide on the unique key: \(Array(duplicates))")
    }

    func testEveryEntryHasRequiredFields() throws {
        for entry in try loadSeed().entries {
            XCTAssertFalse(entry.id.trimmingCharacters(in: .whitespaces).isEmpty, "empty id")
            XCTAssertFalse(entry.title.trimmingCharacters(in: .whitespaces).isEmpty, "empty title for \(entry.id)")
            XCTAssertTrue(entry.articleURL.hasPrefix("https://"), "non-https article URL for \(entry.id): \(entry.articleURL)")
            XCTAssertNotNil(URL(string: entry.articleURL), "unparseable article URL for \(entry.id)")
        }
    }

    func testVictimCountsAreNeverZeroOrNegative() throws {
        for entry in try loadSeed().entries {
            if let count = entry.metric {
                XCTAssertGreaterThan(count, 0, "\(entry.id) has a non-positive victim count; should be nil when unknown")
            }
        }
    }

    func testStartDatesParseWhenPresent() throws {
        for entry in try loadSeed().entries where (entry.startDate?.isEmpty == false) {
            XCTAssertNotNil(SeedEntry.parseDate(entry.startDate),
                            "\(entry.id) has an unparseable startDate: \(entry.startDate ?? "")")
        }
    }

    func testCountryCodesLookValidWhenPresent() throws {
        for entry in try loadSeed().entries {
            if let code = entry.countryCode {
                XCTAssertEqual(code.count, 2, "\(entry.id) country code should be a 2-letter ISO code: \(code)")
                XCTAssertEqual(code, code.uppercased(), "\(entry.id) country code should be uppercase: \(code)")
            }
        }
    }
}
