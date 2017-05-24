import Foundation
import XCTest
import Result

final class NoErrorTests: XCTestCase {
	static var allTests: [(String, (NoErrorTests) -> () throws -> Void)] {
		return [ ("testEquatable", testEquatable) ]
	}

	func testEquatable() {
		let foo = Result<Int, NoError>(1)
		let bar = Result<Int, NoError>(1)
		XCTAssertTrue(foo == bar)
	}
}
