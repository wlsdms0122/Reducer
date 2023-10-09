# Reducer
`Reducer` is unidirectional state machine framework that inspired by [ReactorKit](https://github.com/ReactorKit/ReactorKit) & [TCA](https://github.com/pointfreeco/swift-composable-architecture).

- [Reducer](#reducer)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Getting Started](#getting-started)
  - [Advance Usage](#advance-usage)
    - [Cancel Action](#cancel-action)
    - [Internal Mutating](#internal-mutating)
- [Test](#test)
- [Contribution](#contribution)
- [License](#license)

# Requirements
- iOS 13.0+
- macOS 10.15+
- macCatalyst 13.0+
- tvOS 13.0+
- watchOS 6.0+

# Installation
## Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/wlsdms0122/Reducer.git", .upToNextMajor(from: "2.0.0"))
]
```

# Getting Started
> This guide dose not cover the detailed principles of state design.
> For more information, plrease refer to the [ReactorKit](https://github.com/ReactorKit/ReactorKit) or [TCA](https://github.com/pointfreeco/swift-composable-architecture) README.

To get started, You can define it via the `@Reduce` macro. or you can adopt the `Reduce` protocol.

By default, `Reducer` runs on the UI's main thread, while `Reduce` does not. It's fine to use `Reduce` without the `@MainActor` constraint, but if you want the actions to run sequentially, add the `@MainActor` annotation.

> ⚠️ When implementing `Reduce`, there is a slight difference in the use of macro and protocol.

```swift
@Reduce
@MainActor
final class CounterReduce {
    // User interaction input.
    enum Action {
        case increase
    }
    
    // Unit of state mutation.
    enum Mutation {
        case setCount(Int)
    }

    // Reducer state.
    struct State {
        var count: Int
    }

    let initialState: State

    init() {
        self.initialState = State()
    }
    
    func mutate(action: Action) async throws {
        switch action {
        case .increase:
            mutate(.setCount(currentState.count + 1))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state

        switch mutation {
        case let .setCount(count):
            state.count = count
            return state
        }
    }
}
```

The `mutate(action:) async throws` method defines what to mutate when an action received with the current state. You can call `mutate(_:)`(an extended function) to mutate. and `Swift Concurrency` can be used within the mutate method as well.

`reduce(state:mutation)` describe how to mutate the state from a mutation. It should be a pure function.

```swift
struct CounterView: View {
    var body: some Body {
        VStack {
            Text("\(reducer.state.count)")
            Button("Increase") {
                reducer.action(.increase)
            }
        }
    }

    @StateObject
    var reducer = Reducer(CounterReduce()) // Reducer<CounterReduce>
}
```

The `Reducer` is used to reduce the state using injected `Reduce`. It is designed for use with `SwiftUI` and already adopts the `ObservableObject` protocol.

But it can also be used for `UIKit` like this. How you use it is up to you.

```swift
import Combine

class CounterViewController: UIViewController {
    @IBOutlet var countLabel: UILabel!

    private let reducer = Reducer(CounterReduce())
    private var cancellableBag: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    private func bind() {
        reducer.$state.map(\.count)
            .removeDuplicates()
            .map(String.init)
            .assign(to: \.text, on: countLabel)
            .store(in: &cancellableBag)
    }

    @IBAction func increaseTap(_ sender: UIButton) {
        reducer.action(.increase)
    }
}
```

## Advance Usage
### Cancel Action
You can cancel running action task using `shouldCancel(_:_:) -> Bool`.

For example, if you want to cancel validating user input for each keystroke to efficiently use resources, `Reducer` can determine whether the current running task should be canceled before creating a new task action. If `shouldCancel(_:_:)` returns `true`, the current action should be canceled.

⚠️ The first thing to note about canceling a task is that the general expectation is that the comparison of actions should return `false` except for the case you want to cancel.

The second thing to note that canceling a Task doesn't stop your code from progressing. In swift concurrency, [cancel](https://developer.apple.com/documentation/swift/task/cancel()) of task doesn't has no effect basically.

If you want to make canceling a task meaningful, you'll need to [create a cancelable async method](https://developer.apple.com/documentation/swift/withtaskcancellationhandler(operation:oncancel:)) or utilize something like [`Task.checkCancellation()`](https://developer.apple.com/documentation/swift/task/checkcancellation()).

```swift
@Reduce
@MainActor
final class SignUpReduce {
    enum Action {
        case updateEmail(String)
        case anyAction
    }

    enum Mutation {
        case canSignUp(Bool)
    }

    struct State {
        var canSignUp: Bool
    }

    let initialState: State

    private let validator = EmailValidator()

    init() {
        initialState = State(canSignUp: false)
    }

    func mutate(action: Action) async throws {
        switch action {
        case let .updateEmail(email):
            let result = try await validator.validate(email)
            try Task.checkCancellation()
            
            mutate(.canSignUp(result))

        case .anyAction:
            ...
        }
    }

    ...

    func shouldCancel(_ current: Action, _ upcoming: Action) -> Bool {
        switch (current, upcoming) {
        case (.emailChanged, .emailChanged):
            return true

        default:
            return false
        }
    }
}
```

### Internal Mutating
The reducer sometimes needs to mutate state without explicit outside action like some domain data changed.

In these case, you can use `start()` function. It call once when `Reducer` set `Reduce`. So you can any initialize process with mutations.

```swift
@Reduce
@MainActor
final class ListReduce {
    enum Action { ... }

    enum Mutation {
        case setList([Item])
        ...
    }

    struct State {
        var list: [Item]
        ...
    }

    let initialState: State
    private var cancellableBag = Set<AnyCancellable>()
    
    init() { ... }

    func start() async throws {
        // Reset subscription when reduce re-start by reducer.
        cancellableBag.removeAll()
        
        NotificationCenter.default.publisher(for: .init("data_changed"))
            .sink { [weak self] data in 
                // Write any mutates here.
                self?.mutate(.setList(data.object))
            }
            .store(in: &cancellableBag)
    }
}
```

# Test
The `Reducer` supports proxy reduce for testing.

For example, suppose there is the view that depends on `Reducer<CounterReduce>` instance. in that case, you can manipulate state using `Reducer(proxy:)`.

```swift
struct CounterView: View {
    @StateObject
    var reducer: Reducer<CounterReduce>

    init(reducer: Reducer<CounterReduce>) {
        self._reducer = .init(wrappedValue: reducer)
    }
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView(reducer: .init(proxy: .init(
            initialState: .init(count: 100)
        )))
    }
}
```

The `ProxyReduce` is a feature that enables you to manipulate the `Reduce` instance for testing purposes.

It maipulate all of `Reduce` even the `initialState`.

```swift
CounterView(reducer: .init(proxy: .init(
    initialState: .init(count: 100),
    start: { mutate in ... }
    mutate: { state, action, mutate in ... },
    reduce: { state, mutation in ... },
    shouldCancel: { current, upcoming in ... }
)))
```

# Contribution

Any ideas, issues, opinions are welcome.

# License

Reducer is available under the MIT license. See the LICENSE file for more info.
