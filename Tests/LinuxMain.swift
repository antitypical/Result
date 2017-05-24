import XCTest

@testable import ResultTests

XCTMain([
	testCase(NoErrorTests.allTests),
	testCase(ResultTests.allTests),
])
