import Foundation
import XCTest
import Result

final class AnyErrorTests: XCTestCase {
	static var allTests: [(String, (AnyErrorTests) -> () throws -> Void)] {
		return [ ("testAnyError", testAnyError), ("testSwiftErrorAnyError", testSwiftErrorAnyError) ]
	}

	func testAnyError() {
		let error = Error.a
		let anyErrorFromError = AnyError(error)
		let anyErrorFromAnyError = AnyError(anyErrorFromError)
		XCTAssertTrue(anyErrorFromError == anyErrorFromAnyError)
	}

	func testSwiftErrorAnyError() {
		let error = Error.a
		let anyErrorFromError = error.anyError
		let anyErrorFromAnyError = anyErrorFromError.anyError
		XCTAssertTrue(anyErrorFromError == anyErrorFromAnyError)
	}
}
