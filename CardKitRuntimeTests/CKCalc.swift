//
//  CKCalc.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
@testable import CardKit

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
                yields: [Yield(type: .swiftDouble)],
                yieldDescription: "The sum A + B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
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
                yields: [Yield(type: .swiftDouble)],
                yieldDescription: "The difference A - B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
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
                yields: [Yield(type: .swiftDouble)],
                yieldDescription: "The multiplication A * B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
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
                yields: [Yield(type: .swiftDouble)],
                yieldDescription: "The division A / B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
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
            assetCatalog: CardAssetCatalog(),
            version: 0)
    }
}

// MARK: - CKAdd

public class CKAdd: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .nilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .nilValueForInput(self, "B")
            return
        }
        guard case let .swiftDouble(a) = bindingA else {
            self.error = .typeMismatchForInput(self, "A", .swiftDouble, bindingA)
            return
        }
        guard case let .swiftDouble(b) = bindingB else {
            self.error = .typeMismatchForInput(self, "B", .swiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .expectedYieldNotFound(self)
            return
        }
        
        guard let calcSlot = self.actionCard.tokenSlots.slot(named: "Calculator") else {
            self.error = .expectedTokenSlotNotFound(self, "Calculator")
            return
        }
        
        guard let calc = self.tokens[calcSlot] as? CKCalculator else {
            self.error = .unboundTokenSlot(self, calcSlot)
            return
        }
        
        // do the addition!
        let sum = calc.add(a, b)
        
        // save the result
        self.yields[yield] = .swiftDouble(sum)
    }
}

// MARK: - CKSubtract

public class CKSubtract: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .nilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .nilValueForInput(self, "B")
            return
        }
        guard case let .swiftDouble(a) = bindingA else {
            self.error = .typeMismatchForInput(self, "A", .swiftDouble, bindingA)
            return
        }
        guard case let .swiftDouble(b) = bindingB else {
            self.error = .typeMismatchForInput(self, "B", .swiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .expectedYieldNotFound(self)
            return
        }
        
        guard let calcSlot = self.actionCard.tokenSlots.slot(named: "Calculator") else {
            self.error = .expectedTokenSlotNotFound(self, "Calculator")
            return
        }
        
        guard let calc = self.tokens[calcSlot] as? CKCalculator else {
            self.error = .unboundTokenSlot(self, calcSlot)
            return
        }
        
        // do the subtraction!
        let difference = calc.subtract(a, b)
        
        // save the result
        self.yields[yield] = .swiftDouble(difference)
    }
}

// MARK: - CKMultiply

public class CKMultiply: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .nilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .nilValueForInput(self, "B")
            return
        }
        guard case let .swiftDouble(a) = bindingA else {
            self.error = .typeMismatchForInput(self, "A", .swiftDouble, bindingA)
            return
        }
        guard case let .swiftDouble(b) = bindingB else {
            self.error = .typeMismatchForInput(self, "B", .swiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .expectedYieldNotFound(self)
            return
        }
        
        guard let calcSlot = self.actionCard.tokenSlots.slot(named: "Calculator") else {
            self.error = .expectedTokenSlotNotFound(self, "Calculator")
            return
        }
        
        guard let calc = self.tokens[calcSlot] as? CKCalculator else {
            self.error = .unboundTokenSlot(self, calcSlot)
            return
        }
        
        // do the multiplication!
        let product = calc.multiply(a, b)
        
        // save the result
        self.yields[yield] = .swiftDouble(product)
    }
}


// MARK: - CKDivide

public class CKDivide: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .nilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .nilValueForInput(self, "B")
            return
        }
        guard case let .swiftDouble(a) = bindingA else {
            self.error = .typeMismatchForInput(self, "A", .swiftDouble, bindingA)
            return
        }
        guard case let .swiftDouble(b) = bindingB else {
            self.error = .typeMismatchForInput(self, "B", .swiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .expectedYieldNotFound(self)
            return
        }
        
        guard let calcSlot = self.actionCard.tokenSlots.slot(named: "Calculator") else {
            self.error = .expectedTokenSlotNotFound(self, "Calculator")
            return
        }
        
        guard let calc = self.tokens[calcSlot] as? CKCalculator else {
            self.error = .unboundTokenSlot(self, calcSlot)
            return
        }
        
        // do the division!
        let quotient = calc.divide(a, b)
        
        // save the result
        self.yields[yield] = .swiftDouble(quotient)
    }
}

// MARK: - CKCalculator

protocol CKCalculator {
    func add(_ lhs: Double, _ rhs: Double) -> Double
    func subtract(_ lhs: Double, _ rhs: Double) -> Double
    func multiply(_ lhs: Double, _ rhs: Double) -> Double
    func divide(_ lhs: Double, _ rhs: Double) -> Double
}

class CKFastCalculator: ExecutableTokenCard, CKCalculator {
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

class CKSlowCalculator: ExecutableTokenCard, CKCalculator {
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
