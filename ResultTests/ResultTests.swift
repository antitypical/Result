//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		let value = success.map(count).analysis(
			ifSuccess: id,
			ifFailure: const(0))
		XCTAssertEqual(value, 7)
	}

	func testMapRewrapsFailures() {
		let value = failure.map(count).analysis(
			ifSuccess: id,
			ifFailure: const(0))
		XCTAssertEqual(value, 0)
	}
}

let success = Result.success("success")
let failure = Result<String>.failure(NSError(domain: "com.antitypical.Result", code: 0xdeadbeef, userInfo: nil))


// MARK: - Imports

import Prelude
import Result
import XCTest
