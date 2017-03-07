//
//  CKCalc.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

@testable import CardKit
@testable import CardKitRuntime

// swiftlint:disable nesting
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
                assetCatalog: CardAssetCatalog(description: "No action performed."))
            
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
                assetCatalog: CardAssetCatalog(description: "No action performed."))
            
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
                assetCatalog: CardAssetCatalog(description: "No action performed."))
            
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
                assetCatalog: CardAssetCatalog(description: "No action performed."))
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
    func add(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: 5)
        return lhs + rhs
    }
    
    func subtract(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: 5)
        return lhs - rhs
    }
    
    func multiply(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: 5)
        return lhs * rhs
    }
    
    func divide(_ lhs: Double, _ rhs: Double) -> Double {
        Thread.sleep(forTimeInterval: 5)
        return lhs / rhs
    }
}
