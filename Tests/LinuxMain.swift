import XCTest

@testable import ResultTests

XCTMain([
	testCase(AnyErrorTests.allTests),
	testCase(NoErrorTests.allTests),
	testCase(ResultTests.allTests),
])
