//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map(count) ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map(count) ?? 0, 0)
	}
}

let success = Result.success("success")
let failure = Result<String>.failure(NSError(domain: "com.antitypical.Result", code: 0xdeadbeef, userInfo: nil))


// MARK: - Imports

import Prelude
import Result
import XCTest
