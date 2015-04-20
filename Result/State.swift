//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// Implementation details of `Result`.
internal enum State<T, Error> {
	func analysis<Result>(@noescape #ifSuccess: T -> Result, @noescape ifFailure: Error -> Result) -> Result {
		switch self {
		case let .Success(value):
			return ifSuccess(value.value)
		case let .Failure(value):
			return ifFailure(value.value)
		}
	}

	case Success(Box<T>)
	case Failure(Box<Error>)
}

internal final class Box<T> {
	init(_ value: T) {
		self.value = value
	}

	let value: T
}
