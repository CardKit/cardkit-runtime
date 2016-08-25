//
//  DeckExecutor.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public class DeckExecutor: NSOperation {
    public private (set) var deck: Deck
    
    /// Map between ActionCardDescriptor and the type that implements it
    private var executableActionTypes: [ActionCardDescriptor : ExecutableActionCard.Type] = [:]
    
    /// Map between TokenCard and the instance that implements it
    private var tokenInstances: [TokenCard : ExecutableTokenCard] = [:]
    
    /// Cache of yields produced by ActionCards after their execution
    private var yieldData: [Yield : InputDataBinding] = [:]
    
    /// Private operation queue for executing ActionCards in a Hand
    private let cardExecutionQueue: NSOperationQueue
    
    /// Execution error. Only non-nil if execution encountered an error.
    public var error: ExecutionError? = nil
    
    init(with deck: Deck) {
        self.deck = deck
        
        // create the operation queue for executing cards in a hand
        cardExecutionQueue = NSOperationQueue()
        cardExecutionQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    }
    
    //MARK: NSOperation
    
    public override func main() {
        if self.cancelled {
            return
        }
        
        // execute the deck
        do {
            try self.execute()
        } catch let error {
            self.error = error as? ExecutionError
        }
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
    
    private func validateDeck() throws {
        let errors = ValidationEngine.validate(self.deck)
        if errors.count > 0 {
            throw ExecutionError.DeckDoesNotValidate(self.deck, errors)
        }
    }
    
    private func deckRepeats() -> Bool {
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
    
    private func checkForUndefinedActionCardTypes() throws {
        for card in deck.actionCards {
            if self.executableActionTypes[card.descriptor] == nil {
                throw ExecutionError.NoExecutionTypeDefinedForActionCardDescriptor(card.descriptor)
            }
        }
    }
    
    private func checkForUndefinedTokenInstances() throws {
        for card in deck.tokenCards {
            if self.tokenInstances[card] == nil {
                throw ExecutionError.NoTokenInstanceDefinedForTokenCard(card)
            }
        }
    }
    
    private func checkIfExecutionCancelled() throws {
        if self.cancelled {
            // cancel any ExecutableActionCards that are executing
            self.cardExecutionQueue.cancelAllOperations()
            
            // throw an error that we were cancelled
            throw ExecutionError.ExecutionCancelled
        }
    }
    
    public func execute() throws {
        // make sure the deck validates!
        try self.validateDeck()
        
        // figure out if there is a Repeat or Terminate card in the Deck.
        // validation should make sure both cards don't exist simultaneously.
        let repeatDeck: Bool = self.deckRepeats()
        
        // make sure we have an execution type for every ActionCard in the deck
        try self.checkForUndefinedActionCardTypes()
        
        // make sure we have an instance of each token in the deck
        try self.checkForUndefinedTokenInstances()
        
        // everything checks out -- execute the hand!
        repeat {
            // check if we were cancelled
            try self.checkIfExecutionCancelled()
            
            // start with the first hand in the deck
            var deckHands = deck.hands.enumerate().generate()
            
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
    private func executeHand(hand: Hand) throws -> Hand? {
        // operations to add to the execution queue
        var operations: [NSOperation] = []
        
        let satisfactionCheck: dispatch_semaphore_t = dispatch_semaphore_create(1)
        var satisfiedCards: Set<CardIdentifier> = Set()
        var isHandSatisfied = false
        var nextHand: Hand? = nil
        
        for card in hand.actionCards {
            guard let type = self.executableActionTypes[card.descriptor] else {
                throw ExecutionError.NoExecutionTypeDefinedForActionCardDescriptor(card.descriptor)
            }
            
            let executable = type.init(with: card)
            
            // copy in InputBindings
            for (slot, binding) in card.inputBindings {
                switch binding {
                case .BoundToInputCard(let inputCard):
                    executable.inputs[slot] = inputCard.inputDataValue()
                case .BoundToYieldingActionCard(_, let yield):
                    guard let yieldDataValue = self.yieldData[yield] else { continue }
                    executable.inputs[slot] = yieldDataValue
                default:
                    throw ExecutionError.UnboundInputEncountered(card, slot)
                }
            }
            
            // copy in TokenBindings
            for (slot, binding) in card.tokenBindings {
                switch binding {
                case .BoundToTokenCard(let identifier):
                    guard let tokenCard = deck.tokenCard(with: identifier) else {
                        throw ExecutionError.NoTokenCardPresentWithIdentifier(identifier)
                    }
                    
                    guard let instance = self.tokenInstances[tokenCard] else {
                        throw ExecutionError.NoTokenInstanceDefinedForTokenCard(tokenCard)
                    }
                    
                    executable.tokens[slot] = instance
                default:
                    // shouldn't happen, validation should have caught this
                    throw ExecutionError.TokenSlotBoundToUnboundValue(card, slot)
                }
            }
            
            // create a dependency operation so we know which card finished executing
            let done = NSBlockOperation() {
                // wait until any other operation doing a check is done
                dispatch_semaphore_wait(satisfactionCheck, DISPATCH_TIME_FOREVER)
                if !isHandSatisfied {
                    satisfiedCards.insert(card.identifier)
                    let satisfactionResult = hand.satisfactionResult(given: satisfiedCards)
                    isHandSatisfied = satisfactionResult.0
                    nextHand = satisfactionResult.1
                }
                dispatch_semaphore_signal(satisfactionCheck)
            }
            done.addDependency(executable)
            
            // add these to the operation queue
            operations.append(executable)
            operations.append(done)
        }
        
        // add all operations to the queue and execute it
        cardExecutionQueue.addOperations(operations, waitUntilFinished: false)
        
        // wait until either the operation queue is finished, or the hand is satisfied
        while cardExecutionQueue.operationCount > 0 && !isHandSatisfied {
            // give some processing time. what's the right amount of time we should sleep for before
            // checking if the hand is satisfied? this is a good philosophical question. i'm going to
            // assume checking every second is appropriate, although for more time-sensitive applications
            // this number may need to be reduced.
            NSThread.sleepForTimeInterval(1)
        }
        
        return nextHand
    }
}