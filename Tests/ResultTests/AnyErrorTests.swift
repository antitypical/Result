import Foundation
import XCTest
import Result

final class AnyErrorTests: XCTestCase {
	static var allTests: [(String, (AnyErrorTests) -> () throws -> Void)] {
		return [
			("testAnyError", testAnyError),
			("testWrapperError", testWrapperError),
		]
	}

	func testAnyError() {
		let error = Error.a
		let anyErrorFromError = AnyError(error)
		let anyErrorFromAnyError = AnyError(anyErrorFromError)
		XCTAssertTrue(anyErrorFromError == anyErrorFromAnyError)
	}
	func testWrapperError() {
		let error = Error.a
		let wrapperErrorFromError = WrapperError(error)
		let wrapperErrorFromWrapperError = WrapperError(wrapperErrorFromError)
		XCTAssertTrue(wrapperErrorFromError == wrapperErrorFromWrapperError)
	}
}
