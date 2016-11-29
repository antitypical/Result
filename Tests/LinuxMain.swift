import XCTest

@testable import ResultTests

XCTMain([
  testCase(ResultTests.allTests),
  testCase(NoErrorTests.allTests),
])
