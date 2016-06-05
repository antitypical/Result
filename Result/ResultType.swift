//  Copyright (c) 2015 Rob Rix. All rights reserved.

#if swift(>=3.0)
	public typealias ResultErrorType = ErrorProtocol
#else
	public typealias ResultErrorType = ErrorType
#endif

/// A type that can represent either failure with an error or success with a result value.
public protocol ResultType {
	associatedtype Value
	associatedtype Error: ResultErrorType
	
	/// Constructs a successful result wrapping a `value`.
	init(value: Value)

	/// Constructs a failed result wrapping an `error`.
	init(error: Error)
	
	/// Case analysis for ResultType.
	///
	/// Returns the value produced by appliying `ifFailure` to the error if self represents a failure, or `ifSuccess` to the result value if self represents a success.
#if swift(>=3)
	func analysis<U>(ifSuccess: @noescape (Value) -> U, ifFailure: @noescape (Error) -> U) -> U
#else
	func analysis<U>(@noescape ifSuccess ifSuccess: Value -> U, @noescape ifFailure: Error -> U) -> U
#endif

	/// Returns the value if self represents a success, `nil` otherwise.
	///
	/// A default implementation is provided by a protocol extension. Conforming types may specialize it.
	var value: Value? { get }

	/// Returns the error if self represents a failure, `nil` otherwise.
	///
	/// A default implementation is provided by a protocol extension. Conforming types may specialize it.
	var error: Error? { get }
}

public extension ResultType {
	
	/// Returns the value if self represents a success, `nil` otherwise.
	public var value: Value? {
		return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
	}
	
	/// Returns the error if self represents a failure, `nil` otherwise.
	public var error: Error? {
		return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
	}

	/// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
#if swift(>=3)
	@warn_unused_result
	public func map<U>(_ transform: @noescape (Value) -> U) -> Result<U, Error> {
		return flatMap { .Success(transform($0)) }
	}
#else
	@warn_unused_result
	public func map<U>(@noescape transform: Value -> U) -> Result<U, Error> {
		return flatMap { .Success(transform($0)) }
	}
#endif

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
#if swift(>=3)
	@warn_unused_result
	public func flatMap<U>(_ transform: @noescape (Value) -> Result<U, Error>) -> Result<U, Error> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U, Error>.Failure)
	}
#else
	@warn_unused_result
	public func flatMap<U>(@noescape transform: Value -> Result<U, Error>) -> Result<U, Error> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U, Error>.Failure)
	}
#endif
	
	/// Returns a new Result by mapping `Failure`'s values using `transform`, or re-wrapping `Success`es’ values.
#if swift(>=3)
	@warn_unused_result
	public func mapError<Error2>(_ transform: @noescape (Error) -> Error2) -> Result<Value, Error2> {
		return flatMapError { .Failure(transform($0)) }
	}
#else
	@warn_unused_result
	public func mapError<Error2>(@noescape transform: Error -> Error2) -> Result<Value, Error2> {
		return flatMapError { .Failure(transform($0)) }
	}
#endif

	/// Returns the result of applying `transform` to `Failure`’s errors, or re-wrapping `Success`es’ values.
#if swift(>=3)
	@warn_unused_result
	public func flatMapError<Error2>(_ transform: @noescape (Error) -> Result<Value, Error2>) -> Result<Value, Error2> {
		return analysis(
			ifSuccess: Result<Value, Error2>.Success,
			ifFailure: transform)
	}
#else
	@warn_unused_result
	public func flatMapError<Error2>(@noescape transform: Error -> Result<Value, Error2>) -> Result<Value, Error2> {
		return analysis(
			ifSuccess: Result<Value, Error2>.Success,
			ifFailure: transform)
	}
#endif
}

public extension ResultType {

	// MARK: Higher-order functions

	/// Returns `self.value` if this result is a .Success, or the given value otherwise. Equivalent with `??`
#if swift(>=3)
	public func recover(_ value: @autoclosure () -> Value) -> Value {
		return self.value ?? value()
	}
#else
	public func recover(@autoclosure value: () -> Value) -> Value {
		return self.value ?? value()
	}
#endif

	/// Returns this result if it is a .Success, or the given result otherwise. Equivalent with `??`
#if swift(>=3)
	public func recoverWith(_ result: @autoclosure () -> Self) -> Self {
		return analysis(
			ifSuccess: { _ in self },
			ifFailure: { _ in result() })
	}
#else
	public func recoverWith(@autoclosure result: () -> Self) -> Self {
		return analysis(
			ifSuccess: { _ in self },
			ifFailure: { _ in result() })
	}
#endif
}

/// Protocol used to constrain `tryMap` to `Result`s with compatible `Error`s.
public protocol ErrorTypeConvertible: ResultErrorType {
#if swift(>=3)
	static func errorFromErrorType(_ error: ResultErrorType) -> Self
#else
	static func errorFromErrorType(error: ResultErrorType) -> Self
#endif
}

public extension ResultType where Error: ErrorTypeConvertible {

	/// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
#if swift(>=3)
	@warn_unused_result
	public func tryMap<U>(_ transform: @noescape (Value) throws -> U) -> Result<U, Error> {
		return flatMap { value in
			do {
				return .Success(try transform(value))
			}
			catch {
				let convertedError = Error.errorFromErrorType(error)
				// Revisit this in a future version of Swift. https://twitter.com/jckarter/status/672931114944696321
				return .Failure(convertedError)
			}
		}
	}
#else
	@warn_unused_result
	public func tryMap<U>(@noescape transform: Value throws -> U) -> Result<U, Error> {
		return flatMap { value in
			do {
				return .Success(try transform(value))
			}
			catch {
				let convertedError = Error.errorFromErrorType(error)
				// Revisit this in a future version of Swift. https://twitter.com/jckarter/status/672931114944696321
				return .Failure(convertedError)
			}
		}
	}
#endif
}

// MARK: - Operators

infix operator &&& {
	/// Same associativity as &&.
	associativity left

	/// Same precedence as &&.
	precedence 120
}

/// Returns a Result with a tuple of `left` and `right` values if both are `Success`es, or re-wrapping the error of the earlier `Failure`.
#if swift(>=3)
public func &&& <L: ResultType, R: ResultType where L.Error == R.Error> (left: L, right: @autoclosure () -> R) -> Result<(L.Value, R.Value), L.Error> {
	return left.flatMap { left in right().map { right in (left, right) } }
}
#else
public func &&& <L: ResultType, R: ResultType where L.Error == R.Error> (left: L, @autoclosure right: () -> R) -> Result<(L.Value, R.Value), L.Error> {
	return left.flatMap { left in right().map { right in (left, right) } }
}
#endif

infix operator >>- {
	// Left-associativity so that chaining works like you’d expect, and for consistency with Haskell, Runes, swiftz, etc.
	associativity left

	// Higher precedence than function application, but lower than function composition.
	precedence 100
}

/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
///
/// This is a synonym for `flatMap`.
#if swift(>=3)
public func >>- <T: ResultType, U> (result: T, transform: @noescape (T.Value) -> Result<U, T.Error>) -> Result<U, T.Error> {
	return result.flatMap(transform)
}
#else
public func >>- <T: ResultType, U> (result: T, @noescape transform: T.Value -> Result<U, T.Error>) -> Result<U, T.Error> {
	return result.flatMap(transform)
}
#endif

/// Returns `true` if `left` and `right` are both `Success`es and their values are equal, or if `left` and `right` are both `Failure`s and their errors are equal.
public func == <T: ResultType where T.Value: Equatable, T.Error: Equatable> (left: T, right: T) -> Bool {
	if let left = left.value, right = right.value {
		return left == right
	} else if let left = left.error, right = right.error {
		return left == right
	}
	return false
}

/// Returns `true` if `left` and `right` represent different cases, or if they represent the same case but different values.
public func != <T: ResultType where T.Value: Equatable, T.Error: Equatable> (left: T, right: T) -> Bool {
	return !(left == right)
}

/// Returns the value of `left` if it is a `Success`, or `right` otherwise. Short-circuits.
#if swift(>=3)
public func ?? <T: ResultType> (left: T, right: @autoclosure () -> T.Value) -> T.Value {
	return left.recover(right())
}
#else
public func ?? <T: ResultType> (left: T, @autoclosure right: () -> T.Value) -> T.Value {
	return left.recover(right())
}
#endif

/// Returns `left` if it is a `Success`es, or `right` otherwise. Short-circuits.
#if swift(>=3)
public func ?? <T: ResultType> (left: T, right: @autoclosure () -> T) -> T {
	return left.recoverWith(right())
}
#else
public func ?? <T: ResultType> (left: T, @autoclosure right: () -> T) -> T {
	return left.recoverWith(right())
}
#endif
