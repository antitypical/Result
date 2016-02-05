//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// A type that can represent either failure with an error or success with a result value.
public protocol ResultType {
	typealias Value
	typealias Error: ErrorType
	
	/// Constructs a successful result wrapping a `value`.
	init(value: Value)

	/// Constructs a failed result wrapping an `error`.
	init(error: Error)
	
	/// Case analysis for ResultType.
	///
	/// Returns the value produced by appliying `ifFailure` to the error if self represents a failure, or `ifSuccess` to the result value if self represents a success.
	func analysis<U>(@noescape ifSuccess ifSuccess: Value -> U, @noescape ifFailure: Error -> U) -> U

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
	public func map<U>(@noescape transform: Value -> U) -> Result<U, Error> {
		return flatMap { .Success(transform($0)) }
	}

	/// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
	public func flatMap<U>(@noescape transform: Value -> Result<U, Error>) -> Result<U, Error> {
		return analysis(
			ifSuccess: transform,
			ifFailure: Result<U, Error>.Failure)
	}
	
	/// Returns a new Result by mapping `Failure`'s values using `transform`, or re-wrapping `Success`es’ values.
	public func mapError<Error2>(@noescape transform: Error -> Error2) -> Result<Value, Error2> {
		return flatMapError { .Failure(transform($0)) }
	}
	
	/// Returns the result of applying `transform` to `Failure`’s errors, or re-wrapping `Success`es’ values.
	public func flatMapError<Error2>(@noescape transform: Error -> Result<Value, Error2>) -> Result<Value, Error2> {
		return analysis(
			ifSuccess: Result<Value, Error2>.Success,
			ifFailure: transform)
	}
}

/// Protocol used to constrain `tryMap` to `Result`s with compatible `Error`s.
public protocol ErrorTypeConvertible: ErrorType {
	typealias ConvertibleType = Self
	static func errorFromErrorType(error: ErrorType) -> ConvertibleType
}

public extension ResultType where Error: ErrorTypeConvertible {

	/// Returns the result of applying `transform` to `Success`es’ values, or wrapping thrown errors.
	public func tryMap<U>(@noescape transform: Value throws -> U) -> Result<U, Error> {
		return flatMap { value in
			do {
				return .Success(try transform(value))
			}
			catch {
				let convertedError = Error.errorFromErrorType(error) as! Error
				// Revisit this in a future version of Swift. https://twitter.com/jckarter/status/672931114944696321
				return .Failure(convertedError)
			}
		}
	}
}

// MARK: - Operators

infix operator &&& {
	/// Same associativity as &&.
	associativity left

	/// Same precedence as &&.
	precedence 120
}

/// Returns a Result with a tuple of `left` and `right` values if both are `Success`es, or re-wrapping the error of the earlier `Failure`.
public func &&& <L: ResultType, R: ResultType where L.Error == R.Error> (left: L, @autoclosure right: () -> R) -> Result<(L.Value, R.Value), L.Error> {
	return left.flatMap { left in right().map { right in (left, right) } }
}

/// Return a array of `V` by applying transform to all elements of array 'U' and filtering out failure ones
public func mapFilter<U, V, Error>(results: [U], @noescape transform: U -> Result<V, Error>) -> [V]{
	var vs = [V]()
	for result in results{
		if case let .Success(value) = transform(result){
			vs.append(value)
		}
	}
	return vs
}

/// Return a Result with an array of `V`s if all Results of applying `transform` are `Success`es or return the error of the first `Failure`
public func mapM<U, V, Error>(results: [U], @noescape transform: U -> Result<V, Error>) -> Result<[V], Error>{
	var vs = [V]()
	for result in results{
		let mapped = transform(result)
		switch mapped{
		case let .Success(value):
			vs.append(value)
		case let .Failure(error):
			return Result(error: error)
		}
	}
	return Result(vs)
}
