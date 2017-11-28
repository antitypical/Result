import Foundation

/// Protocols used to define a wrapper for arbitrary `Error`s.
public protocol ErrorInitializing: Swift.Error {
	init(_ error: Swift.Error)
}
public protocol ErrorConvertible {
	var error : Swift.Error { get }
}

/// A type-erased error which wraps an arbitrary error instance. This should be
/// useful for generic contexts.
public struct AnyError: Swift.Error, ErrorInitializing, ErrorConvertible {
	/// The underlying error.
	public let error: Swift.Error

	public init(_ error: Swift.Error) {
		if let anyError = error as? AnyError {
			self = anyError
		} else {
			self.error = error
		}
	}
}

extension AnyError: CustomStringConvertible {
	public var description: String {
		return String(describing: error)
	}
}

extension AnyError: LocalizedError {
	public var errorDescription: String? {
		return error.localizedDescription
	}

	public var failureReason: String? {
		return (error as? LocalizedError)?.failureReason
	}

	public var helpAnchor: String? {
		return (error as? LocalizedError)?.helpAnchor
	}

	public var recoverySuggestion: String? {
		return (error as? LocalizedError)?.recoverySuggestion
	}
}

public protocol NSErrorInitializing : ErrorInitializing {}

extension NSErrorInitializing {
	public init(_ error: Swift.Error) {
		self = error as! Self
	}
}

extension NSError : NSErrorInitializing {}
