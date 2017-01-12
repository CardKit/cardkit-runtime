//
//  ExecutionEngine.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/17/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public class ExecutionEngine {
    public fileprivate (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    fileprivate var executableActionTypes: [ActionCardDescriptor : ExecutableActionCard.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    fileprivate var tokenInstances: [TokenCard : ExecutableTokenCard] = [:]
    
    /// Queue used for running the DeckExecutor
    fileprivate let operationQueue: OperationQueue = OperationQueue()
    
    public init(with deck: Deck) {
        self.deck = deck
        
        // register these implementation classes because they come bundled with the Runtime
        self.setExecutableActionType(CKTimer.self, for: CardKit.Action.Trigger.Time.Timer)
        self.setExecutableActionType(CKWaitUntilTime.self, for: CardKit.Action.Trigger.Time.WaitUntilTime)
    }
    
    // MARK: Instance Methods
    
    public func setExecutableActionType(_ type: ExecutableActionCard.Type, for descriptor: ActionCardDescriptor) {
        self.executableActionTypes[descriptor] = type
    }
    
    public func setExecutableActionTypes(_ executionTypes: [ActionCardDescriptor : ExecutableActionCard.Type]) {
        self.executableActionTypes = executionTypes
    }
    
    public func setTokenInstance(_ instance: ExecutableTokenCard, for tokenCard: TokenCard) {
        self.tokenInstances[tokenCard] = instance
    }
    
    public func setTokenInstances(_ tokenInstances: [TokenCard : ExecutableTokenCard]) {
        self.tokenInstances = tokenInstances
    }
    
    public func execute(_ completion: (YieldBindings, ExecutionError?) -> Void) {
        // create a DeckExecutor
        let deckExecutor = DeckExecutor(with: self.deck)
        deckExecutor.setExecutableActionTypes(self.executableActionTypes)
        deckExecutor.setTokenInstances(self.tokenInstances)
        
        // create a concurrent dispatch queue for both the DeckExecutor operation
        // and the dispatch_sync that will wait for the queue to finish
        let queue = DispatchQueue(label: "com.ibm.research.CardKitRuntime.ExecutionEngine", attributes: DispatchQueue.Attributes.concurrent)
        
        self.operationQueue.underlyingQueue = queue
        
        queue.sync {
            print("ExecutionEngine beginning execution in dispatch queue \(queue.description)")
            
            // start executing the deck
            self.operationQueue.addOperation(deckExecutor)
            
            // wait until it's done
            print("ExecutionEngine waiting for execution to finish")
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            // and see if we got any errors
            if let error = deckExecutor.error {
                print("ExecutionEngine finished with errors")
                completion(deckExecutor.yieldData, error)
            } else {
                print("ExecutionEngine finished")
                completion(deckExecutor.yieldData, nil)
            }
        }
    }
    
    public func cancelExecution() {
        print("ExecutionEngine cancelling execution")
        self.operationQueue.cancelAllOperations()
    }
}
