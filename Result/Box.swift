//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An implementation detail of `Result`
public final class Box<T> {
	public init(_ value: T) {
		self.value = value
	}

	public let value: T
}
