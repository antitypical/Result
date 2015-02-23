//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T>: EitherType {
	// MARK: Constructors

	/// Constructs a failure from an `error`.
	public static func failure(error: NSError) -> Result {
		return Failure(error)
	}

	/// Constructs a success from a `value`.
	public static func success(value: T) -> Result {
		return Success(Box(value))
	}


	// MARK: Deconstruction

	/// Returns the error from `Failure` Results, `nil` otherwise.
	public var failure: NSError? {
		return analysis(
			ifFailure: id,
			ifSuccess: const(nil))
	}

	/// Returns the value from `Success` Results, `nil` otherwise.
	public var success: T? {
		return analysis(
			ifFailure: const(nil),
			ifSuccess: id)
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
	public func analysis<Result>(#ifFailure: NSError -> Result, ifSuccess: T -> Result) -> Result {
		switch self {
		case let Failure(error):
			return ifFailure(error)

		case let Success(value):
			return ifSuccess(value.value)
		}
	}


	// MARK: Cases

	case Failure(NSError)
	case Success(Box<T>)


	// MARK: EitherType

	public static func left(error: NSError) -> Result {
		return failure(error)
	}

	public static func right(value: T) -> Result {
		return success(value)
	}

	public func either<Result>(ifLeft: NSError -> Result, _ ifRight: T -> Result) -> Result {
		return analysis(
			ifFailure: ifLeft,
			ifSuccess: ifRight)
	}
}


// MARK: - Imports

import Box
import Either
import Prelude
import Foundation
