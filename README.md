# Result

This is a Swift µframework providing `Result<Value, Error>`.

`Result<Value, Error>` values are either successful (wrapping `Value`) or failed (wrapping `Error`). This is similar to Swift’s native `Optional` type, with the addition of an error value to pass some error code, message, or object along to be logged or displayed to the user.


## Use

API documentation is in the source.


## Integration

1. Add this repository as a submodule and check out its dependencies, and/or [add it to your Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile) if you’re using [carthage](https://github.com/Carthage/Carthage/) to manage your dependencies.
2. Drag `Result.xcodeproj` into your project or workspace, and do the same with its dependencies (i.e. the other `.xcodeproj` files included in `Result.xcworkspace`). NB: `Result.xcworkspace` is for standalone development of Result, while `Result.xcodeproj` is for targets using Result as a dependency.
3. Link your target against `Result.framework` and each of the dependency frameworks.
4. Application targets should ensure that the framework gets copied into their application bundle. (Framework targets should instead require the application linking them to include Result and its dependencies.)
