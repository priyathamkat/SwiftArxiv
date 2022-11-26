import XCTest
@testable import SwiftArxiv

final class SwiftArxivTests: XCTestCase {
    @available(macOS 13.0, *)
    func testGetTaxonomy() async throws {
        let taxonomy = await ArxivAPI.getTaxonomy()
        XCTAssertNotNil(taxonomy)
    }
}
