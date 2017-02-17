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

public typealias InputBindings = [InputSlot : DataBinding]
public typealias TokenBindings = [TokenSlot : ExecutableTokenCard]
public typealias YieldBindings = [Yield : DataBinding]

/// Appled to classes that implement an executable ActionCard
protocol CarriesActionCardState {
    func setup(inputBindings: InputBindings, tokenBindings: TokenBindings)
    
    /// This is the ActionCard instance carrying all of the binding data for inputs and yields. This is an input.
    var actionCard: ActionCard { get }
    
    /// The specific Input data bound to the card. This is an input.
    var inputBindings: InputBindings { get }
    
    /// The Tokens bound to the card. This is an input.
    var tokenBindings: TokenBindings { get }
    
    /// These are the yields produced by the card. This is an output.
    var yieldBindings: YieldBindings { get }
    
    /// This holds any errors produced during execution. This is an output.
    var errors: [Error] { get }
    
    /// Retrieve the input binding for the named slot
    func binding(forInput name: String) -> DataBinding?
    
    /// Retrieve the input value for the named slot
    func value<T>(forInput name: String) -> T? where T : JSONDecodable
    
    /// Retrieve the input value for the named slot, or nil if the slot is unbound
    func optionalValue<T>(forInput name: String) -> T? where T : JSONDecodable
    
    /// Retrieve the token for the named slot
    func token<T>(named name: String) -> T? where T : ExecutableTokenCard
    
    /// Retrieve a Yield by its index (e.g. 1st yield, 2nd yield, etc.)
    /// Useful because Yields are not named like Inputs are named.
    func yield(atIndex index: Int) -> Yield?
    
    /// Store yielded data
    func store<T>(data: T, forYield yield: Yield) where T : JSONEncodable
    func store<T>(data: T, forYieldIndex index: Int) where T : JSONEncodable
    
    /// Retrieve yielded data
    func value<T>(forYield yield: Yield) -> T? where T : JSONDecodable
    func value<T>(forYieldIndex index: Int) -> T? where T : JSONDecodable
}
