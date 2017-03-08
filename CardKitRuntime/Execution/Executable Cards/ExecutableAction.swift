//
//  ExecutableAction.swift
//  CardKit Runtime
//
//  Created by Justin Weisz on 7/28/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import Freddy
import CardKit

/// ExecutableAction performs the actual, executable action of an ActionCard. This class is meant to
/// be subclassed. Subclasses must override the main() method to provide their executable functioanlity.
/// This method will be called on a background thread so operations used by this method may block if desired,
/// without blocking the main app thread. This method may also spawn additional background threads, e.g.
/// using dispatch_async(). However, upon return of main(), the ExecutionEngine will consider this card
/// as having finished its execution. Therefore, you may need to block returning until background threads have
/// completed executing, e.g. using dispatch_semaphore_wait or dispatch_group_wait or other mechanics.
/// In the event that a Hand becomes satisfied while ExecutableActions are still executing, the ExecutionEngine
/// will cancel all other operations in its queue. Therefore, an ExecutableAction may wish to override
/// cancel() in order to perform cleanup or free resources.
open class ExecutableAction: Operation {
    // these are "inputs" to the ExecutableAction
    // note that inputBindings and tokenBindings will be set by DeckExecutor based on
    // the bindings present in actionCard -- e.g. when calling init() with an ActionCard
    // that has bound inputs, inputBindings will remain nil until DeckExecutor copies
    // those bindings in. which means, when writing tests that don't use DeckExecutor, 
    // don't bind inputs to the ActionCard, bind them to the ExecutableAction via
    // setup()
    public var actionCard: ActionCard
    var inputBindings: InputBindings = [:]
    var tokenBindings: TokenBindings = [:]
    
    // these are "outputs" from the ExecutableAction
    var yieldData: [YieldData] = []
    public var errors: [Error] = []
    
    // this is 'required' so we can instantiate it from the metatype
    required public init(with card: ActionCard) {
        self.actionCard = card
    }
    
    // MARK: Operation
    
    open override func main() {
        // subclasses must override main() to perform their executable actions
        fatalError("main() method cannot be executed on ExecutableAction, it must be overridden in a subclass")
    }
    
    open override func cancel() {
        // subclasses should override cancel() in order to clean up / free resources
        // no fatalError() here in case a subclass doesn't override this (maybe they don't need to do anything)
    }
}

// MARK: CarriesActionCardState

extension ExecutableAction: CarriesActionCardState {
    public func error(_ error: Error) {
        self.errors.append(error)
    }
    
    /// Convenience method for setting up input and token bindings. Used for setting up an ExecutableToken
    /// outside the context of the ExecutionEngine (e.g. for running tests).
    public func setup(inputBindings: InputBindings, tokenBindings: TokenBindings) {
        self.inputBindings = inputBindings
        self.tokenBindings = tokenBindings
    }
    
    /// Convenience method for setting up input and token bindings. Used for setting up an ExecutableToken
    /// outside the context of the ExecutionEngine (e.g. for running tests).
    public func setup(inputBindings: [String : JSONEncodable], tokenBindings: [String : ExecutableToken]) {
        // bind inputs
        for (slotName, encodable) in inputBindings {
            // silently ignore slots that don't exist
            guard let slot = self.actionCard.inputSlots.slot(named: slotName) else { continue }
            
            // convert to a DataBinding & bind it
            self.inputBindings[slot] = .bound(encodable.toJSON())
        }
        
        // bind tokens
        for (slotName, binding) in tokenBindings {
            // silently ignore slots that don't exist
            guard let slot = self.actionCard.tokenSlots.slot(named: slotName) else { continue }
            self.tokenBindings[slot] = binding
        }
    }
    
    public func binding(forInput name: String) -> DataBinding? {
        guard let slot = self.actionCard.descriptor.inputSlots.slot(named: name) else { return nil }
        return self.inputBindings[slot]
    }
    
    /// Obtain the bound value for the given input slot. Returns the bound value or nil if an
    /// error occurred, such as if a slot with the given name is not found or if the bound value
    /// is not convertible to the expected type T. The error is stored in self.error.
    public func value<T>(forInput name: String) -> T? where T : JSONDecodable {
        guard let binding = self.binding(forInput: name) else {
            self.error(ActionExecutionError.unboundInputSlot(self, name))
            return nil
        }
        guard case let .bound(json) = binding else {
            self.error(ActionExecutionError.nilValueForInput(self, name))
            return nil
        }
        
        // convert type JSON to type T
        do {
            let val = try T(json: json)
            return val
        } catch {
            self.error(ActionExecutionError.boundInputNotConvertibleToExpectedType(self, name, json, T.self))
            return nil
        }
    }
    
    /// Obtain the bound value for the given input slot. Returns nil if the slot is not found,
    /// if the slot is unbound, or if the value in the slot is not convertible to the expected
    /// type T.
    public func optionalValue<T>(forInput name: String) -> T? where T : JSONDecodable {
        // don't use self.value(forInput:) here because it may set an error that we don't really
        // want; e.g. if we are requesting the value for an optional input which isn't bound,
        // we do not want to self.error(.expectedInputSlotNotBound).
        guard let binding = self.binding(forInput: name) else { return nil }
        guard case let .bound(json) = binding else { return nil }
        
        // convert type JSON to type T
        do {
            let val = try T(json: json)
            return val
        } catch {
            return nil
        }
    }
    
    /// Obtain the bound token for the given token slot. Returns nil if a slot
    /// with the given name is not found, or if the token slot is unbound. The error
    /// is stored in self.error.
    public func token<T>(named name: String) -> T? where T : ExecutableToken {
        guard let slot = self.actionCard.tokenSlots.slot(named: name) else {
            self.error(ActionExecutionError.expectedTokenSlotNotFound(self, name))
            return nil
        }
        
        guard let token = self.tokenBindings[slot] as? T else {
            self.error(ActionExecutionError.unboundTokenSlot(self, slot))
            return nil
        }
        
        return token
    }
    
    /// Retrieve a Yield by its index (e.g. 1st yield, 2nd yield, etc.)
    /// Useful because Yields are not named like Inputs are named.
    public func yield(atIndex index: Int) -> Yield? {
        guard index < self.actionCard.yields.count else {
            self.error(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return nil
        }
        return self.actionCard.yields[index]
    }
    
    /// Store the given data as a Yield of this card.
    public func store<T>(data: T, forYield yield: Yield) where T : JSONEncodable {
        // make sure the given Yield exists for this card
        guard self.actionCard.yields.contains(yield) else {
            self.error(ActionExecutionError.attemptToStoreDataForInvalidYield(self, yield, data.toJSON()))
            return
        }
        
        // make sure the data types match
        guard yield.matchesType(of: data) else {
            let dataType = String(describing: type(of: data))
            self.error(ActionExecutionError.attemptToStoreDataOfUnexpectedType(self, yield, yield.type, dataType))
            return
        }
        
        // capture the yielded data
        let newYield = YieldData(cardIdentifier: self.actionCard.identifier, yield: yield, data: data.toJSON())
        self.yieldData.append(newYield)
    }
    
    /// Store the given data as a Yield of this card in the Yield with the given index.
    public func store<T>(data: T, forYieldIndex index: Int) where T : JSONEncodable {
        guard let yield = self.yield(atIndex: index) else {
            self.error(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return
        }
        
        // capture the yielded data
        self.store(data: data, forYield: yield)
    }
    
    /// Retrieve the data for the given yield.
    public func value<T>(forYield yield: Yield) -> T? where T : JSONDecodable {
        // if the given yield is not a valid yield for this card, return nil
        guard self.actionCard.yields.contains(yield) else {
            self.error(ActionExecutionError.attemptToRetrieveDataForInvalidYield(self, yield))
            return nil
        }
        
        // if the yield is not bound, then just return nil (this is not necessarily an error
        // because the yield may not have been produced yet)
        guard let yieldData = self.yieldData.filter({ $0.yield == yield }).first else {
            return nil
        }
        
        // convert type JSON to type T
        do {
            let val = try T(json: yieldData.data)
            return val
        } catch {
            self.error(ActionExecutionError.boundYieldNotConvertibleToExpectedType(self, yield, yieldData.data, T.self))
            return nil
        }
    }
    
    /// Retrieve the data for the yield specified by the given index.
    public func value<T>(forYieldIndex index: Int) -> T? where T : JSONDecodable {
        guard let yield = self.yield(atIndex: index) else {
            self.error(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return nil
        }
        
        // retrieve the yielded data
        return self.value(forYield: yield)
    }
}

extension ExecutableAction: SignalsEmergencyStop {
    /// `ExecutableAction` subclasses should call this method from `main()` to trigger
    /// an Emergency Stop event. This event will cascade up to the DeckExecutor, triggering a hand
    /// satisfaction check, and then an error check. When the DeckExecutor sees an
    /// `ActionExecutionError.emergencyStop`, it will cancel execution of all other cards in the 
    /// hand, and trigger `emergencyStop()` calls for all of its `tokenInstances`. Calling 
    /// `emergencyStop()` will result in a call to `cancel()`, hence, do not call this
    /// method from `cancel()`.
    public func emergencyStop(errors: [Error]) {
        // request the emergency stop by storing the errors and cancelling the operation.
        // this will trigger the 'done' satisfaction check and test for errors.
        errors.forEach { self.error(ActionExecutionError.emergencyStop($0)) }
        self.cancel()
    }
}
