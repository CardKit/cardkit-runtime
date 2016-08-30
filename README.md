# CardKit Runtime

This is the runtime engine for the [CardKit](https://github.ibm.com/CMER/card-kit) project. It is kept as a separate project to enable a decoupling between the *creation* of CardKit programs and the *execution* of such programs.

CardKit Runtime is written in Swift and supports macOS, iOS, and tvOS.

CardKit Runtime depends on [Freddy](https://github.com/bignerdranch/Freddy) for JSON object serialization & deserialization.

## Validation

CardKit Runtime contains a `ValidationEngine` that will validate CardKit programs before execution. Validation performs a series of checks at three levels:

* Deck-level validation to perform checks such as whether multiple cards share the same identifier or that a yield is consumed only after it is produced. `DeckValidator` performs these checks.
* Hand-level validation to perform checks for a `Hand`, such as containing multiple branch cards for the same `CardTree` or circular references in the branching structure of subhands. `HandValidator` performs these checks.
* Card-level validation to perform checks for a card, such as unbound mandatory inputs or bindings to unexpected types. `CardValidator` performs these checks.

`ValidationEngine` performs validation checks in a multi-threaded fashion. It will first produce a master list of all validation actions to be performed on a Deck. These are then executed in parallel in `executeValidation()` via `dispatch_apply`. Validation errors are coalesced and returned synchronously.

## Execution

Execution of a Deck relies heavily on the multi-threading APIs provided by `NSOperation` and GCD.

### Execution Engine and Deck Executor

The `ExecutionEngine` is responsible for the execution of a Deck. `ExecutionEngine` provides a thin wrapper on top of `DeckExecutor`, which performs the actual work of executing a deck. `ExecutionEngine` provides a synchronous `execute()` method which accepts a block that is called when execution is finished. This block accepts two parameters: the `YieldBindings` that have been produced from the execution (a map between `Yield` and `InputDataBinding`), and an `ExecutionError?` specifying whether there was an error during execution.

`DeckExecutor` is responsible for the heavy-lifting of execution. It maintains a mapping between `ActionCardDescriptor`s and the type responsible for executing that Action card (a subclass of `ExecutableActionCard`). `ExecutionEngine` also contains methods which pass the `ExecutableActionCard` types to `DeckExecutor`. Here is an example:

```
let engine = ExecutionEngine(with: deck)
engine.setExecutableActionType(CKAdd.self, for: CKCalc.Action.Math.Add)
engine.setExecutableActionType(CKSubtract.self, for: CKCalc.Action.Math.Subtract)
engine.setExecutableActionType(CKMultiply.self, for: CKCalc.Action.Math.Multiply)
engine.setExecutableActionType(CKDivide.self, for: CKCalc.Action.Math.Divide)
```

In this example, we assume `ActionCardDescriptors` exist for a hypothetical calculator's addition, subtraction, multiplication, and division functions. These methods will be implemented by the classes `CKAdd`, `CKSubtract`, `CKMultiply`, and `CKDivide` (these classes all subclass `ExecutableActionCard`). The above code tells the `ExecutionEngine`, as well as its underlying `DeckExecutor`, that these classes should be instantiated when their corresponding Action cards are encountered in the Deck.

`ExecutionEngine` and `DeckExecutor` also maintain a map between `TokenCard`s and the `ExecutableTokenCard` that implements the tokens. Continuing our example, we define a calculator token `CKCalc.Token.Calculator` and its implementation `CKCalculator : ExecutableTokenCard`, and pass these to the execution engine.

```
let calcToken = CKCalc.Token.Calculator.makeCard()
let calculator = CKSlowCalculator(with: calcToken)
engine.setTokenInstance(calculator, for: calcToken)
```

### Execution Strategy

`DeckExecutor` is a subclass of `NSOperation`, enabling it to function on a background thread managed by an `NSOperationQueue`. `ExecutionEngine` manages an operation queue for `DeckExecutor`, but if finer-grained control over execution is required, `DeckExecutor` may also be used in your own operation queue outside of `ExecutionEngine`.

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

## Building

We use Carthage to manage our dependencies. Run `carthage bootstrap` to build all of the dependencies before building the CardKit Runtime Xcode project.

### Developing CardKit and CardKit Runtime

In order to simultaneously develop `CardKit` and `CardKit Runtime`, you will want to check out `CardKit` as a submodule. You will also want to build it with the Debug configuration so the tests work. After cloning this project from git, run the following commands:

```
carthage checkout --use-submodules
carthage build --configuration Debug
```

Now, when you make modifications to files in `CardKit Runtime/Carthage/Checkouts/card-kit`, you can push those changes back to the source `CardKit` repository.

In addition, there is a Run Script build phase that will rebuild `CardKit` each time `CardKit Runtime` is built. Thus, any local changes made to `CardKit` during development are included when building `CardKit Runtime`, without needing to check those changes back into git. However, as it takes a *long* time to build `CardKit` before each `CardKit Runtime` build, this script is disabled. To enable it, go to Build Phases for the target and uncomment the '#' in the 2nd to last Run Script (the one that runs `/usr/local/bin/carthage build`).

For more information about this process, please refer to [Using Submodules for Dependencies](https://github.com/Carthage/Carthage#using-submodules-for-dependencies) in the Carthage manual.

## Contributing

If you would like to contribute to CardKit Runtime, we recommend forking the repository, making your changes, and submitting a pull request.

## Contact

The authors of CardKit Runtime are members of the Center for Mobile Enterprise Research in IBM Research.

* Justin Weisz, jweisz@us.ibm.com
* Justin Manweiler, jmanweiler@us.ibm.com
* Saad Ismail, saad@us.ibm.com