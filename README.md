# CardKit Runtime

This is the runtime engine for the [CardKit](https://github.ibm.com/CMER/card-kit) project. It is kept as a separate project to enable a decoupling between the *creation* of CardKit programs and the *execution* of such programs.

CardKit Runtime is written in Swift and supports macOS, iOS, and tvOS.

CardKit Runtime depends on [Freddy](https://github.com/bignerdranch/Freddy) for JSON object serialization & deserialization.

## Building

We use Carthage to manage our dependencies. Run `carthage bootstrap` to build all of the dependencies before building the CardKit Runtime Xcode project.

### Developing CardKit and CardKit Runtime

In order to simultaneously develop `CardKit` and `CardKit Runtime`, you'll want to check out `CardKit` as a submodule. You'll also want to build it with the Debug configuration so the tests work. After cloning this project from git, run the following commands:

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