//  Copyright (c) 2015 Rob Rix. All rights reserved.

internal final class Box<T> {
	init(_ value: T) {
		self.value = value
	}

	let value: T
}
