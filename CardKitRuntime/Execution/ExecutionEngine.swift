//
//  ExecutionEngine.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/17/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: ExecutionEngineDelegate

public protocol ExecutionEngineDelegate: class {
    func executionEngine(_ engine: ExecutionEngine, willValidate deck: Deck)
    func executionEngine(_ engine: ExecutionEngine, didValidate deck: Deck)
    
    func executionEngine(_ engine: ExecutionEngine, willExecute deck: Deck)
    func executionEngine(_ engine: ExecutionEngine, willExecute hand: Hand)
    func executionEngine(_ engine: ExecutionEngine, willExecute card: Card)
    
    func executionEngine(_ engine: ExecutionEngine, didExecute deck: Deck, producing yields: [Yield: YieldData]?)
    func executionEngine(_ engine: ExecutionEngine, didExecute hand: Hand, producing yields: [Yield: YieldData]?)
    func executionEngine(_ engine: ExecutionEngine, didExecute card: Card, producing yields: [Yield: YieldData]?)
    
    func executionEngine(_ engine: ExecutionEngine, hadErrors errors: [Error])
}

extension ExecutionEngineDelegate {
    func executionEngine(_ engine: ExecutionEngine, willValidate deck: Deck) {}
    func executionEngine(_ engine: ExecutionEngine, didValidate deck: Deck) {}
    
    func executionEngine(_ engine: ExecutionEngine, willExecute deck: Deck) {}
    func executionEngine(_ engine: ExecutionEngine, willExecute hand: Hand) {}
    func executionEngine(_ engine: ExecutionEngine, willExecute card: Card) {}
    
    func executionEngine(_ engine: ExecutionEngine, didExecute deck: Deck, producing yields: [Yield: YieldData]?) {}
    func executionEngine(_ engine: ExecutionEngine, didExecute hand: Hand, producing yields: [Yield: YieldData]?) {}
    func executionEngine(_ engine: ExecutionEngine, didExecute card: Card, producing yields: [Yield: YieldData]?) {}
    
    func executionEngine(_ engine: ExecutionEngine, hadErrors errors: [Error]) {}
}

// MARK: - ExecutionEngine

public class ExecutionEngine {
    public fileprivate (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    fileprivate var executableActionTypes: [ActionCardDescriptor : ExecutableAction.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    fileprivate var tokenInstances: [TokenCard : ExecutableToken] = [:]
    
    /// Queue used for running the DeckExecutor
    fileprivate let operationQueue: OperationQueue = OperationQueue()
    
    /// Execution engine delegate receives callbacks when various execution events occur,
    /// such as validation, execution, and errors.
    public weak var delegate: ExecutionEngineDelegate?
    
    public init(with deck: Deck) {
        self.deck = deck
        
        // register the CardKit descriptors with the engine
        let cardKit = CardKitCatalog()
        self.registerDescriptorCatalog(cardKit)
    }
    
    // MARK: Instance Methods
    
    /// Set the `ExecutableAction` type for a given `ActionCardDescriptor`. The preferred method for registering these
    /// types is via `registerDescriptorCatalog(_:)`, but this method exists to override a single specified type
    /// (e.g. for testing alternate implementations of an `ExecutableAction`).
    public func setExecutableActionType(_ type: ExecutableAction.Type, for descriptor: ActionCardDescriptor) {
        self.executableActionTypes[descriptor] = type
    }
    
    /// Register the card descriptor catalog with the `ExecutionEngine` so it knows which `ExecutableAction` types
    /// to instantiate for which `ActionCardDescriptors`.
    public func registerDescriptorCatalog(_ catalog: DescriptorCatalog) {
        for descriptor in catalog.descriptors {
            // only register ActionCardDescriptors
            if let actionDescriptor = descriptor as? ActionCardDescriptor {
                // make sure there is a corresponding implementation type -- if we don't have it, we will
                // ignore it here, but validation will fail
                guard let executableType = catalog.executableActionTypes[actionDescriptor] else { continue }
                
                // save the type
                self.executableActionTypes[actionDescriptor] = executableType
            }
        }
    }
    
    public func setTokenInstance(_ instance: ExecutableToken, for tokenCard: TokenCard) {
        self.tokenInstances[tokenCard] = instance
    }
    
    public func setTokenInstances(_ tokenInstances: [TokenCard : ExecutableToken]) {
        self.tokenInstances = tokenInstances
    }
    
    /// Execute the Deck
    public func execute(_ completion: @escaping ([YieldData], ExecutionError?) -> Void) {
        // create a DeckExecutor
        let deckExecutor = DeckExecutor(with: self.deck)
        deckExecutor.delegate = self
        deckExecutor.setExecutableActionTypes(self.executableActionTypes)
        deckExecutor.setTokenInstances(self.tokenInstances)
        
        // create a concurrent dispatch queue for both the DeckExecutor operation
        // and the dispatch_sync that will wait for the queue to finish
        let queue = DispatchQueue(label: "com.ibm.research.CardKitRuntime.ExecutionEngine", attributes: .concurrent)
        
        self.operationQueue.underlyingQueue = queue
        
        queue.async {
            print("ExecutionEngine beginning execution in dispatch queue \(queue.description)")
            
            // start executing the deck
            self.operationQueue.addOperation(deckExecutor)
            
            // wait until it's done
            // potential bug: when halt() is called while we are waiting here,
            // this method doesn't return. which is bad if we want to call execute() again.
            print("ExecutionEngine waiting for execution to finish")
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            // capture yields
            let yields: [YieldData] = Array(deckExecutor.yieldData.values)
            
            // and see if we got any errors
            if let error = deckExecutor.error {
                print("ExecutionEngine finished with errors")
                completion(yields, error)
            } else {
                print("ExecutionEngine finished")
                completion(yields, nil)
            }
        }
    }
    
    /// Halts execution of the Deck
    public func halt() {
        print("ExecutionEngine halting execution")
        self.operationQueue.cancelAllOperations()
    }
}

// Pass all notifications from the DeckExecutor up to our own delegate
extension ExecutionEngine: DeckExecutorDelegate {
    func deckExecutor(_ executor: DeckExecutor, willValidate deck: Deck) {
        self.delegate?.executionEngine(self, willValidate: deck)
    }
    func deckExecutor(_ executor: DeckExecutor, didValidate deck: Deck) {
        self.delegate?.executionEngine(self, didValidate: deck)
    }
    func deckExecutor(_ executor: DeckExecutor, willExecute card: Card) {
        self.delegate?.executionEngine(self, willExecute: card)
    }
    func deckExecutor(_ executor: DeckExecutor, willExecute hand: Hand) {
        self.delegate?.executionEngine(self, willExecute: hand)
    }
    func deckExecutor(_ executor: DeckExecutor, willExecute deck: Deck) {
        self.delegate?.executionEngine(self, willExecute: deck)
    }
    func deckExecutor(_ executor: DeckExecutor, didExecute card: Card, producing yields: [Yield : YieldData]?) {
        self.delegate?.executionEngine(self, didExecute: card, producing: yields)
    }
    func deckExecutor(_ executor: DeckExecutor, didExecute hand: Hand, producing yields: [Yield : YieldData]?) {
        self.delegate?.executionEngine(self, didExecute: hand, producing: yields)
    }
    func deckExecutor(_ executor: DeckExecutor, didExecute deck: Deck, producing yields: [Yield : YieldData]?) {
        self.delegate?.executionEngine(self, didExecute: deck, producing: yields)
    }
    func deckExecutor(_ executor: DeckExecutor, hadErrors errors: [Error]) {
        self.delegate?.executionEngine(self, hadErrors: errors)
    }
}
