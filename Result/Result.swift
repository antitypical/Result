//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T>: EitherType, Printable, DebugPrintable {
	// MARK: Constructors

	/// Constructs a success from a `value`.
	public static func success(value: T) -> Result {
		return Success(Box(value))
	}

	/// Constructs a failure from an `error`.
	public static func failure(error: NSError) -> Result {
		return Failure(error)
	}


	// MARK: Deconstruction

	/// Returns the value from `Success` Results, `nil` otherwise.
	public var success: T? {
		return analysis(
			ifSuccess: id,
			ifFailure: const(nil))
	}

	/// Returns the error from `Failure` Results, `nil` otherwise.
	public var failure: NSError? {
		return analysis(
			ifSuccess: const(nil),
			ifFailure: id)
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
	public func analysis<Result>(#ifSuccess: T -> Result, ifFailure: NSError -> Result) -> Result {
		switch self {
		case let Failure(error):
			return ifFailure(error)

		case let Success(value):
			return ifSuccess(value.value)
		}
	}


	// MARK: Higher-order functions

	/// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
	public func map<U>(transform: T -> U) -> Result<U> {
		return flatMap(transform >>> Result<U>.success)
	}

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
	public func flatMap<U>(transform: T -> Result<U>) -> Result<U> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U>.failure)
	}


	// MARK: Cases

	case Success(Box<T>)
	case Failure(NSError)


	// MARK: EitherType

	public static func left(error: NSError) -> Result {
		return failure(error)
	}

	public static func right(value: T) -> Result {
		return success(value)
	}

	public func either<Result>(ifLeft: NSError -> Result, _ ifRight: T -> Result) -> Result {
		return analysis(
			ifSuccess: ifRight,
			ifFailure: ifLeft)
	}


	// MARK: Printable

	public var description: String {
		return analysis(
			ifSuccess: { ".Success(\($0))" },
			ifFailure: { ".Failure(\($0))" })
	}


	// MARK: DebugPrintable

	public var debugDescription: String {
		return description
	}
}


/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
public func == <T: Equatable> (left: Result<T>, right: Result<T>) -> Bool {
	return
		(left.success &&& right.success).map { $0 == $1 }
	??	(left.failure &&& right.failure).map(==)
	??	false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: Equatable> (left: Result<T>, right: Result<T>) -> Bool {
	return !(left == right)
}


/// Returns the value of `Success`es, or `right` otherwise. Short-circuits.
public func ?? <T> (left: Result<T>, @autoclosure right: () -> T) -> T {
	return left.success ?? right()
}


// MARK: - Operators

infix operator >>- {
	// Left-associativity so that chaining works like you’d expect, and for consistency with Haskell, Runes, swiftz, etc.
	associativity left

	// Higher precedence than function application, but lower than function composition.
	precedence 150
}


/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
public func >>- <T, U> (result: Result<T>, transform: T -> Result<U>) -> Result<U> {
	return result.flatMap(transform)
}


// MARK: - Imports

import Box
import Either
import Prelude
import Foundation
