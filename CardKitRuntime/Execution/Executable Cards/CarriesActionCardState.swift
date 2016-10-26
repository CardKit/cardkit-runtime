//
//  CarriesActionCardState.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import Freddy
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
    var error: Error? { get }
    
    /// Retrieve the input binding for the named slot
    func binding(forInput name: String) -> InputDataBinding?
    
    /// Retrieve the input value for the named slot
    func value<T>(forInput name: String) -> T? where T : JSONDecodable
    
    /// Retrieve the input value for the named slot, or nil if the slot is unbound
    func optionalValue<T>(forInput name: String) -> T? where T : JSONDecodable
    
    /// Retrieve the token for the named slot
    func token<T>(named name: String) -> T? where T : ExecutableTokenCard
}
