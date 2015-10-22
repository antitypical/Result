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
		let file = __FILE__
		XCTAssert(Result<(), NSError>.error().file == file)
	}

	func testErrorsIncludeTheSourceLine() {
		let (line, error) = (__LINE__, Result<(), NSError>.error())
		XCTAssertEqual(error.line ?? -1, line)
	}

	func testErrorsIncludeTheCallingFunction() {
		let function = __FUNCTION__
		XCTAssert(Result<(), NSError>.error().function == function)
	}

	// MARK: Try - Catch
	
	func testTryCatchProducesSuccesses() {
		let result: Result<String, NSError> = Result(try tryIsSuccess("success"))
		XCTAssert(result == success)
	}
	
	func testTryCatchProducesFailures() {
		let result: Result<String, NSError> = Result(try tryIsSuccess(nil))
		XCTAssert(result.error == error)
	}

	// MARK: Cocoa API idioms

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
	
	// MARK: Functor, Applicative, Monad
	
	func testFunctor() {
		let result1 = { $0.characters.count } <^> success
		XCTAssertTrue(result1 == .Success(7))
		
		let result2 = { $0.characters.count } <^> failure
		XCTAssertTrue(result2 == .Failure(error))
	}
	
	func testApplicative() {
		let result1 = .Success({ $0.characters.count }) <*> success
		XCTAssertTrue(result1 == .Success(7))
		
		let result2 = .Success({ $0.characters.count }) <*> failure
		XCTAssertTrue(result2 == .Failure(error))
		
		let result3: Result<Int, NSError> = .Failure(error) <*> success
		XCTAssertTrue(result3 == .Failure(error))
		
		let result4: Result<Int, NSError> = .Failure(error) <*> failure
		XCTAssertTrue(result4 == .Failure(error))
	}
	
	func testApplicativeStyle() {
		let f: Int -> Int -> Int = { x in { y in x + y } }
		
		let result1: Result<Int, NSError> = f <^> .Success(1) <*> .Success(2)
		XCTAssertTrue(result1 == .Success(3))
		
		let result2: Result<Int, NSError> = f <^> .Success(1) <*> .Failure(error2)
		XCTAssertTrue(result2 == .Failure(error2))
		
		let result3: Result<Int, NSError> = f <^> .Failure(error) <*> .Success(2)
		XCTAssertTrue(result3 == .Failure(error))
		
		let result4: Result<Int, NSError> = f <^> .Failure(error) <*> .Failure(error2)
		XCTAssertTrue(result4 == .Failure(error))
	}
	
	func testMonad() {
		let result1 = success >>- { .Success($0.characters.count) }
		XCTAssertTrue(result1 == .Success(7))
		
		let result2 = success >>- { _ in Result<Int, NSError>.Failure(error) }
		XCTAssertTrue(result2 == .Failure(error))
		
		let result3 = failure >>- { .Success($0.characters.count) }
		XCTAssertTrue(result3 == .Failure(error))
		
		let result4 = failure >>- { _ in Result<Int, NSError>.Failure(error) }
		XCTAssertTrue(result4 == .Failure(error))
	}

}


// MARK: - Fixtures

let success = Result<String, NSError>.Success("success")
let error = NSError(domain: "com.antitypical.Result", code: 1, userInfo: nil)
let error2 = NSError(domain: "com.antitypical.Result", code: 2, userInfo: nil)
let failure = Result<String, NSError>.Failure(error)
let failure2 = Result<String, NSError>.Failure(error2)


// MARK: - Helpers

func attempt<T>(value: T, succeed: Bool, error: NSErrorPointer) -> T? {
	if succeed {
		return value
	} else {
		error.memory = Result<(), NSError>.error()
		return nil
	}
}

func tryIsSuccess(text: String?) throws -> String {
	guard let text = text else {
		throw error
	}
	
	return text
}

extension NSError {
	var function: String? {
		return userInfo[Result<(), NSError>.functionKey as NSString] as? String
	}
	
	var file: String? {
		return userInfo[Result<(), NSError>.fileKey as NSString] as? String
	}

	var line: Int? {
		return userInfo[Result<(), NSError>.lineKey as NSString] as? Int
	}
}


import Result
import XCTest
