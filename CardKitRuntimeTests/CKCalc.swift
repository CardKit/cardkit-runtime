/**
 * Copyright 2018 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// swiftlint:disable nesting

import Foundation

@testable import CardKit
@testable import CardKitRuntime

public struct CKCalc {
    fileprivate init() {}
    
    // MARK: Action Cards
    
    /// Contains descriptors for Action cards
    public struct Action {
        fileprivate init() {}
        
        /// Contains descriptors for Math cards
        public struct Math {
            fileprivate init() {}
            
            // MARK: Add
            /// Descriptor for Add card
            public static let Add = ActionCardDescriptor(
                name: "Add",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", descriptor: CardKit.Input.Numeric.Real, isOptional: false),
                    InputSlot(name: "B", descriptor: CardKit.Input.Numeric.Real, isOptional: false)
                ],
                tokens: [TokenSlot(name: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: Double.self)],
                yieldDescription: "The sum A + B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "Add"))
            
            // MARK: Subtract
            /// Descriptor for Subtract card
            public static let Subtract = ActionCardDescriptor(
                name: "Subtract",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", descriptor: CardKit.Input.Numeric.Real, isOptional: false),
                    InputSlot(name: "B", descriptor: CardKit.Input.Numeric.Real, isOptional: false)
                ],
                tokens: [TokenSlot(name: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: Double.self)],
                yieldDescription: "The difference A - B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "Subtract"))
            
            // MARK: Multiply
            /// Descriptor for Multiply card
            public static let Multiply = ActionCardDescriptor(
                name: "Multiply",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", descriptor: CardKit.Input.Numeric.Real, isOptional: false),
                    InputSlot(name: "B", descriptor: CardKit.Input.Numeric.Real, isOptional: false)
                ],
                tokens: [TokenSlot(name: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: Double.self)],
                yieldDescription: "The multiplication A * B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "Multiply"))
            
            // MARK: Divide
            /// Descriptor for Divide card
            public static let Divide = ActionCardDescriptor(
                name: "Divide",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", descriptor: CardKit.Input.Numeric.Real, isOptional: false),
                    InputSlot(name: "B", descriptor: CardKit.Input.Numeric.Real, isOptional: false)
                ],
                tokens: [TokenSlot(name: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: Double.self)],
                yieldDescription: "The division A / B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "Divide"))
            
            // MARK: PrimeSieve
            /// Descriptor for PrimeSieve card
            public static let PrimeSieve = ActionCardDescriptor(
                name: "Sieve of Eratosthenes",
                subpath: "Math",
                inputs: nil,
                tokens: [TokenSlot(name: "Sieve", descriptor: CKCalc.Token.Sieve)],
                yields: [Yield(type: PrimeList.self)],
                yieldDescription: "Prime numbers",
                ends: false,
                endsDescription: nil,
                assetCatalog: CardAssetCatalog(description: "Prime Sieve"))
            
            // MARK: DoesNotCompute
            /// Descriptor for DoesNotCompute card
            public static let DoesNotCompute = ActionCardDescriptor(
                name: "Does Not Compute",
                subpath: "Math",
                inputs: nil,
                tokens: nil,
                yields: nil,
                yieldDescription: nil,
                ends: false,
                endsDescription: nil,
                assetCatalog: CardAssetCatalog(description: "Does Not Compute"))
        }
    }
    
    // MARK: Token Cards
    
    /// Contains descriptors for Token cards
    public struct Token {
        fileprivate init() {}
        
        public static let Calculator = TokenCardDescriptor(
            name: "Calculator",
            subpath: nil,
            isConsumed: false,
            assetCatalog: CardAssetCatalog())
        
        public static let Sieve = TokenCardDescriptor(
            name: "Sieve",
            subpath: nil,
            isConsumed: false,
            assetCatalog: CardAssetCatalog())
    }
}

// MARK: - CKAdd

public class CKAdd: ExecutableAction {
    public override func main() {
        // get our inputs
        guard let a: Double = self.value(forInput: "A") else {
            return
        }
        
        guard let b: Double = self.value(forInput: "B") else {
            return
        }
        
        guard let calc: CKCalculator = self.token(named: "Calculator") as? CKCalculator else {
            return
        }
        
        // do the addition!
        let sum = calc.add(a, b)
        
        // save the result
        self.store(sum, forYieldIndex: 0)
    }
}

// MARK: - CKSubtract

public class CKSubtract: ExecutableAction {
    public override func main() {
        // get our inputs
        guard let a: Double = self.value(forInput: "A") else {
            return
        }
        
        guard let b: Double = self.value(forInput: "B") else {
            return
        }
        
        guard let calc: CKCalculator = self.token(named: "Calculator") as? CKCalculator else {
            return
        }
        
        // do the subtraction!
        let difference = calc.subtract(a, b)
        
        // save the result
        self.store(difference, forYieldIndex: 0)
    }
}

// MARK: - CKMultiply

public class CKMultiply: ExecutableAction {
    public override func main() {
        // get our inputs
        guard let a: Double = self.value(forInput: "A") else {
            return
        }
        
        guard let b: Double = self.value(forInput: "B") else {
            return
        }
        
        guard let calc: CKCalculator = self.token(named: "Calculator") as? CKCalculator else {
            return
        }
        
        // do the multiplication!
        let product = calc.multiply(a, b)
        
        // save the result
        self.store(product, forYieldIndex: 0)
    }
}

// MARK: - CKDivide

public class CKDivide: ExecutableAction {
    public override func main() {
        // get our inputs
        guard let a: Double = self.value(forInput: "A") else {
            return
        }
        
        guard let b: Double = self.value(forInput: "B") else {
            return
        }
        
        guard let calc: CKCalculator = self.token(named: "Calculator") as? CKCalculator else {
            return
        }
        
        // do the division!
        let quotient = calc.divide(a, b)
        
        // save the result
        self.store(quotient, forYieldIndex: 0)
    }
}

// MARK: - CKPrimeSieve

struct PrimeList: Codable {
    var primes: [Int] = []
}

class CKPrimeSieve: ExecutableAction {
    var primeList = PrimeList()
    
    public override func main() {
        // get the sieve token
        guard let sieve: CKSieveOfEratosthenes = self.token(named: "Sieve") as? CKSieveOfEratosthenes else {
            return
        }
        
        // generate primes from the sieve until the cows come home
        repeat {
            let next = sieve.nextPrime()
            self.primeList.primes.append(next)
        } while !isCancelled
    }
    
    public override func cancel() {
        // yield
        self.store(primeList, forYieldIndex: 0)
    }
}

// MARK: - CKDoesNotCompute

enum CKCalculatorError: Error {
    case doesNotCompute
}

class CKDoesNotCompute: ExecutableAction {
    public override func main() {
        // sleep for 3 seconds
        Thread.sleep(forTimeInterval: 3)
        
        // oh noes our calculator blew up!
        self.emergencyStop(error: CKCalculatorError.doesNotCompute)
    }
    
    public override func cancel() {
        // nothing to cancel
    }
}

// MARK: - CKCalculator

protocol CKCalculator {
    func add(_ lhs: Double, _ rhs: Double) -> Double
    func subtract(_ lhs: Double, _ rhs: Double) -> Double
    func multiply(_ lhs: Double, _ rhs: Double) -> Double
    func divide(_ lhs: Double, _ rhs: Double) -> Double
}

class CKFastCalculator: ExecutableToken, CKCalculator {
    func add(_ lhs: Double, _ rhs: Double) -> Double {
        return lhs + rhs
    }
    
    func subtract(_ lhs: Double, _ rhs: Double) -> Double {
        return lhs - rhs
    }
    
    func multiply(_ lhs: Double, _ rhs: Double) -> Double {
        return lhs * rhs
    }
    
    func divide(_ lhs: Double, _ rhs: Double) -> Double {
        return lhs / rhs
    }
    
    override func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void)) {
        // we're done
        completion(.success)
    }
}

class CKSlowCalculator: ExecutableToken, CKCalculator {
    public var delay: TimeInterval = 3
    
    func add(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: self.delay)
        return lhs + rhs
    }
    
    func subtract(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: self.delay)
        return lhs - rhs
    }
    
    func multiply(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: self.delay)
        return lhs * rhs
    }
    
    func divide(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: self.delay)
        return lhs / rhs
    }
    
    override func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void)) {
        // sleep for `delay`, pretending like we're stopping something
        Thread.sleep(forTimeInterval: delay)
        
        // we're done
        completion(.success)
    }
}

// MARK: - CKSieveOfEratosthenes

class CKSieveOfEratosthenes: ExecutableToken {
    // swiftlint:disable variable_name
    private struct EratosthenesIterator: IteratorProtocol {
        let n: Int
        var composite: [Bool]
        var current = 2
        
        init(upTo n: Int) {
            self.n = n
            self.composite = [Bool](repeating: false, count: n + 1)
        }
        
        mutating func next() -> Int? {
            while current <= self.n {
                if !composite[current] {
                    let prime = current
                    for multiple in stride(from: current * current, through: self.n, by: current) {
                        composite[multiple] = true
                    }
                    current += 1
                    return prime
                }
                current += 1
            }
            return nil
        }
    }
    // swiftlint:enable variable_name
    
    private var sieve = EratosthenesIterator(upTo: 10_000_000)
    private var primes: [Int] = []
    
    func nextPrime() -> Int {
        guard let next = sieve.next() else {
            if let last = primes.last {
                return last
            } else {
                return 2
            }}
        primes.append(next)
        return next
    }
    
    // used for testing emergencyStop()
    var emergencyStopError: Error?
    override func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void)) {
        if let error = errors.first {
            self.emergencyStopError = error
        }
        completion(.success)
    }
}
