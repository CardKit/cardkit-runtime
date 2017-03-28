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
    fileprivate var executableActionTypes: [ActionCardDescriptor : ExecutableAction.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    fileprivate var tokenInstances: [TokenCard : ExecutableToken] = [:]
    
    /// Queue used for running the DeckExecutor
    fileprivate let operationQueue: OperationQueue = OperationQueue()
    
    public init(with deck: Deck) {
        self.deck = deck
        
        // register these implementation classes because they come bundled with the Runtime
        self.setExecutableActionType(CKTimer.self, for: CardKit.Action.Trigger.Time.Timer)
        self.setExecutableActionType(CKWaitUntilTime.self, for: CardKit.Action.Trigger.Time.WaitUntilTime)
    }
    
    // MARK: Instance Methods
    
    public func setExecutableActionType(_ type: ExecutableAction.Type, for descriptor: ActionCardDescriptor) {
        self.executableActionTypes[descriptor] = type
    }
    
    public func setExecutableActionTypes(_ executionTypes: [ActionCardDescriptor : ExecutableAction.Type]) {
        self.executableActionTypes = executionTypes
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
            // TODO potential bug: when halt() is called while we are waiting here,
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
