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
    func setup(inputs: InputBindings, tokens: TokenBindings)
    
    /// This is the ActionCard instance carrying all of the binding data for inputs and yields
    var actionCard: ActionCard { get }
    
    /// The specific Input data bound to the card
    var inputs: InputBindings { get }
    
    /// The Tokens bound to the card
    var tokens: TokenBindings { get }
    
    /// These are the yields produced by the card.
    var yields: YieldBindings { get }
    
    /// Retrieve the input value for the named slot
    func valueForInput(named name: String) -> InputDataBinding?
}
