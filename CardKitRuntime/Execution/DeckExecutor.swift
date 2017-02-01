//
//  DeckExecutor.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public class DeckExecutor: Operation {
    public fileprivate (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    fileprivate var executableActionTypes: [ActionCardDescriptor : ExecutableActionCard.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    fileprivate var tokenInstances: [TokenCard : ExecutableTokenCard] = [:]
    
    /// Cache of yields produced by ActionCards after their execution
    public fileprivate (set) var yieldData: YieldBindings = [:]
    
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
            
            // cancel any ExecutableActionCards that are executing
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
    //swiftlint:disable:next function_body_length
    fileprivate func executeHand(_ hand: Hand) throws -> Hand? {
        // operations to add to the execution queue
        var operations: [Operation] = []
        var executableCards: [ExecutableActionCard] = []
        
        let satisfactionCheck: DispatchSemaphore = DispatchSemaphore(value: 1)
        var satisfiedCards: Set<CardIdentifier> = Set()
        var isHandSatisfied = false
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
                    executable.inputs[slot] = inputCard.boundData
                case .boundToYieldingActionCard(_, let yield):
                    guard let yieldDataValue = self.yieldData[yield] else { continue }
                    executable.inputs[slot] = yieldDataValue
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
                    
                    executable.tokens[slot] = instance
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
                
                print("  ... copying out yielded data")
                
                // copy out yielded data
                for (yield, data) in executable.yields {
                    self.yieldData[yield] = data
                }
                
                print("  ... checking for hand satisfaction")
                
                // check for satisfaction
                if !isHandSatisfied {
                    satisfiedCards.insert(card.identifier)
                    let satisfactionResult = hand.satisfactionResult(given: satisfiedCards)
                    isHandSatisfied = satisfactionResult.0
                    nextHand = satisfactionResult.1
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
        
        // wait until either the operation queue is finished, or the hand is satisfied
        while cardExecutionQueue.operationCount > 0 && !isHandSatisfied {
            // give some processing time. what's the right amount of time we should sleep for before
            // checking if the hand is satisfied? this is a good philosophical question. i'm going to
            // assume checking every second is appropriate, although for more time-sensitive applications
            // this number may need to be reduced.
            print("SLEEPING WHILE WE WAIT FOR ALL CARDS TO FINISH EXECUTION")
            Thread.sleep(forTimeInterval: 1)
        }
        
        print("hand execution finished, checking if any cards threw errors")
        
        // obtain the semaphore so no other threads are performing the satisfaction check
        let _ = satisfactionCheck.wait(timeout: DispatchTime.distantFuture)
        
        // cancel execution of any outstanding operations in the queue
        cardExecutionQueue.cancelAllOperations()
        
        // check to see if any ExecutableActionCards had errors
        for executable in executableCards {
            // only throws the first error encountered...
            if let error = executable.error {
                print(" ... yep, a card threw an error: \(executable.actionCard.description)")
                satisfactionCheck.signal()
                throw ExecutionError.actionCardError(error)
            }
        }
        satisfactionCheck.signal()
        
        print("the next hand to be executed will be \(nextHand?.identifier)")
        
        return nextHand
    }
}
