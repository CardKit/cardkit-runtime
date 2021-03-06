/**
 * Copyright 2018 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

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

// MARK: - CarriesActionCardState

extension ExecutableAction: CarriesActionCardState {
    public func error(_ error: Error) {
        self.errors.append(error)
    }
    
    /// Convenience method for setting up input and token bindings. Used for setting up an ExecutableToken
    /// outside the context of the ExecutionEngine (e.g. for running tests).
    public func setup(inputBindings: [String: Codable], tokenBindings: [String: ExecutableToken]) {
        // bind inputs
        for (slotName, object) in inputBindings {
            // silently ignore slots that don't exist
            guard let slot = self.actionCard.inputSlots.slot(named: slotName) else { continue }
            
            // silently ignore bindings that don't box encode
            guard let data = object.boxedEncoding() else { continue }
            
            // store the data
            self.inputBindings[slot] = data
        }
        
        // bind tokens
        for (slotName, binding) in tokenBindings {
            // silently ignore slots that don't exist
            guard let slot = self.actionCard.tokenSlots.slot(named: slotName) else { continue }
            self.tokenBindings[slot] = binding
        }
    }
    
    /// Obtain the bound value for the given input slot. Returns the bound value or nil if an
    /// error occurred, such as if a slot with the given name is not found or if the bound value
    /// is not convertible to the expected type T. The error is stored in self.error.
    public func value<T>(forInput name: String) -> T? where T: Codable {
        guard let slot = self.actionCard.descriptor.inputSlots.slot(named: name) else {
            self.error(ActionExecutionError.expectedInputSlotNotFound(self, name))
            return nil
        }
        
        guard let data = self.inputBindings[slot] else {
            self.error(ActionExecutionError.unboundInputSlot(self, name))
            return nil
        }
        
        // deserialize data
        guard let val: T = data.unboxedValue() else {
            self.error(ActionExecutionError.boundInputNotConvertibleToExpectedType(self, name, data, T.self))
            return nil
        }
        
        return val
    }
    
    /// Obtain the bound value for the given input slot. Returns nil if the slot is not found,
    /// if the slot is unbound, or if the value in the slot is not convertible to the expected
    /// type T.
    public func optionalValue<T>(forInput name: String) -> T? where T: Codable {
        // don't use self.value(forInput:) here because it may set an error that we don't really
        // want; e.g. if we are requesting the value for an optional input which isn't bound,
        // we do not want to self.error(.expectedInputSlotNotBound).
        guard let slot = self.actionCard.descriptor.inputSlots.slot(named: name) else { return nil }
        guard let data = self.inputBindings[slot] else { return nil }
        
        // deserialize data
        guard let val: T = data.unboxedValue() else { return nil }
        return val
    }
    
    /// Obtain the bound token for the given token slot. Returns nil if a slot
    /// with the given name is not found, or if the token slot is unbound. The error
    /// is stored in self.error.
    public func token<T>(named name: String) -> T? where T: ExecutableToken {
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
    
    /// Store the given object as a Yield of this card.
    public func store<T>(_ object: T, forYield yield: Yield) where T: Codable {
        // make sure the given Yield exists for this card
        guard self.actionCard.yields.contains(yield) else {
            self.error(ActionExecutionError.attemptToStoreInvalidYield(self, yield))
            return
        }
        
        // make sure the data types match
        guard yield.matchesType(of: object) else {
            let dataType = String(describing: Swift.type(of: object))
            self.error(ActionExecutionError.attemptToStoreYieldOfUnexpectedType(self, yield, yield.type, dataType))
            return
        }
        
        // box the data
        guard let data = object.boxedEncoding() else {
            let dataType = String(describing: Swift.type(of: object))
            self.error(ActionExecutionError.attemptToStoreYieldOfUnexpectedType(self, yield, yield.type, dataType))
            return
        }
        
        // capture the yielded data
        let newYield = YieldData(cardIdentifier: self.actionCard.identifier, yield: yield, data: data)
        self.yieldData.append(newYield)
    }
    
    /// Store the given object as a Yield of this card in the Yield with the given index.
    public func store<T>(_ object: T, forYieldIndex index: Int) where T: Codable {
        guard let yield = self.yield(atIndex: index) else {
            self.error(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return
        }
        
        // capture the yielded data
        self.store(object, forYield: yield)
    }
    
    /// Retrieve the object for the given yield.
    public func value<T>(forYield yield: Yield) -> T? where T: Codable {
        // if the given yield is not a valid yield for this card, return nil
        guard self.actionCard.yields.contains(yield) else {
            self.error(ActionExecutionError.attemptToRetrieveInvalidYield(self, yield))
            return nil
        }
        
        // if the yield is not bound, then just return nil (this is not necessarily an error
        // because the yield may not have been produced yet)
        guard let yieldData = self.yieldData.filter({ $0.yield == yield }).first else {
            return nil
        }
        
        // convert the boxed data to type T
        guard let val: T = yieldData.data.unboxedValue() else {
            self.error(ActionExecutionError.boundYieldNotConvertibleToExpectedType(self, yield, yieldData.data, T.self))
            return nil
        }
        
        return val
    }
    
    /// Retrieve the object for the yield specified by the given index.
    public func value<T>(forYieldIndex index: Int) -> T? where T: Codable {
        guard let yield = self.yield(atIndex: index) else {
            self.error(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return nil
        }
        
        // retrieve the yielded data
        return self.value(forYield: yield)
    }
}

// MARK: - SignalsEmergencyStop

extension ExecutableAction: SignalsEmergencyStop {
    /// `ExecutableAction` subclasses should call this method from `main()` to trigger
    /// an Emergency Stop event. This event will cascade up to the DeckExecutor, triggering a hand
    /// satisfaction check, and then an error check. When the DeckExecutor sees an
    /// `ActionExecutionError.emergencyStop`, it will cancel execution of all other cards in the 
    /// hand, and trigger `emergencyStop()` calls for all of its `tokenInstances`. Calling 
    /// `emergencyStop()` will result in a call to `cancel()`, hence, do not call this
    /// method from `cancel()`. This method is used when multiple errors trigger an emergency stop.
    public func emergencyStop(errors: [Error]) {
        // request the emergency stop by storing the errors and cancelling the operation.
        // this will trigger the 'done' satisfaction check and test for errors.
        errors.forEach { self.error(ActionExecutionError.emergencyStop($0)) }
        self.cancel()
    }
    
    /// `ExecutableAction` subclasses should call this method from `main()` to trigger
    /// an Emergency Stop event. This event will cascade up to the DeckExecutor, triggering a hand
    /// satisfaction check, and then an error check. When the DeckExecutor sees an
    /// `ActionExecutionError.emergencyStop`, it will cancel execution of all other cards in the
    /// hand, and trigger `emergencyStop()` calls for all of its `tokenInstances`. Calling
    /// `emergencyStop()` will result in a call to `cancel()`, hence, do not call this
    /// method from `cancel()`. This method is used when a single error triggers an emergency stop.
    public func emergencyStop(error: Error) {
        self.emergencyStop(errors: [error])
    }
}
