//  Copyright (c) 2015 Rob Rix. All rights reserved.

final class ResultTests: XCTestCase {}

let success = Result.success("success")
let failure = Result<String>.failure(NSError(domain: "com.antitypical.Result", code: 0xdeadbeef, userInfo: nil))


// MARK: - Imports

import Result
import XCTest
