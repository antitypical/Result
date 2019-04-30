/// An “error” that is impossible to construct.
///
/// This can be used to describe `Result`s where failures will never
/// be generated. For example, `Result<Int, NoError>` describes a result that
/// contains an `Int`eger and is guaranteed never to be a `failure`.
#if swift(>=5.0)
@available(*, deprecated, message: "Use `Swift.Never` instead", renamed: "Never")
public enum NoError: Swift.Error, Equatable {
	public static func ==(lhs: NoError, rhs: NoError) -> Bool {
		return true
	}
}
#else
public enum NoError: Swift.Error, Equatable {
	public static func ==(lhs: NoError, rhs: NoError) -> Bool {
		return true
	}
}
#endif
