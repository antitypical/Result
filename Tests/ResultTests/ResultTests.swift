//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {
	func testMapTransformsSuccesses() {
		XCTAssertEqual(success.map { $0.count } ?? 0, 7)
	}

	func testMapRewrapsFailures() {
		XCTAssertEqual(failure.map { $0.count } ?? 0, 0)
	}

	func testInitOptionalSuccess() {
		XCTAssert(Result("success" as String?, failWith: error) == success)
	}

	func testInitOptionalFailure() {
		XCTAssert(Result(nil, failWith: error) == failure)
	}

	func testFanout() {
		let resultSuccess = success.fanout(success)
		if let (x, y) = resultSuccess.value {
			XCTAssertTrue(x == "success" && y == "success")
		} else {
			XCTFail()
		}

		let resultFailureBoth = failure.fanout(failure2)
		XCTAssert(resultFailureBoth.error == error)

		let resultFailureLeft = failure.fanout(success)
		XCTAssert(resultFailureLeft.error == error)

		let resultFailureRight = success.fanout(failure2)
		XCTAssert(resultFailureRight.error == error2)
	}

	func testBimapTransformsSuccesses() {
		XCTAssertEqual(success.bimap(
			success: { $0.count },
			failure: { $0 }
		) ?? 0, 7)
	}

	func testBimapTransformsFailures() {
		XCTAssert(failure.bimap(
			success: { $0 },
			failure: { _ in error2 }
		) == failure2)
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

	func testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError() {
		XCTAssertEqual(error.errorDescription, "localized description")
		XCTAssertEqual(error.localizedDescription, "localized description")
		XCTAssertEqual(error3.errorDescription, "localized description")
		XCTAssertEqual(error3.localizedDescription, "localized description")
	}

	func testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError() {
		XCTAssertEqual(error.failureReason, "failure reason")
	}

	func testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError() {
		XCTAssertEqual(error.recoverySuggestion, "recovery suggestion")
	}

	func testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError() {
		XCTAssertEqual(error.helpAnchor, "help anchor")
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

	func testTryCatchWithFunctionThrowingNonAnyErrorCanProducesAnyErrorFailures() {
		let nsError = NSError(domain: "", code: 0)
		let function: () throws -> String = { throw nsError }

		let result: Result<String, AnyError> = Result(attempt: function)
		XCTAssert(result.error == AnyError(nsError))
		
		let wrapperResult: Result<String, WrapperError> = Result(attempt: function)
		XCTAssert(wrapperResult.error == WrapperError(nsError))
	}

	func testMaterializeProducesSuccesses() {
		let result1: Result<String, AnyError> = Result(try tryIsSuccess("success"))
		XCTAssert(result1 == success)

		let result2: Result<String, AnyError> = Result(attempt: { try tryIsSuccess("success") })
		XCTAssert(result2 == success)
		
	}

	func testMaterializeProducesFailures() {
		let result1: Result<String, AnyError> = Result(try tryIsSuccess(nil))
		XCTAssert(result1.error == error)

		let result2: Result<String, AnyError> = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert(result2.error == error)
	}

	func testMaterializeProducesSuccessesForErrorInitializing() {
		let result1: Result<String, WrapperError> = Result(try tryIsSuccess("success"))
		XCTAssert(result1 == wrapperSuccess)

		let result2: Result<String, WrapperError> = Result(attempt: { try tryIsSuccess("success") })
		XCTAssert(result2 == wrapperSuccess)
	}

	func testMaterializeProducesFailuresForErrorInitializing() {
		let result1: Result<String, WrapperError> = Result(try tryIsSuccess(nil))
		XCTAssert(result1.error == wrapperError)

		let result2: Result<String, WrapperError> = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert(result2.error == wrapperError)
		
	}

	func testMaterializeInferrence() {
		let result = Result(attempt: { try tryIsSuccess(nil) })
		XCTAssert((type(of: result) as Any.Type) is Result<String, AnyError>.Type)
		
		let result2 = Result(1)
		XCTAssert((type(of: result2) as Any.Type) is Result<Int, NoError>.Type)
		
	}
	
	func testParsingSuccess() {
		let result = Result(attempt: { try tryParseJSON(jsonRaw) })
		XCTAssert((type(of: result) as Any.Type) is Result<Any, AnyError>.Type)
		XCTAssert(result.value != nil)
	}
	func testParsingFailure() {
		let result = Result(attempt: { try tryParseJSON(jsonRawMalformed) })
		XCTAssert((type(of: result) as Any.Type) is Result<Any, AnyError>.Type)
		XCTAssert(result.error != nil)
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

	func testTryMapProducesSuccess() {
		let result = success.tryMap(tryIsSuccess)
		XCTAssert(result == success)
	}

	func testTryMapProducesFailure() {
		let result = Result<String, AnyError>.success("fail").tryMap(tryIsSuccess)
		XCTAssert(result == failure)
	}
}


// MARK: - Fixtures

enum Error: Swift.Error, LocalizedError {
	case a, b

	var errorDescription: String? {
		return "localized description"
	}

	var failureReason: String? {
		return "failure reason"
	}

	var helpAnchor: String? {
		return "help anchor"
	}

	var recoverySuggestion: String? {
		return "recovery suggestion"
	}
}

enum WrapperError: Swift.Error, LocalizedError, ErrorInitializing, ErrorConvertible {
	case c, d, other(Swift.Error)
	
	init(_ error: Swift.Error) {
		self = (error as? WrapperError) ?? .other(error)
	}
	
	var error: Swift.Error {
		switch self {
			case .other(let error): return error
			default: return self
		}
	}

	var errorDescription: String? {
		return "localized description"
	}

	var failureReason: String? {
		return "failure reason"
	}

	var helpAnchor: String? {
		return "help anchor"
	}

	var recoverySuggestion: String? {
		return "recovery suggestion"
	}
}

let success = Result<String, AnyError>.success("success")
let error = AnyError(Error.a)
let error2 = AnyError(Error.b)
let error3 = AnyError(NSError(domain: "Result", code: 42, userInfo: [NSLocalizedDescriptionKey: "localized description"]))
let failure = Result<String, AnyError>.failure(error)
let failure2 = Result<String, AnyError>.failure(error2)

let wrapperSuccess = Result<String, WrapperError>.success("success")
let wrapperError = WrapperError(Error.a)
let wrapperError2 = WrapperError(Error.b)
let wrapperError3 = WrapperError(NSError(domain: "Result", code: 42, userInfo: [NSLocalizedDescriptionKey: "localized description"]))
let wrapperFailure = Result<String, WrapperError>.failure(wrapperError)
let wrapperFailure2 = Result<String, WrapperError>.failure(wrapperError2)

// MARK: - Helpers

extension AnyError: Equatable {
	public static func ==(lhs: AnyError, rhs: AnyError) -> Bool {
		return lhs.error._code == rhs.error._code
			&& lhs.error._domain == rhs.error._domain
	}
}

extension WrapperError: Equatable {
	public static func ==(lhs: WrapperError, rhs: WrapperError) -> Bool {
		switch (lhs, rhs) {
			case (.c, .c), (.d, .d): return true
			case (.other(let lError), .other(let rError)):
				return lError._code == rError._code
					&& lError._domain == rError._domain
			default:
				return false
		}
	}
}

func tryIsSuccess(_ text: String?) throws -> String {
	guard let text = text, text == "success" else {
		throw Error.a
	}

	return text
}

let jsonObject: Any = ["foo": "bar"]
let jsonRaw = "{\"foo\": \"bar\"}"
let jsonRawMalformed = "{\"foo\": \"bar\""
func tryParseJSON(_ jsonString: String) throws -> Any {
	return try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8) ?? Data(), options: [])
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

extension ResultTests {
	static var allTests: [(String, (ResultTests) -> () throws -> Void)] {
		return [
			("testMapTransformsSuccesses", testMapTransformsSuccesses),
			("testMapRewrapsFailures", testMapRewrapsFailures),
			("testInitOptionalSuccess", testInitOptionalSuccess),
			("testInitOptionalFailure", testInitOptionalFailure),
			("testFanout", testFanout),
			("testBimapTransformsSuccesses", testBimapTransformsSuccesses),
			("testBimapTransformsFailures", testBimapTransformsFailures),
			("testErrorsIncludeTheSourceFile", testErrorsIncludeTheSourceFile),
			("testErrorsIncludeTheSourceLine", testErrorsIncludeTheSourceLine),
			("testErrorsIncludeTheCallingFunction", testErrorsIncludeTheCallingFunction),
			("testTryCatchProducesSuccesses", testTryCatchProducesSuccesses),
			("testTryCatchProducesFailures", testTryCatchProducesFailures),
			("testTryCatchWithFunctionProducesSuccesses", testTryCatchWithFunctionProducesSuccesses),
			("testTryCatchWithFunctionCatchProducesFailures", testTryCatchWithFunctionCatchProducesFailures),
			("testMaterializeProducesSuccesses", testMaterializeProducesSuccesses),
			("testMaterializeProducesFailures", testMaterializeProducesFailures),
			("testMaterializeProducesSuccessesForErrorInitializing", testMaterializeProducesSuccessesForErrorInitializing),
			("testMaterializeProducesFailuresForErrorInitializing", testMaterializeProducesFailuresForErrorInitializing),
			("testParsingSuccess", testParsingSuccess),
			("testParsingFailure", testParsingFailure),
			("testRecoverProducesLeftForLeftSuccess", testRecoverProducesLeftForLeftSuccess),
			("testRecoverProducesRightForLeftFailure", testRecoverProducesRightForLeftFailure),
			("testRecoverWithProducesLeftForLeftSuccess", testRecoverWithProducesLeftForLeftSuccess),
			("testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess", testRecoverWithProducesRightSuccessForLeftFailureAndRightSuccess),
			("testRecoverWithProducesRightFailureForLeftFailureAndRightFailure", testRecoverWithProducesRightFailureForLeftFailureAndRightFailure),
			("testTryMapProducesSuccess", testTryMapProducesSuccess),
			("testTryMapProducesFailure", testTryMapProducesFailure),
			("testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError", testAnyErrorDelegatesLocalizedDescriptionToUnderlyingError),
			("testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError", testAnyErrorDelegatesLocalizedFailureReasonToUnderlyingError),
			("testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError", testAnyErrorDelegatesLocalizedRecoverySuggestionToUnderlyingError),
			("testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError", testAnyErrorDelegatesLocalizedHelpAnchorToUnderlyingError),
		]
	}
}

import Foundation
import Result
import XCTest
