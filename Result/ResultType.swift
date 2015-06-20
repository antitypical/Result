//  Copyright (c) 2015 Rob Rix. All rights reserved.

public protocol ResultType {
	typealias Value
	typealias Error: ErrorType
	
	init(value: Value)
	init(error: Error)
	
	func analysis<U>(@noescape ifSuccess ifSuccess: Value -> U, @noescape ifFailure: Error -> U) -> U
}

public extension ResultType {
	
	/// Returns the value from `Success` Results, `nil` otherwise.
	var value: Value? {
		return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
	}
	
	/// Returns the error from `Failure` Results, `nil` otherwise.
	var error: Error? {
		return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
	}
}