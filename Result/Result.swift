//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T, Error: ResultErrorType>: ResultType, CustomStringConvertible, CustomDebugStringConvertible {
	case success(T)
	case failure(Error)

	// MARK: Constructors

	/// Constructs a success wrapping a `value`.
	public init(value: T) {
		self = .success(value)
	}

	/// Constructs a failure wrapping an `error`.
	public init(error: Error) {
		self = .failure(error)
	}

	/// Constructs a result from an Optional, failing with `Error` if `nil`.
#if swift(>=3)
	public init(_ value: T?, failWith: @autoclosure () -> Error) {
		self = value.map(Result.success) ?? .failure(failWith())
	}
#else
	public init(_ value: T?, @autoclosure failWith: () -> Error) {
		self = value.map(Result.success) ?? .failure(failWith())
	}
#endif

	/// Constructs a result from a function that uses `throw`, failing with `Error` if throws.
#if swift(>=3)
	public init(_ f: @autoclosure () throws -> T) {
		self.init(attempt: f)
	}
#else
	public init(@autoclosure _ f: () throws -> T) {
		self.init(attempt: f)
	}
#endif

	/// Constructs a result from a function that uses `throw`, failing with `Error` if throws.
#if swift(>=3)
	public init(attempt f: @noescape () throws -> T) {
		do {
			self = .success(try f())
		} catch {
			self = .failure(error as! Error)
		}
	}
#else
	public init(@noescape attempt f: () throws -> T) {
		do {
			self = .success(try f())
		} catch {
			self = .failure(error as! Error)
		}
	}
#endif

	// MARK: Deconstruction

	/// Returns the value from `Success` Results or `throw`s the error.
	public func dematerialize() throws -> T {
		switch self {
		case let .success(value):
			return value
		case let .failure(error):
			throw error
		}
	}

	/// Case analysis for Result.
	///
	/// Returns the value produced by applying `ifFailure` to `Failure` Results, or `ifSuccess` to `Success` Results.
#if swift(>=3)
	public func analysis<Result>(ifSuccess: @noescape (T) -> Result, ifFailure: @noescape (Error) -> Result) -> Result {
		switch self {
		case let .success(value):
			return ifSuccess(value)
		case let .failure(value):
			return ifFailure(value)
		}
	}
#else
	public func analysis<Result>(@noescape ifSuccess: (T) -> Result, @noescape ifFailure: (Error) -> Result) -> Result {
		switch self {
		case let .success(value):
			return ifSuccess(value)
		case let .failure(value):
			return ifFailure(value)
		}
	}
#endif

	// MARK: Errors

	/// The domain for errors constructed by Result.
	public static var errorDomain: String { return "com.antitypical.Result" }

	/// The userInfo key for source functions in errors constructed by Result.
	public static var functionKey: String { return "\(errorDomain).function" }

	/// The userInfo key for source file paths in errors constructed by Result.
	public static var fileKey: String { return "\(errorDomain).file" }

	/// The userInfo key for source file line numbers in errors constructed by Result.
	public static var lineKey: String { return "\(errorDomain).line" }

	#if os(Linux)
	private typealias UserInfoType = Any
	#else
	private typealias UserInfoType = AnyObject
	#endif

	/// Constructs an error.
#if swift(>=3)
	public static func error(_ message: String? = nil, function: String = #function, file: String = #file, line: Int = #line) -> NSError {
		var userInfo: [String: UserInfoType] = [
		                                       	functionKey: function,
		                                       	fileKey: file,
		                                       	lineKey: line,
		                                       	]
		
		if let message = message {
			userInfo[NSLocalizedDescriptionKey] = message
		}
		
		return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
	}
#else
	public static func error(_ message: String? = nil, function: String = #function, file: String = #file, line: Int = #line) -> NSError {
		var userInfo: [String: UserInfoType] = [
			functionKey: function,
			fileKey: file,
			lineKey: line,
		]

		if let message = message {
			userInfo[NSLocalizedDescriptionKey] = message
		}

		return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
	}
#endif


	// MARK: CustomStringConvertible

	public var description: String {
		return analysis(
			ifSuccess: { ".success(\($0))" },
			ifFailure: { ".failure(\($0))" })
	}


	// MARK: CustomDebugStringConvertible

	public var debugDescription: String {
		return description
	}
}

// MARK: - Derive result from failable closure

#if swift(>=3)
public func materialize<T>(_ f: @noescape () throws -> T) -> Result<T, NSError> {
	return materialize(try f())
}

public func materialize<T>(_ f: @autoclosure () throws -> T) -> Result<T, NSError> {
	do {
		return .success(try f())
	} catch let error as NSError {
		return .failure(error)
	}
}
#else
public func materialize<T>(@noescape _ f: () throws -> T) -> Result<T, NSError> {
	return materialize(try f())
}
	
public func materialize<T>(@autoclosure _ f: () throws -> T) -> Result<T, NSError> {
	do {
		return .success(try f())
	} catch let error as NSError {
		return .failure(error)
	}
}
#endif

// MARK: - Cocoa API conveniences

#if !os(Linux)

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns an object or `nil` + an error, by reference. e.g.:
///
///     Result.try { NSData(contentsOfURL: URL, options: .DataReadingMapped, error: $0) }
#if swift(>=3)
public func `try`<T>(_ function: String = #function, file: String = #file, line: Int = #line, `try`: (NSErrorPointer) -> T?) -> Result<T, NSError> {
	var error: NSError?
	return `try`(&error).map(Result.success) ?? .failure(error ?? Result<T, NSError>.error(function: function, file: file, line: line))
}
#else
public func `try`<T>(_ function: String = #function, file: String = #file, line: Int = #line, try: (NSErrorPointer) -> T?) -> Result<T, NSError> {
	var error: NSError?
	return `try`(&error).map(Result.success) ?? .failure(error ?? Result<T, NSError>.error(function: function, file: file, line: line))
}
#endif

/// Constructs a Result with the result of calling `try` with an error pointer.
///
/// This is convenient for wrapping Cocoa API which returns a `Bool` + an error, by reference. e.g.:
///
///     Result.try { NSFileManager.defaultManager().removeItemAtURL(URL, error: $0) }
#if swift(>=3)
public func `try`(_ function: String = #function, file: String = #file, line: Int = #line, `try`: (NSErrorPointer) -> Bool) -> Result<(), NSError> {
	var error: NSError?
	return `try`(&error) ?
		.success(())
	:	.failure(error ?? Result<(), NSError>.error(function: function, file: file, line: line))
}
#else
public func `try`(_ function: String = #function, file: String = #file, line: Int = #line, try: (NSErrorPointer) -> Bool) -> Result<(), NSError> {
	var error: NSError?
	return `try`(&error) ?
		.success(())
	:	.failure(error ?? Result<(), NSError>.error(function: function, file: file, line: line))
}
#endif

#endif

// MARK: - ErrorTypeConvertible conformance
	
extension NSError: ErrorTypeConvertible {
#if swift(>=3)
	public static func errorFromErrorType(_ error: ResultErrorType) -> Self {
		func cast<T: NSError>(_ error: ResultErrorType) -> T {
			return error as! T
		}

		return cast(error)
	}
#else
	public static func errorFromErrorType(_ error: ResultErrorType) -> Self {
		func cast<T: NSError>(_ error: ResultErrorType) -> T {
			return error as! T
		}

		return cast(error)
	}
#endif
}

// MARK: -

/// An “error” that is impossible to construct.
///
/// This can be used to describe `Result`s where failures will never
/// be generated. For example, `Result<Int, NoError>` describes a result that
/// contains an `Int`eger and is guaranteed never to be a `Failure`.
public enum NoError: ResultErrorType { }

import Foundation
