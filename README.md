# Result

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/Result.svg)](https://cocoapods.org/)

This is a Swift µframework providing `Result<Value, Error>`.

`Result<Value, Error>` values are either successful (wrapping `Value`) or failed (wrapping `Error`). This is similar to Swift’s native `Optional` type, with the addition of an error value to pass some error code, message, or object along to be logged or displayed to the user.

## Use

Use `Result` whenever an operation has the possibility of failure. Consider the following example of a function that tries to extract a `String` for a given key from a JSON `Dictionary`.

```swift
typealias JSONObject = [String:AnyObject]

enum JSONError : ErrorType {
    case NoSuchKey(String)
    case TypeMismatch
}

func stringForKey(json: JSONObject, key: String) -> Result<String, JSONError> {
    guard let value = json[key] else {
        return .Failure(.NoSuchKey(key))
    }
    
    if let value = value as? String {
        return .Success(value)
    }
    else {
        return .Failure(.TypeMismatch)
    }
}
```

This function provides a more robust wrapper around the default subscripting provided by `Dictionary`. Rather than return `AnyObject?`, it returns a `Result` that either contains the `String` value for the given key, or an `ErrorType` detailing what went wrong.

One simple way to handle a `Result` is to deconstruct it using a `switch` statement.

```swift
switch stringForKey(json, key: "email") {

case let .Success(email):
    print("The email is \(email)")
    
case let .Failure(JSONError.NoSuchKey(key)):
    print("\(key) is not a valid key")
    
case .Failure(JSONError.TypeMismatch):
    print("Didn't have the right type")
}
```

Using a `switch` statement allows powerful pattern matching, and ensures all possible results are covered. Swift 2.0 offers new ways to deconstruct enums like the `if-case` statement, but be wary as such methods do not ensure errors are handled.

Other methods available for processing `Result` are detailed in the [API documentation](http://cocoadocs.org/docsets/Result/).

## Result vs. Throws

Swift 2.0 introduced error handling via throwing error types. `Result` accomplishes the same goal by encapsulating the result instead of hijacking control flow. The `Result` abstraction also enables powerful functionality such as `map` and `flatMap`.

Since dealing with APIs that throw is common, you can convert functions such functions into a `Result` by using the `materialize` method. [Note: due to compiler issues, `materialize` is not currently available]

## Higher Order Functions

`map` is analagous to `map` for Swift's `Optional`. `map` transforms a `Result` into a `Result` of a new type. It does this by taking a block that processes the `Value` type of the `Result`. This block is only applied to the value if the `Result` is a success. In the case that the `Result` is a `Failure`, the error is re-wrapped in the new `Result`.

```swift
let idResult: Result<Int, JSONError> = parseInt(json, key:"id")
let idStringResult: Result<String, JSONError> = idResult.map { id in String(id) }
```

Here, `idStringResult` is either the id as a `String`, or carries over the `.Failure` from the previous expression.

`flatMap` is similar to `map` in that in transforms the `Result` into another `Result`. However, the function passed into `flatMap` must return a `Result`.

An in depth discussion of `map` and `flatMap` is beyond the scope of this documentation. If you would like a deeper understanding, read about functors and monads. This article is a good place to [start](http://www.javiersoto.me/post/106875422394).

## Integration

1. Add this repository as a submodule and/or [add it to your Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile) if you’re using [carthage](https://github.com/Carthage/Carthage/) to manage your dependencies.
2. Drag `Result.xcodeproj` into your project or workspace.
3. Link your target against `Result.framework`.
4. Application targets should ensure that the framework gets copied into their application bundle. (Framework targets should instead require the application linking them to include Result.)
