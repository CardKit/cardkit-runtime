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
    public var actionCard: ActionCard
    var inputBindings: InputBindings = [:]
    var tokenBindings: TokenBindings = [:]
    
    // these are "outputs" from the ExecutableActionCard
    var yieldBindings: YieldBindings = [:]
    var errors: [Error] = []
    
    // this is 'required' so we can instantiate it from the metatype
    required public init(with card: ActionCard) {
        self.actionCard = card
    }
    
    // MARK: CarriesActionCardState
    
    func setup(inputBindings: InputBindings, tokenBindings: TokenBindings) {
        self.inputBindings = inputBindings
        self.tokenBindings = tokenBindings
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
            self.errors.append(ActionExecutionError.expectedInputSlotNotFound(self, name))
            return nil
        }
        guard case let .bound(json) = binding else {
            self.errors.append(ActionExecutionError.nilValueForInput(self, name))
            return nil
        }
        
        // convert type JSON to type T
        do {
            let val = try T(json: json)
            return val
        } catch {
            self.errors.append(ActionExecutionError.boundInputNotConvertibleToExpectedType(self, name, json, T.self))
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
            self.errors.append(ActionExecutionError.expectedTokenSlotNotFound(self, name))
            return nil
        }
        
        guard let token = self.tokenBindings[slot] as? T else {
            self.errors.append(ActionExecutionError.unboundTokenSlot(self, slot))
            return nil
        }
        
        return token
    }
    
    /// Retrieve a Yield by its index (e.g. 1st yield, 2nd yield, etc.)
    /// Useful because Yields are not named like Inputs are named.
    public func yield(atIndex index: Int) -> Yield? {
        if index > self.actionCard.yields.count {
            self.errors.append(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return nil
        }
        return self.actionCard.yields[index]
    }
    
    /// Store the given data as a Yield of this card.
    public func store<T>(data: T, forYield yield: Yield) where T : JSONEncodable {
        // make sure the given Yield exists for this card
        if !self.actionCard.yields.contains(yield) {
            self.errors.append(ActionExecutionError.attemptToStoreDataForInvalidYield(self, yield, data.toJSON()))
            return
        }
        
        // make sure the data types match
        if !yield.matchesType(of: data) {
            let dataType = String(describing: type(of: data))
            self.errors.append(ActionExecutionError.attemptToStoreDataOfUnexpectedType(self, yield, yield.type, dataType))
            return
        }
        
        // capture the yielded data
        self.yieldBindings[yield] = .bound(data.toJSON())
    }
    
    /// Store the given data as a Yield of this card in the Yield with the given index.
    public func store<T>(data: T, forYieldIndex index: Int) where T : JSONEncodable {
        guard let yield = self.yield(atIndex: index) else {
            self.errors.append(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return
        }
        
        // capture the yielded data
        self.store(data: data, forYield: yield)
    }
    
    /// Retrieve the data for the given yield.
    public func value<T>(forYield yield: Yield) -> T? where T : JSONDecodable {
        // if the given yield is not a valid yield for this card, return nil
        if !self.actionCard.yields.contains(yield) {
            self.errors.append(ActionExecutionError.attemptToRetrieveDataForInvalidYield(self, yield))
            return nil
        }
        
        // if the yield is not bound, then just return nil (this is not necessarily an error
        // because the yield may not have been produced yet)
        guard let binding = self.yieldBindings[yield] else {
            return nil
        }
        
        // if the yield is bound, but the value is not .bound, this is probably
        // an error
        guard case let .bound(json) = binding else {
            self.errors.append(ActionExecutionError.nilValueForYield(self, yield))
            return nil
        }
        
        // convert type JSON to type T
        do {
            let val = try T(json: json)
            return val
        } catch {
            self.errors.append(ActionExecutionError.boundYieldNotConvertibleToExpectedType(self, yield, json, T.self))
            return nil
        }
    }
    
    /// Retrieve the data for the yield specified by the given index.
    public func value<T>(forYieldIndex index: Int) -> T? where T : JSONDecodable {
        guard let yield = self.yield(atIndex: index) else {
            self.errors.append(ActionExecutionError.yieldAtIndexNotFound(self, index))
            return nil
        }
        
        // retrieve the yielded data
        return self.value(forYield: yield)
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
