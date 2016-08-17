# CardKit Runtime

This is the runtime engine for the [CardKit](https://github.ibm.com/CMER/card-kit) project. It is kept as a separate project to enable a decoupling between the *creation* of CardKit programs and the *execution* of such programs.

CardKit Runtime is written in Swift and supports macOS, iOS, and tvOS.

CardKit Runtime depends on [Freddy](https://github.com/bignerdranch/Freddy) for JSON object serialization & deserialization.

## Building

We use Carthage to manage our dependencies. Run `carthage bootstrap` to build all of the dependencies before building the CardKit Runtime Xcode project.

### Developing CardKit and CardKit Runtime

In order to simultaneously develop `CardKit` and `CardKit Runtime`, you'll want to check out `CardKit` as a submodule. After cloning this project from git, run the following commands:

```
carthage checkout --use-submodules card-kit
carthage update
```

Please refer to [Using Submodules for Dependencies](https://github.com/Carthage/Carthage#using-submodules-for-dependencies) in the Carthage manual for more information on this process.

## Contributing

If you would like to contribute to CardKit Runtime, we recommend forking the repository, making your changes, and submitting a pull request.

## Contact

The authors of CardKit Runtime are members of the Center for Mobile Enterprise Research in IBM Research.

* Justin Weisz, jweisz@us.ibm.com
* Justin Manweiler, jmanweiler@us.ibm.com
* Saad Ismail, saad@us.ibm.com