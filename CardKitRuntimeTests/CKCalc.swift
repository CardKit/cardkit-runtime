//
//  CKCalc.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

// swiftlint:disable nesting

import Foundation

import Freddy

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
        self.store(data: sum, forYieldIndex: 0)
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
        self.store(data: difference, forYieldIndex: 0)
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
        self.store(data: product, forYieldIndex: 0)
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
        self.store(data: quotient, forYieldIndex: 0)
    }
}

// MARK: - CKPrimeSieve

struct PrimeList: JSONEncodable, JSONDecodable {
    var primes: [Int] = []
    
    init() {
    }
    
    init(json: JSON) throws {
        self.primes = try json.decodedArray(at: "primes", type: Int.self)
    }
    
    func toJSON() -> JSON {
        return .dictionary([
            "primes": primes.toJSON()
            ])
    }
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
        self.store(data: primeList, forYieldIndex: 0)
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
}
