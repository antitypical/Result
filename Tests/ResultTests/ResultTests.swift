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
		let result: Result<String, AnyError> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		let result: Result<String, AnyError> = Result(try tryIsSuccess(nil))
		XCTAssert(result.error == error)
	}

	func testTryCatchWithFunctionProducesSuccesses() {
		let function = { try tryIsSuccess("success") }

		let result: Result<String, AnyError> = Result(attempt: function)
		XCTAssert(result == success)
	}

	func testTryCatchWithFunctionCatchProducesFailures() {
		let function = { try tryIsSuccess(nil) }

		let result: Result<String, AnyError> = Result(attempt: function)
		XCTAssert(result.error == error)
	}

	func testMaterializeProducesSuccesses() {
		let result1: Result<String, AnyError> = materialize(try tryIsSuccess("success"))
		XCTAssert(result1 == success)

		let result2: Result<String, AnyError> = materialize { try tryIsSuccess("success") }
		XCTAssert(result2 == success)
	}

	func testMaterializeProducesFailures() {
		let result1: Result<String, AnyError> = materialize(try tryIsSuccess(nil))
		XCTAssert(result1.error == error)

		let result2: Result<String, AnyError> = materialize { try tryIsSuccess(nil) }
		XCTAssert(result2.error == error)
	}

	// MARK: Recover

	func testRecoverProducesLeftForLeftSuccess() {
		let left = Result<String, Error>.success("left")
		XCTAssertEqual(left.recover("right"), "left")
	}

	func testRecoverProducesRightForLeftFailure() {
		let left = Result<String, Error>.failure(Error.a)
		XCTAssertEqual(left.recover("right"), "right")
	}

	// MARK: Recover With

	func testRecoverWithProducesLeftForLeftSuccess() {
		let left = Result<String, NSError>.success("left")
		let right = Result<String, NSError>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "left")
	}

	func testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess() {
		struct Error: Swift.Error {}

		let left = Result<String, Error>.failure(Error())
		let right = Result<String, Error>.success("right")

		XCTAssertEqual(left.recover(with: right).value, "right")
	}

	func testRecoverWithProducesRightFailureForLeftFailureAndRightFailure() {
		enum Error: Swift.Error { case left, right }

		let left = Result<String, Error>.failure(.left)
		let right = Result<String, Error>.failure(.right)

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

	#endif

	func testTryMapProducesSuccess() {
		let result = success.tryMap(tryIsSuccess)
		XCTAssert(result == success)
	}

	func testTryMapProducesFailure() {
		let result = Result<String, AnyError>.success("fail").tryMap(tryIsSuccess)
		XCTAssert(result == failure)
	}

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


// MARK: - Fixtures

private enum Error: Swift.Error {
	case a, b
}

let success = Result<String, AnyError>.success("success")
let error = AnyError(Error.a)
let error2 = AnyError(Error.b)
let failure = Result<String, AnyError>.failure(error)
let failure2 = Result<String, AnyError>.failure(error2)


// MARK: - Helpers

extension AnyError: Equatable {
	public static func ==(lhs: AnyError, rhs: AnyError) -> Bool {
		return lhs.error._code == rhs.error._code
			&& lhs.error._domain == rhs.error._domain
	}
}

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
			("testTryMapProducesSuccess", testTryMapProducesSuccess),
			("testTryMapProducesFailure", testTryMapProducesFailure),
			("testConjunctionOperator", testConjunctionOperator),
		]
	}
}

#endif

import Foundation
import Result
import XCTest
