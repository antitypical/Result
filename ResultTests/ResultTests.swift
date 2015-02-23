//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map(count) ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map(count) ?? 0, 0)
	}


	// MARK: Cocoa API idioms

	func testTryProducesFailuresForBooleanAPIWithErrorReturnedByReference() {
		let result = try { attempt(true, succeed: false, error: $0) }
		XCTAssertFalse(result ?? false)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesFailuresForOptionalWithErrorReturnedByReference() {
		let result = try { attempt(1, succeed: false, error: $0) }
		XCTAssertEqual(result ?? 0, 0)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesSuccessesForBooleanAPI() {
		let result = try { attempt(true, succeed: true, error: $0) }
		XCTAssertTrue(result ?? false)
		XCTAssertNil(result.error)
	}

	func testTryProducesSuccessesForOptionalAPI() {
		let result = try { attempt(1, succeed: true, error: $0) }
		XCTAssertEqual(result ?? 0, 1)
		XCTAssertNil(result.error)
	}
}

func attempt<T>(value: T, #succeed: Bool, #error: NSErrorPointer) -> T? {
	if succeed {
		return value
	} else {
		error.memory = Result<()>.error()
		return nil
	}
}

let success = Result.success("success")
let failure = Result<String>.failure(NSError(domain: "com.antitypical.Result", code: 0xdeadbeef, userInfo: nil))


// MARK: - Imports

import Prelude
import Result
import XCTest
