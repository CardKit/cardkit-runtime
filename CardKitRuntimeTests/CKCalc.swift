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
    private init() {}
    
    //MARK:- Action Cards
    
    /// Contains descriptors for Action cards
    public struct Action {
        private init() {}
        
        /// Contains descriptors for Math cards
        public struct Math {
            private init() {}
            
            //MARK: Add
            /// Descriptor for Add card
            public static let Add = ActionCardDescriptor(
                name: "Add",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", type: .SwiftDouble, isOptional: false),
                    InputSlot(name: "B", type: .SwiftDouble, isOptional: false)
                ],
                tokens: [TokenSlot(identifier: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: .SwiftDouble)],
                yieldDescription: "The sum A + B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
            //MARK: Subtract
            /// Descriptor for Subtract card
            public static let Subtract = ActionCardDescriptor(
                name: "Subtract",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", type: .SwiftDouble, isOptional: false),
                    InputSlot(name: "B", type: .SwiftDouble, isOptional: false)
                ],
                tokens: [TokenSlot(identifier: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: .SwiftDouble)],
                yieldDescription: "The difference A - B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
            //MARK: Multiply
            /// Descriptor for Multiply card
            public static let Multiply = ActionCardDescriptor(
                name: "Multiply",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", type: .SwiftDouble, isOptional: false),
                    InputSlot(name: "B", type: .SwiftDouble, isOptional: false)
                ],
                tokens: [TokenSlot(identifier: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: .SwiftDouble)],
                yieldDescription: "The multiplication A * B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
            
            //MARK: Divide
            /// Descriptor for Divide card
            public static let Divide = ActionCardDescriptor(
                name: "Divide",
                subpath: "Math",
                inputs: [
                    InputSlot(name: "A", type: .SwiftDouble, isOptional: false),
                    InputSlot(name: "B", type: .SwiftDouble, isOptional: false)
                ],
                tokens: [TokenSlot(identifier: "Calculator", descriptor: CKCalc.Token.Calculator)],
                yields: [Yield(type: .SwiftDouble)],
                yieldDescription: "The division A / B",
                ends: true,
                endsDescription: "Ends when the computation is complete.",
                assetCatalog: CardAssetCatalog(description: "No action performed."),
                version: 0)
        }
    }
    
    //MARK:- Token Cards
    
    /// Contains descriptors for Token cards
    public struct Token {
        private init() {}
        
        public static let Calculator = TokenCardDescriptor(
            name: "Calculator",
            subpath: nil,
            isConsumed: false,
            assetCatalog: CardAssetCatalog(),
            version: 0)
    }
}

public class CKAdd: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .NilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .NilValueForInput(self, "B")
            return
        }
        guard case let .SwiftDouble(a) = bindingA else {
            self.error = .TypeMismatchForInput(self, "A", .SwiftDouble, bindingA)
            return
        }
        guard case let .SwiftDouble(b) = bindingB else {
            self.error = .TypeMismatchForInput(self, "B", .SwiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .ExpectedYieldNotFound(self)
            return
        }
        
        // do the addition!
        let sum = a + b
        
        // save the result
        self.yields[yield] = .SwiftDouble(sum)
    }
}

public class CKSubtract: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .NilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .NilValueForInput(self, "B")
            return
        }
        guard case let .SwiftDouble(a) = bindingA else {
            self.error = .TypeMismatchForInput(self, "A", .SwiftDouble, bindingA)
            return
        }
        guard case let .SwiftDouble(b) = bindingB else {
            self.error = .TypeMismatchForInput(self, "B", .SwiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .ExpectedYieldNotFound(self)
            return
        }
        
        // do the subtraction!
        let difference = a - b
        
        // save the result
        self.yields[yield] = .SwiftDouble(difference)
    }
}

public class CKMultiply: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .NilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .NilValueForInput(self, "B")
            return
        }
        guard case let .SwiftDouble(a) = bindingA else {
            self.error = .TypeMismatchForInput(self, "A", .SwiftDouble, bindingA)
            return
        }
        guard case let .SwiftDouble(b) = bindingB else {
            self.error = .TypeMismatchForInput(self, "B", .SwiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .ExpectedYieldNotFound(self)
            return
        }
        
        // do the multiplication!
        let product = a * b
        
        // save the result
        self.yields[yield] = .SwiftDouble(product)
    }
}

public class CKDivide: ExecutableActionCard {
    public override func main() {
        // get our inputs
        guard let bindingA = self.valueForInput(named: "A") else {
            self.error = .NilValueForInput(self, "A")
            return
        }
        guard let bindingB = self.valueForInput(named: "B") else {
            self.error = .NilValueForInput(self, "B")
            return
        }
        guard case let .SwiftDouble(a) = bindingA else {
            self.error = .TypeMismatchForInput(self, "A", .SwiftDouble, bindingA)
            return
        }
        guard case let .SwiftDouble(b) = bindingB else {
            self.error = .TypeMismatchForInput(self, "B", .SwiftDouble, bindingB)
            return
        }
        
        guard let yield = self.actionCard.descriptor.yields.first else {
            self.error = .ExpectedYieldNotFound(self)
            return
        }
        
        // do the division!
        let quotient = a / b
        
        // save the result
        self.yields[yield] = .SwiftDouble(quotient)
    }
}
