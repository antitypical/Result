//  Copyright (c) 2015 Rob Rix. All rights reserved.

/// An enum representing either a failure with an explanatory error, or a success with a result value.
public enum Result<T> {
	case Failure(NSError)
	case Success(Box<T>)
}


// MARK: - Imports

import Box
import Foundation
