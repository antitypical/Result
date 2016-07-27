//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map { $0.characters.count } ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map { $0.characters.count } ?? 0, 0)
	}

	func testInitOptionalSuccess() {
		XCTAssert(Result("success" as String?, failWith: error) == success)
	}

	func testInitOptionalFailure() {
		XCTAssert(Result(nil, failWith: error) == failure)
	}


	// MARK: Errors

	func testErrorsIncludeTheSourceFile() {
		let file = #file
		XCTAssert(Result<(), NSError>.error().file == file)
	}

	func testErrorsIncludeTheSourceLine() {
		let (line, error) = (#line, Result<(), NSError>.error())
		XCTAssertEqual(error.line ?? -1, line)
	}

	func testErrorsIncludeTheCallingFunction() {
		let function = #function
		XCTAssert(Result<(), NSError>.error().function == function)
	}

	// MARK: Try - Catch
	
	func testTryCatchProducesSuccesses() {
		let result: Result<String, NSError> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		#if os(Linux)
			/// FIXME: skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.
			print("Test Case `\(#function)` skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.")
		#else
			let result: Result<String, NSError> = Result(try tryIsSuccess(nil))
			XCTAssert(result.error == error)
		#endif
	}

	func testTryCatchWithFunctionProducesSuccesses() {
		let function = { try tryIsSuccess("success") }

		let result: Result<String, NSError> = Result(attempt: function)
		XCTAssert(result == success)
	}

	func testTryCatchWithFunctionCatchProducesFailures() {
		#if os(Linux)
			/// FIXME: skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.
			print("Test Case `\(#function)` skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.")
		#else
			let function = { try tryIsSuccess(nil) }

			let result: Result<String, NSError> = Result(attempt: function)
			XCTAssert(result.error == error)
		#endif
	}

	func testMaterializeProducesSuccesses() {
		let result1 = materialize(try tryIsSuccess("success"))
		XCTAssert(result1 == success)

		let result2: Result<String, NSError> = materialize { try tryIsSuccess("success") }
		XCTAssert(result2 == success)
	}

	func testMaterializeProducesFailures() {
		#if os(Linux)
			/// FIXME: skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.
			print("Test Case `\(#function)` skipped on Linux because of crash with swift-DEVELOPMENT-SNAPSHOT-2016-07-25-a.")
		#else
			let result1 = materialize(try tryIsSuccess(nil))
			XCTAssert(result1.error == error)

			let result2: Result<String, NSError> = materialize { try tryIsSuccess(nil) }
			XCTAssert(result2.error == error)
		#endif
	}

	// MARK: Recover

	func testRecoverProducesLeftForLeftSuccess() {
		let left = Result<String, NSError>.success("left")
		XCTAssertEqual(left.recover("right"), "left")
	}

	func testRecoverProducesRightForLeftFailure() {
		struct MyError: Error {}

		let left = Result<String, MyError>.failure(MyError())
		XCTAssertEqual(left.recover("right"), "right")
	}

	// MARK: Recover With

	func testRecoverWithProducesLeftForLeftSuccess() {
		let left = Result<String, NSError>.success("left")
		let right = Result<String, NSError>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "left")
	}

	func testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess() {
		struct MyError: Error {}

		let left = Result<String, MyError>.failure(MyError())
		let right = Result<String, MyError>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "right")
	}

	func testRecoverWithProducesRightFailureForLeftFailureAndRightFailure() {
		enum MyError: Error { case left, right }

		let left = Result<String, MyError>.failure(.left)
		let right = Result<String, MyError>.failure(.right)

		XCTAssertEqual(left.recover(with: right).error, .right)
	}

	// MARK: Cocoa API idioms

	#if !os(Linux)

	func testTryProducesFailuresForBooleanAPIWithErrorReturnedByReference() {
		let result = `try` { attempt(true, succeed: false, error: $0) }
		XCTAssertFalse(result ?? false)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesFailuresForOptionalWithErrorReturnedByReference() {
		let result = `try` { attempt(1, succeed: false, error: $0) }
		XCTAssertEqual(result ?? 0, 0)
		XCTAssertNotNil(result.error)
	}

	func testTryProducesSuccessesForBooleanAPI() {
		let result = `try` { attempt(true, succeed: true, error: $0) }
		XCTAssertTrue(result ?? false)
		XCTAssertNil(result.error)
	}

	func testTryProducesSuccessesForOptionalAPI() {
		let result = `try` { attempt(1, succeed: true, error: $0) }
		XCTAssertEqual(result ?? 0, 1)
		XCTAssertNil(result.error)
	}

	func testTryMapProducesSuccess() {
		let result = success.tryMap(tryIsSuccess)
		XCTAssert(result == success)
	}

	func testTryMapProducesFailure() {
		let result = Result<String, NSError>.success("fail").tryMap(tryIsSuccess)
		XCTAssert(result == failure)
	}

	#endif

	// MARK: Operators

	func testConjunctionOperator() {
		let resultSuccess = success &&& success
		if let (x, y) = resultSuccess.value {
			XCTAssertTrue(x == "success" && y == "success")
		} else {
			XCTFail()
		}

		let resultFailureBoth = failure &&& failure2
		XCTAssert(resultFailureBoth.error == error)

		let resultFailureLeft = failure &&& success
		XCTAssert(resultFailureLeft.error == error)

		let resultFailureRight = success &&& failure2
		XCTAssert(resultFailureRight.error == error2)
	}
}


// MARK: - Fixtures

let success = Result<String, NSError>.success("success")
let error = NSError(domain: "com.antitypical.Result", code: 1, userInfo: nil)
let error2 = NSError(domain: "com.antitypical.Result", code: 2, userInfo: nil)
let failure = Result<String, NSError>.failure(error)
let failure2 = Result<String, NSError>.failure(error2)


// MARK: - Helpers

#if !os(Linux)

func attempt<T>(_ value: T, succeed: Bool, error: NSErrorPointer) -> T? {
	if succeed {
		return value
	} else {
		error?.pointee = Result<(), NSError>.error()
		return nil
	}
}

#endif

func tryIsSuccess(_ text: String?) throws -> String {
	guard let text = text, text == "success" else {
		throw error
	}

	return text
}

extension NSError {
	var function: String? {
		return userInfo[Result<(), NSError>.functionKey] as? String
	}
	
	var file: String? {
		return userInfo[Result<(), NSError>.fileKey] as? String
	}

	var line: Int? {
		return userInfo[Result<(), NSError>.lineKey] as? Int
	}
}

#if os(Linux)

extension ResultTests {
	static var allTests: [(String, (ResultTests) -> () throws -> Void)] {
		return [
			("testMapTransformsSuccesses", testMapTransformsSuccesses),
			("testMapRewrapsFailures", testMapRewrapsFailures),
			("testInitOptionalSuccess", testInitOptionalSuccess),
			("testInitOptionalFailure", testInitOptionalFailure),
			("testErrorsIncludeTheSourceFile", testErrorsIncludeTheSourceFile),
			("testErrorsIncludeTheSourceLine", testErrorsIncludeTheSourceLine),
			("testErrorsIncludeTheCallingFunction", testErrorsIncludeTheCallingFunction),
			("testTryCatchProducesSuccesses", testTryCatchProducesSuccesses),
			("testTryCatchProducesFailures", testTryCatchProducesFailures),
			("testTryCatchWithFunctionProducesSuccesses", testTryCatchWithFunctionProducesSuccesses),
			("testTryCatchWithFunctionCatchProducesFailures", testTryCatchWithFunctionCatchProducesFailures),
			("testMaterializeProducesSuccesses", testMaterializeProducesSuccesses),
			("testMaterializeProducesFailures", testMaterializeProducesFailures),
			("testRecoverProducesLeftForLeftSuccess", testRecoverProducesLeftForLeftSuccess),
			("testRecoverProducesRightForLeftFailure", testRecoverProducesRightForLeftFailure),
			("testRecoverWithProducesLeftForLeftSuccess", testRecoverWithProducesLeftForLeftSuccess),
			("testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess", testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess),
			("testRecoverWithProducesRightFailureForLeftFailureAndRightFailure", testRecoverWithProducesRightFailureForLeftFailureAndRightFailure),
//			("testTryProducesFailuresForBooleanAPIWithErrorReturnedByReference", testTryProducesFailuresForBooleanAPIWithErrorReturnedByReference),
//			("testTryProducesFailuresForOptionalWithErrorReturnedByReference", testTryProducesFailuresForOptionalWithErrorReturnedByReference),
//			("testTryProducesSuccessesForBooleanAPI", testTryProducesSuccessesForBooleanAPI),
//			("testTryProducesSuccessesForOptionalAPI", testTryProducesSuccessesForOptionalAPI),
//			("testTryMapProducesSuccess", testTryMapProducesSuccess),
//			("testTryMapProducesFailure", testTryMapProducesFailure),
			("testConjunctionOperator", testConjunctionOperator),
		]
	}
}
#endif

import Foundation
import Result
import XCTest
