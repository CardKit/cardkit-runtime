//
//  CarriesActionCardState.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public typealias InputBindings = [InputSlot: Data]
public typealias TokenBindings = [TokenSlot: ExecutableToken]

/// Carries data yielded by an ActionCard.
public struct YieldData {
    public let cardIdentifier: CardIdentifier
    public let yield: Yield
    public let data: Data
}

/// Appled to classes that implement an executable ActionCard
protocol CarriesActionCardState {
    /// This is the ActionCard instance carrying all of the binding data for inputs and yields. This is an input.
    var actionCard: ActionCard { get }
    
    /// The specific Input data bound to the card. This is an input.
    /// Input bindings should be set via one of the setup() methods.
    var inputBindings: InputBindings { get }
    
    /// The Tokens bound to the card. This is an input.
    /// Token bindings should be set via one of the setup() methods.
    var tokenBindings: TokenBindings { get }
    
    /// These are the yields produced by the card. This is an output.
    /// Yields should be accessed via the yield(atIndex:) method.
    var yieldData: [YieldData] { get }
    
    /// This holds any errors produced during execution. This is an output.
    var errors: [Error] { get }
    
    /// Store the given error. Any error encountered should be stored using this method.
    func error(_ error: Error)
    
    /// Set the card up with the given input and token bindings, given via mappings between
    /// the String slot names and the Codable object to be bound. Keys that don't match any
    /// available slots will be ignored.
    func setup(inputBindings: [String: Codable], tokenBindings: [String: ExecutableToken])
    
    /// Retrieve the input value for the named slot, or nil if the slot is unbound.
    /// Stores an error if the input slot is unbound or if the expected type does not
    /// match the type of the stored data.
    func value<T>(forInput name: String) -> T? where T: Codable
    
    /// Retrieve the input value for the named slot, or nil if the slot is unbound.
    /// Does not store an error if the input slot is unbound or if the expected type
    /// does not match the type of the stored data.
    func optionalValue<T>(forInput name: String) -> T? where T: Codable
    
    /// Retrieve the token for the named slot
    func token<T>(named name: String) -> T? where T: ExecutableToken
    
    /// Retrieve a Yield by its index (e.g. 1st yield, 2nd yield, etc.)
    /// Useful because Yields are not named like Inputs are named.
    func yield(atIndex index: Int) -> Yield?
    
    /// Store yielded data
    func store<T>(_ object: T, forYield yield: Yield) where T: Codable
    func store<T>(_ object: T, forYieldIndex index: Int) where T: Codable
    
    /// Retrieve yielded data
    func value<T>(forYield yield: Yield) -> T? where T: Codable
    func value<T>(forYieldIndex index: Int) -> T? where T: Codable
}
