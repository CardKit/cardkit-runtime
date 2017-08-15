# CardKit Runtime

This is the runtime engine for [CardKit](https://github.ibm.com/CMER/card-kit). It is a separate project to enable a decoupling between the *creation* of CardKit programs and the *execution* of such programs.

CardKit Runtime is written in Swift 4 and supports macOS, iOS, and tvOS.

## Validation

CardKit Runtime contains a `ValidationEngine` that will validate CardKit programs before execution. Validation performs a series of checks at three levels:

* Deck-level validation to perform checks such as whether multiple cards share the same identifier or that a yield is consumed only after it is produced. `DeckValidator` performs these checks.
* Hand-level validation to perform checks for a `Hand`, such as containing multiple branch cards for the same `CardTree` or circular references in the branching structure of subhands. `HandValidator` performs these checks.
* Card-level validation to perform checks for a card, such as unbound mandatory inputs or bindings to unexpected types. `CardValidator` performs these checks.

`ValidationEngine` performs validation checks in a multi-threaded fashion. It will first produce a master list of all validation actions to be performed on a Deck. These are then executed in parallel in `executeValidation()` via `dispatch_apply`. Validation errors are coalesced and returned synchronously.

## Execution

Execution of a Deck relies heavily on the multi-threading APIs provided by `NSOperation` and GCD.

### Execution Engine

The `ExecutionEngine` is responsible for the execution of a Deck. `ExecutionEngine` provides a thin wrapper on top of `DeckExecutor`, which performs the actual work of executing a deck; however, `DeckExecutor` is not intended for direct use.

`ExecutionEngine` provides a synchronous `execute(_:)` method that calls a block when execution is finished. This block accepts two parameters: the `[YieldData]` that were produced from the execution, and an `ExecutionError?` specifying whether there was an error during execution.

`ExecutionEngine` maintains a mapping between `ActionCardDescriptor`s and the type responsible for executing that Action card (a subclass of `ExecutableActionCard`). Here is an example:

```
let deck = ...
let engine = ExecutionEngine(with: deck)
engine.setExecutableActionType(CKAdd.self, for: CKCalc.Action.Math.Add)
engine.setExecutableActionType(CKSubtract.self, for: CKCalc.Action.Math.Subtract)
engine.setExecutableActionType(CKMultiply.self, for: CKCalc.Action.Math.Multiply)
engine.setExecutableActionType(CKDivide.self, for: CKCalc.Action.Math.Divide)
```

In this example, we assume `ActionCardDescriptors` exist for a hypothetical calculator's addition, subtraction, multiplication, and division functions. These methods will be implemented by the classes `CKAdd`, `CKSubtract`, `CKMultiply`, and `CKDivide`, all of which are subclasses of `ExecutableActionCard`. The above code tells the `ExecutionEngine`, as well as its underlying `DeckExecutor`, that these classes should be instantiated when their corresponding Action cards are encountered in the Deck.

`ExecutionEngine` also maintains a map between `TokenCard`s and the `ExecutableTokenCard` that implements the tokens. Continuing our example, we define a calculator token `CKCalc.Token.Calculator` and its implementation `CKCalculator : ExecutableTokenCard`, and pass these to the execution engine.

```
let calcToken = CKCalc.Token.Calculator.makeCard()
let calculator = CKSlowCalculator(with: calcToken)
engine.setTokenInstance(calculator, for: calcToken)
```

### Execution Strategy

`DeckExecutor` performs the heavy lifting of executing a Deck. It is a subclass of `NSOperation`, enabling it to function on a background thread managed by an `NSOperationQueue`. `ExecutionEngine` manages an operation queue for `DeckExecutor`.

`DeckExecutor` begins execution with the first Hand specified in the Deck. It creates an `ExecutableActionCard` instance for each `ActionCard` in the Hand, and provides any required yields produced from prior Hands and required Token implementation instances (`ExecutableTokenCard`). It then creates its own `NSOperationQueue`to execute all cards in a Hand simultaneously. In order to determine when a single card has finished executing, it creates a dependent block operation for each `ExecutableActionCard` to check the Hand's satisfaction state. The `NSOperationQueue` looks like the following, for four `ExecutableActionCard`s:

```
+-----+ +-----+ +-----+ +-----+
| A1  | | A2  | | A3  | | A4  |
+-----+ +-----+ +-----+ +-----+
   |       |       |       |
   v       v       v       v
+-----+ +-----+ +-----+ +-----+
|done?| |done?| |done?| |done?|
+-----+ +-----+ +-----+ +-----+
```

Each `done?` operation checks the satisfaction state of the Hand given the current set of "done" cards. If it is determined that the hand has been satisfied, the rest of the operations in the queue are cancelled, and execution moves to the next Hand.

### Executable Action Cards

The `ExecutableActionCard` class is responsible for managing the runtime execution of an `ActionCard`. This class is instantiated by the `ExecutionEngine`. Subclasses of `ExecutableActionCard` must override `main()` and provide their functionality from that method. Note that `main()` will be called from a background thread, and once execution from`main()` exits, the card will be considered to be done. Thus, if an `ExecutableActionCard` subclass wishes to perform any background processing or use asynchronous APIs, it is critical to block `main()` from exiting until all background processing is finished or asynchronous results are obtained.

### Executable Tokens

The `ExecutableTokenCard` class is responsible for providing the API to the physical/virtual object managed by the token. Subclasses of `ExecutableTokenCard` may provide whatever API they wish, although `ExecutableActionCards` must know how to downcast the `ExecutableTokenCard` instances they receive in order to access this API. For example, in the implementation of `CKAdd` from above, this is how it retrieves the Calculator token:

```
// obtain the TokenSlot named "Calculator", which is where our Calculator will be stored
guard let calcSlot = self.actionCard.tokenSlots.slot(named: "Calculator") else {
	self.error = .ExpectedTokenSlotNotFound(self, "Calculator")
	return
}
// obtain the instance of our Calculator as a CKCalculator
guard let calc = self.tokens[calcSlot] as? CKCalculator else {
	self.error = .UnboundTokenSlot(self, calcSlot)
	return
}
```

### Execution Status

In order to monitor the status of execution, `ExecutionEngine` contains a `delegate` property of type `ExecutionEngineDelegate` that provides an interface for receiving notifications when activities occur around validation, execution, and errors.


## Building

We use Carthage to manage our dependencies. Run `carthage bootstrap` to build all of the dependencies before building the CardKit Runtime Xcode project.

### Developing for CardKit and CardKit Runtime

The easiest way to simultaneously develop CardKit and CardKit Runtime is to check out both projects into the same directory and use the `CardKitRuntime.xcworkspace` to keep both projects open.

It is also possible to check out CardKit as a submodule using Carthage, as detailed in [Using Submodules for Dependencies](https://github.com/Carthage/Carthage#using-submodules-for-dependencies) in the Carthage manual. We have found that the `xcworkspace` method is easier to understand and use.

## Contributing

If you would like to contribute to CardKit Runtime, we recommend forking the repository, making your changes, and submitting a pull request.

## Contact

Please contact Justin Weisz (jweisz [at] us.ibm.com) with any questions.
