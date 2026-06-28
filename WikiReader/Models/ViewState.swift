import Foundation

/// Generic loading state exposed by view models so views can render
/// idle / loading / loaded / empty / error uniformly (spec §5).
enum ViewState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(String)
}
