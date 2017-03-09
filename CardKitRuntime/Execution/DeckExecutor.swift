//
//  DeckExecutor.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

// swiftlint:disable cyclomatic_complexity

import Foundation

import CardKit

public class DeckExecutor: Operation {
    public fileprivate (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    fileprivate var executableActionTypes: [ActionCardDescriptor : ExecutableAction.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    fileprivate var tokenInstances: [TokenCard : ExecutableToken] = [:]
    
    /// Cache of yields produced by ActionCards after their execution
    public fileprivate (set) var yieldData: [Yield : YieldData] = [:]
    
    /// Private operation queue for executing ActionCards in a Hand
    fileprivate let cardExecutionQueue: OperationQueue
    
    /// Execution error. Only non-nil if execution encountered an error.
    public var error: ExecutionError?
    
    init(with deck: Deck) {
        self.deck = deck
        
        // create the operation queue for executing cards in a hand
        cardExecutionQueue = OperationQueue()
        cardExecutionQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }
    
    // MARK: NSOperation
    
    public override func main() {
        if self.isCancelled {
            return
        }
        
        // execute the deck
        do {
            try self.execute()
        } catch let error {
            self.error = error as? ExecutionError
        }
    }
    
    public override func cancel() {
        // tell all of the tokens to emergencyStop(), in parallel
        // so one token doesn't block another
        let tokens = Array(self.tokenInstances.values)
        
        DispatchQueue.concurrentPerform(iterations: tokens.count) { index in
            let token = tokens[index]
            
            // NOTE: we're not capturing any errors that the token may throw in
            // its emergencyStop() procedure. in the future we may need to find
            // a way to save these.
            let _ = token.emergencyStop(error: ExecutionError.executionCancelled)
        }
        
        // we were cancelled, so set our error
        self.error = ExecutionError.executionCancelled
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
    
    fileprivate func validateDeck() throws {
        let errors = ValidationEngine.validate(self.deck)
        if errors.count > 0 {
            throw ExecutionError.deckDoesNotValidate(errors)
        }
    }
    
    fileprivate func deckRepeats() -> Bool {
        var repeatDeck = false
        for deckCard in deck.deckCards {
            if deckCard.descriptor == CardKit.Deck.Repeat {
                repeatDeck = true
            } else if deckCard.descriptor == CardKit.Deck.Terminate {
                repeatDeck = false
            }
        }
        return repeatDeck
    }
    
    fileprivate func checkForUndefinedActionCardTypes() throws {
        for card in deck.actionCards {
            if self.executableActionTypes[card.descriptor] == nil {
                throw ExecutionError.noExecutionTypeDefinedForActionCardDescriptor(card.descriptor)
            }
        }
    }
    
    fileprivate func checkForUndefinedTokenInstances() throws {
        for card in deck.tokenCards {
            if self.tokenInstances[card] == nil {
                throw ExecutionError.noTokenInstanceDefinedForTokenCard(card)
            }
        }
    }
    
    fileprivate func checkIfExecutionCancelled() throws {
        print("DeckExecutor checking if execution is cancelled")
        if self.isCancelled {
            print("  it is! cancelling all pending operations")
            
            // cancel any ExecutableActions that are executing
            self.cardExecutionQueue.cancelAllOperations()
            
            // throw an error that we were cancelled
            throw ExecutionError.executionCancelled
        }
    }
    
    public func execute() throws {
        // make sure the deck validates!
        print("DeckExecutor validating deck")
        try self.validateDeck()
        
        // make sure we have an execution type for every ActionCard in the deck
        print("DeckExecutor checking for undefined ActionCard types")
        try self.checkForUndefinedActionCardTypes()
        
        // make sure we have an instance of each token in the deck
        print("DeckExecutor checking for undefined Token instances")
        try self.checkForUndefinedTokenInstances()
        
        // figure out if there is a Repeat or Terminate card in the Deck.
        // validation should make sure both cards don't exist simultaneously.
        let repeatDeck: Bool = self.deckRepeats()
        
        // everything checks out -- execute the hand!
        repeat {
            // check if we were cancelled
            try self.checkIfExecutionCancelled()
            
            // start with the first hand in the deck
            var deckHands = deck.hands.enumerated().makeIterator()
            
            // keep track of the next hand we are supposed to execute
            var nextHand: Hand? = nil
            
            // once we follow a branch, execution stops when executeHand() returns nil
            var followedBranch: Bool = false
            
            guard let nextDeckHand = deckHands.next() else { break }
            nextHand = nextDeckHand.1
            
            // execute the hand
            repeat {
                // check if we were cancelled
                try self.checkIfExecutionCancelled()
                
                // get the hand we are executing
                guard let currentHand = nextHand else { break }
                
                // and execute it!
                let subhand = try self.executeHand(currentHand)
                
                // if we haven't yet branched to a subhand, and we aren't going to now, then
                // the next hand is the next hand in the deck
                if !followedBranch && subhand == nil {
                    guard let nextDeckHand = deckHands.next() else { break }
                    nextHand = nextDeckHand.1
                    
                } else {
                    // otherwise, we followed a branch and the next hand is the subhand
                    followedBranch = true
                    nextHand = subhand
                }
            } while nextHand != nil
        } while repeatDeck
    }
    
    /// Execute the given Hand. Returns the next Hand to be executed (if it's a subhand), or nil
    /// if the Deck should continue execution with the next hand. Also returns a flag indicating
    /// whether execution should terminate after the current Hand.
    // swiftlint:disable:next function_body_length
    fileprivate func executeHand(_ hand: Hand) throws -> Hand? {
        // operations to add to the execution queue
        var operations: [Operation] = []
        var executableCards: [ExecutableAction] = []
        
        let satisfactionCheck: DispatchSemaphore = DispatchSemaphore(value: 1)
        var satisfiedCards: Set<CardIdentifier> = Set()
        var isHandSatisfied = false
        var stopExecution = false
        var nextHand: Hand? = nil
        
        print("DeckExecutor setting up hand \(hand.identifier) for execution")
        
        for card in hand.actionCards {
            guard let type = self.executableActionTypes[card.descriptor] else {
                throw ExecutionError.noExecutionTypeDefinedForActionCardDescriptor(card.descriptor)
            }
            
            let executable = type.init(with: card)
            executableCards.append(executable)
            
            // copy in InputBindings
            for (slot, binding) in card.inputBindings {
                switch binding {
                case .boundToInputCard(let inputCard):
                    executable.inputBindings[slot] = inputCard.boundData
                case .boundToYieldingActionCard(_, let yield):
                    guard let yieldData = self.yieldData[yield] else { continue }
                    executable.inputBindings[slot] = .bound(yieldData.data)
                default:
                    throw ExecutionError.unboundInputEncountered(card, slot)
                }
            }
            
            // copy in TokenBindings
            for (slot, binding) in card.tokenBindings {
                switch binding {
                case .boundToTokenCard(let identifier):
                    guard let tokenCard = deck.tokenCard(with: identifier) else {
                        throw ExecutionError.noTokenCardPresentWithIdentifier(identifier)
                    }
                    
                    guard let instance = self.tokenInstances[tokenCard] else {
                        throw ExecutionError.noTokenInstanceDefinedForTokenCard(tokenCard)
                    }
                    
                    executable.tokenBindings[slot] = instance
                default:
                    // shouldn't happen, validation should have caught this
                    throw ExecutionError.tokenSlotBoundToUnboundValue(card, slot)
                }
            }
            
            // create a dependency operation so we know which card finished executing
            let done = BlockOperation {
                print("finished execution of card \(executable.actionCard.description)")
                
                // wait until any other operation doing a check is done
                let _ = satisfactionCheck.wait(timeout: DispatchTime.distantFuture)
                
                // check for errors
                print("  ... checking if the card threw errors")
                if executable.errors.count > 0 {
                    stopExecution = true
                    print("  > it did")
                }
                
                // check for hand satisfaction
                print("  ... checking for hand satisfaction")
                
                // check for satisfaction
                if !isHandSatisfied {
                    satisfiedCards.insert(card.identifier)
                    let satisfactionResult = hand.satisfactionResult(given: satisfiedCards)
                    isHandSatisfied = satisfactionResult.0
                    nextHand = satisfactionResult.1
                    if isHandSatisfied {
                        print("  > it is")
                    }
                }
                satisfactionCheck.signal()
            }
            done.addDependency(executable)
            
            print(" ... it has a \(executable.actionCard.description) card")
            
            // add these to the operation queue
            operations.append(executable)
            operations.append(done)
        }
        
        // add all operations to the queue and execute it
        print("beginning execution of hand")
        cardExecutionQueue.addOperations(operations, waitUntilFinished: false)
        
        // wait until either the operation queue is finished, the hand is satisfied, or 
        // execution should be stopped for any other reason (e-stop, errors thrown)
        while cardExecutionQueue.operationCount > 0 && !isHandSatisfied && !stopExecution {
            // give some processing time. what's the right amount of time we should sleep for before
            // checking if the hand is satisfied? this is a good philosophical question. i'm going to
            // assume checking every second is appropriate, although for more time-sensitive applications
            // this number may need to be reduced.
            print("SLEEPING WHILE WE WAIT FOR HAND EXECUTION TO FINISH")
            Thread.sleep(forTimeInterval: 1)
        }
        
        print("hand execution finished")
        
        // obtain the semaphore so no other threads are performing the satisfaction check
        let _ = satisfactionCheck.wait(timeout: DispatchTime.distantFuture)
        
        // cancel execution of any outstanding operations in the queue
        cardExecutionQueue.cancelAllOperations()
        
        // check to see if any ExecutableActions had errors
        print(" ... checking if any cards threw errors")
        for executable in executableCards {
            if executable.errors.count > 0 {
                print(" ... yep, \(executable.actionCard.description) threw errors: \(executable.errors)")
                
                // signal the tokens for an emergency stop
                print(" ... signaling tokens to perform their emergency stop procedures")
                let results = self.signalTokensForEmergencyStop(errors: executable.errors)
                satisfactionCheck.signal()
                throw ExecutionError.actionCardErrorsTriggeredEmergencyStop(executable.errors, results)
            }
        }
        
        // copy out yielded data
        print(" ... copying out yielded data")
        for executable in executableCards {
            print(" > \(executable.actionCard.descriptor.name) produced \(executable.yieldData.count) yields")
            for yield in executable.yieldData {
                self.yieldData[yield.yield] = YieldData(cardIdentifier: executable.actionCard.identifier, yield: yield.yield, data: yield.data)
            }
        }
        
        // signal on the satisfactionCheck because we're finished; in case anything was
        // waiting to perform a satisfactionCheck, this will unblock them
        satisfactionCheck.signal()
        
        print("the next hand to be executed will be \(nextHand?.identifier)")
        
        return nextHand
    }
    
    fileprivate func signalTokensForEmergencyStop(errors: [Error]) -> [TokenCard : EmergencyStopResult] {
        // trigger all tokens in parallel to perform the emergency stop
        // and then wait until all of them have completed it
        let group = DispatchGroup()
        var results: [TokenCard : EmergencyStopResult] = [:]
        for (_, token) in self.tokenInstances {
            group.enter()
            token.handleEmergencyStop(errors: errors) { result in
                results[token.tokenCard] = result
                group.leave()
            }
        }
        group.wait()
        return results
    }
}
