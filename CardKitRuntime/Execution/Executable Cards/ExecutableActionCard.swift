//
//  ExecutableActionCard.swift
//  CardKit Runtime
//
//  Created by Justin Weisz on 7/28/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import Freddy
import CardKit

/// ExecutableActionCard performs the actual, executable action of an ActionCard. This class is meant to
/// be subclassed. Subclasses must override the main() method to provide their executable functioanlity.
/// This method will be called on a background thread so operations used by this method may block if desired,
/// without blocking the main app thread. This method may also spawn additional background threads, e.g.
/// using dispatch_async(). However, upon return of main(), the ExecutionEngine will consider this card
/// as having finished its execution. Therefore, you may need to block returning until background threads have
/// completed executing, e.g. using dispatch_semaphore_wait or dispatch_group_wait or other mechanics.
/// In the event that a Hand becomes satisfied while ExecutableActionCards are still executing, the ExecutionEngine
/// will cancel all other operations in its queue. Therefore, an ExecutableActionCard may wish to override
/// cancel() in order to perform cleanup or free resources.
open class ExecutableActionCard: Operation, CarriesActionCardState {
    // these are "inputs" to the ExecutableActionCard
    var actionCard: ActionCard
    var inputs: InputBindings = [:]
    var tokens: TokenBindings = [:]
    
    // these are "outputs" from the ExecutableActionCard
    open var yields: YieldBindings = [:]
    open var error: Error?
    
    // this is 'required' so we can instantiate it from the metatype
    required public init(with card: ActionCard) {
        self.actionCard = card
    }
    
    // MARK: CarriesActionCardState
    
    func setup(_ inputs: InputBindings, tokens: TokenBindings) {
        self.inputs = inputs
        self.tokens = tokens
    }
    
    public func binding(forInput name: String) -> InputDataBinding? {
        guard let slot = self.actionCard.descriptor.inputSlots.slot(named: name) else { return nil }
        return self.inputs[slot]
    }
    
    /// Obtain the bound value for the given input slot. Returns the bound value or nil if an
    /// error occurred, such as if a slot with the given name is not found or if the bound value
    /// is not convertible to the expected type T. The error is stored in self.error.
    public func value<T>(forInput name: String) -> T? where T : JSONDecodable {
        guard let binding = self.binding(forInput: name) else {
            self.error = ActionExecutionError.expectedInputSlotNotFound(self, name)
            return nil
        }
        guard case let .bound(json) = binding else {
            self.error = ActionExecutionError.nilValueForInput(self, name)
            return nil
        }
        
        // convert type JSON to type T
        do {
            let val = try T(json: json)
            return val
        } catch {
            self.error = ActionExecutionError.boundInputNotConvertibleToExpectedType(self, name, json, T.self)
            return nil
        }
    }
    
    /// Obtain the bound value for the given input slot. Returns nil if the slot is not found,
    /// if the slot is unbound, or if the value in the slot is not convertible to the expected
    /// type T.
    public func optionalValue<T>(forInput name: String) -> T? where T : JSONDecodable {
        guard let value: T = self.value(forInput: name) else {
            return nil
        }
        
        return value
    }
    
    /// Obtain the bound token for the given token slot. Returns nil if a slot
    /// with the given name is not found, or if the token slot is unbound. The error
    /// is stored in self.error.
    public func token<T>(named name: String) -> T? where T : ExecutableTokenCard {
        guard let slot = self.actionCard.tokenSlots.slot(named: name) else {
            self.error = ActionExecutionError.expectedTokenSlotNotFound(self, name)
            return nil
        }
        
        guard let token = self.tokens[slot] as? T else {
            self.error = ActionExecutionError.unboundTokenSlot(self, slot)
            return nil
        }
        
        return token
    }
    
    // MARK: Operation
    
    open override func main() {
        // subclasses must override main() to perform their executable actions
        fatalError("main() method cannot be executed on ExecutableActionCard, it must be overridden in a subclass")
    }
    
    open override func cancel() {
        // subclasses should override cancel() in order to clean up / free resources
        fatalError("cancel() method cannot be executed on ExecutabletionCa")
    }
}
