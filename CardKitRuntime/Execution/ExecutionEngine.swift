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
    public private (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    private var executableActionTypes: [ActionCardDescriptor : ExecutableActionCard.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    private var tokenInstances: [TokenCard : ExecutableTokenCard] = [:]
    
    /// Queue used for running the DeckExecutor
    private let operationQueue: NSOperationQueue = NSOperationQueue()
    
    init(with deck: Deck) {
        self.deck = deck
        
        // register these implementation classes because they come bundled with the Runtime
        self.setExecutableActionType(CKTimer.self, for: CardKit.Action.Trigger.Time.Timer)
        self.setExecutableActionType(CKWaitUntilTime.self, for: CardKit.Action.Trigger.Time.WaitUntilTime)
    }
    
    //MARK: Instance Methods
    
    public func setExecutableActionType(type: ExecutableActionCard.Type, for descriptor: ActionCardDescriptor) {
        self.executableActionTypes[descriptor] = type
    }
    
    public func setExecutableActionTypes(executionTypes: [ActionCardDescriptor : ExecutableActionCard.Type]) {
        self.executableActionTypes = executionTypes
    }
    
    public func setTokenInstance(instance: ExecutableTokenCard, for tokenCard: TokenCard) {
        self.tokenInstances[tokenCard] = instance
    }
    
    public func setTokenInstances(tokenInstances: [TokenCard : ExecutableTokenCard]) {
        self.tokenInstances = tokenInstances
    }
    
    public func execute(completion: (YieldBindings, ExecutionError?) -> Void) {
        // create a DeckExecutor
        let deckExecutor = DeckExecutor(with: self.deck)
        deckExecutor.setExecutableActionTypes(self.executableActionTypes)
        deckExecutor.setTokenInstances(self.tokenInstances)
        
        // create a concurrent dispatch queue for both the DeckExecutor operation
        // and the dispatch_async that will wait for the queue to finish
        let queue = dispatch_queue_create("com.ibm.research.CardKitRuntime.ExecutionEngine", DISPATCH_QUEUE_CONCURRENT)
        
        self.operationQueue.underlyingQueue = queue
        
        dispatch_async(queue) {
            // start executing the deck
            self.operationQueue.addOperation(deckExecutor)
            
            // wait until it's done
            self.operationQueue.waitUntilAllOperationsAreFinished()
            
            // and see if we got any errors
            if let error = deckExecutor.error {
                completion(deckExecutor.yieldData, error)
            } else {
                completion(deckExecutor.yieldData, nil)
            }
        }
    }
    
    public func cancelExecution() {
        self.operationQueue.cancelAllOperations()
    }
}
