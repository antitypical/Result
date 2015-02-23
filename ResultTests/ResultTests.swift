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
		XCTAssertNotNil(result.failure)
	}

	func testTryProducesFailuresForObjectAPIWithErrorReturnedByReference() {
		let result = try { attempt(1, succeed: false, error: $0) }
		XCTAssertEqual(result ?? 0, 0)
		XCTAssertNotNil(result.failure)
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
