//
//  CarriesActionCardState.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public typealias InputBindings = [InputSlot : InputDataBinding]
public typealias TokenBindings = [TokenSlot : ExecutableTokenCard]
public typealias YieldBindings = [Yield : InputDataBinding]

/// Appled to classes that implement an executable ActionCard
protocol CarriesActionCardState {
    func setup(_ inputs: InputBindings, tokens: TokenBindings)
    
    /// This is the ActionCard instance carrying all of the binding data for inputs and yields. This is an input.
    var actionCard: ActionCard { get }
    
    /// The specific Input data bound to the card. This is an input.
    var inputs: InputBindings { get }
    
    /// The Tokens bound to the card. This is an input.
    var tokens: TokenBindings { get }
    
    /// These are the yields produced by the card. This is an output.
    var yields: YieldBindings { get }
    
    /// This holds an error produced during execution. This is an output.
    var error: ActionExecutionError? { get }
    
    /// Retrieve the input value for the named slot
    func valueForInput(named name: String) -> InputDataBinding?
}
