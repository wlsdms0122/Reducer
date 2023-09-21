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
    .package(url: "https://github.com/wlsdms0122/Reducer.git", exact: "1.1.0")
]
```

# Getting Started
> This guide dose not cover the detailed principles of state design.
> For more information, plrease refer to the [ReactorKit](https://github.com/ReactorKit/ReactorKit) or [TCA](https://github.com/pointfreeco/swift-composable-architecture) README.

To get started, you'll need to define a class that adopts the `Reduce` protocol.

```swift
final class CounterReduce: Reduce {
    // User interaction input.
    enum Action {
        case increase
    }
    
    // Unit of state mutation.
    enum Mutation {
        case addOne
    }

    // Reducer state.
    struct State {
        var count: Int
    }

    var mutator: Mutator<Mutation, State>?
    let initialState: State

    init(initialState: State) {
        self.initialState = initialState
    }
    
    func mutate(state: State, action: Action) async throws {
        switch action {
        case .increase:
            mutate(.addOne)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state

        switch mutation {
        case .addOne:
            state.count += 1
            return state
        }
    }
}
```

The `mutate(state:action) async throws` method defines what to mutate when an action received with the current state. You can call `mutate(_:)`(an extended function) to mutate. and `Swift Concurrency` can be used within the mutate method as well.

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

```swift
final class SignUpReduce: Reduce {
    enum Action {
        case updateEmail(String)
    }

    enum Mutation {
        case canSignUp(Bool)
    }

    struct State {
        var canSignUp: Bool
    }

    var mutator: (any Mutator<Mutation, State>)?
    let initialState: State

    private let validator = EmailValidator()

    init() {
        initialState = State(canSignUp: false)
    }

    func mutate(state: State, action: Action) async throws {
        switch action {
        case let .updateEmail(email):
            let result = try await validator.validate(email)
            mutate(.canSignUp(result))
        }
    }

    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool {
        switch (current.action, upcoming.action) {
        case (.emailChanged, .emailChanged):
            return true
        }
    }
}
```

### Internal Mutating
The reducer sometimes needs to mutate state without explicit outside action like some domain data changed.

In these case, you can use `start(with:)` function. It call once when `Reducer` set `Reduce`. So you can any initialize process with mutations.

```swift
final class ListReduce: Reduce {
    enum Action { ... }

    enum Mutation {
        case setList([Item])
        ...
    }

    struct State {
        var list: [Item]
        ...
    }

    var mutator: (any Mutator<Mutation, State>)?
    let initialState: State
    
    init() { ... }

    func start(with mutator: any Mutator<Mutation, State>) async throws {
        NotificationCenter.default.publisher(for: .init("data_changed"))
            .sink { data in 
                // Write any mutates here.
                mutator(.setList($0.object))
            }
            // You can mutator scope cancellable bag.
            // It all cancel when mutator(reducer) deinit.
            .store(in: mutator.cancellableBag)
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
    mutate: { state, action, mutate in
        
    },
    reduce: { state, mutation in
        // Return the state of result of mutating.
    },
    shouldCancel: { current, upcoming in
        // Return wether the current action should be canceled via the upcoming action.
    }
)))
```

# Contribution

Any ideas, issues, opinions are welcome.

# License

Reducer is available under the MIT license. See the LICENSE file for more info.
