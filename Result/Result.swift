//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T>: EitherType, Printable, DebugPrintable {
	// MARK: Constructors

	/// Constructs a success wrapping a `value`.
	public init(value: T) {
		self = Success(Box(value))
	}

	/// Constructs a failure wrapping an `error`.
	public init(error: NSError) {
		self = Failure(error)
	}


	/// Constructs a success wrapping a `value`.
	public static func success(value: T) -> Result {
		return Result(value: value)
	}

	/// Constructs a failure wrapping an `error`.
	public static func failure(error: NSError) -> Result {
		return Result(error: error)
	}


	// MARK: Deconstruction

	/// Returns the value from `Success` Results, `nil` otherwise.
	public var value: T? {
		return analysis(
			ifSuccess: unit,
			ifFailure: const(nil))
	}

	/// Returns the error from `Failure` Results, `nil` otherwise.
	public var error: NSError? {
		return analysis(
			ifSuccess: const(nil),
			ifFailure: unit)
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
	public func analysis<Result>(@noescape #ifSuccess: T -> Result, @noescape ifFailure: NSError -> Result) -> Result {
		switch self {
		case let Failure(error):
			return ifFailure(error)

		case let Success(value):
			return ifSuccess(value.value)
		}
	}


	// MARK: Higher-order functions

	/// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
	public func map<U>(@noescape transform: T -> U) -> Result<U> {
		return flatMap { Result<U>.success(transform($0)) }
	}

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
	public func flatMap<U>(@noescape transform: T -> Result<U>) -> Result<U> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U>.failure)
	}


	// MARK: Errors

	/// The domain for errors constructed by Result.
	public static var errorDomain: String { return "com.antitypical.Result" }

	/// The userInfo key for source functions in errors constructed by Result.
	public static var functionKey: String { return "\(errorDomain).function" }

	/// The userInfo key for source file paths in errors constructed by Result.
	public static var fileKey: String { return "\(errorDomain).file" }

	/// The userInfo key for source file line numbers in errors constructed by Result.
	public static var lineKey: String { return "\(errorDomain).line" }

	/// Constructs an error.
	public static func error(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) -> NSError {
		return NSError(domain: "com.antitypical.Result", code: 0, userInfo: [
			functionKey: function,
			fileKey: file,
			lineKey: line,
		])
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
		(left.value &&& right.value).map { $0 == $1 }
	??	(left.error &&& right.error).map(==)
	??	false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: Equatable> (left: Result<T>, right: Result<T>) -> Bool {
	return !(left == right)
}


/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
public func ?? <T> (left: Result<T>, @autoclosure right: () -> T) -> T {
	return left.value ?? right()
}

/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
public func ?? <T> (left: Result<T>, @autoclosure right: () -> Result<T>) -> Result<T> {
	return left.analysis(
		ifSuccess: const(left),
		ifFailure: { _ in right() })
}


// MARK: - Cocoa API conveniences

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     Result.try { NSData(contentsOfURL: URL, options: .DataReadingMapped, error: $0) }
public func try<T>(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, try: NSErrorPointer -> T?) -> Result<T> {
	var error: NSError?
	return try(&error).map(Result.success) ?? Result.failure(error ?? Result<T>.error(function: function, file: file, line: line))
}

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     Result.try { NSFileManager.defaultManager().removeItemAtURL(URL, error: $0) }
public func try(function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__, try: NSErrorPointer -> Bool) -> Result<()> {
	var error: NSError?
	return try(&error) ?
		.success(())
	:	.failure(error ?? Result<()>.error(function: function, file: file, line: line))
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
public func >>- <T, U> (result: Result<T>, @noescape transform: T -> Result<U>) -> Result<U> {
	return result.flatMap(transform)
}


// MARK: - Imports

import Box
import Either
import Prelude
import Foundation
