//
//  ValidationEngine.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/8/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

public class ValidationEngine {
    /// Validates the entire Deck.
    public class func validate(_ deck: Deck) -> [ValidationError] {
        var validationActions: [ValidationAction] = []
        
        validationActions.append(contentsOf: DeckValidator(deck).validationActions)
        
        for hand in deck.hands {
            validationActions.append(contentsOf: HandValidator(deck, hand).validationActions)
            
            for card in hand.cards {
                validationActions.append(contentsOf: CardValidator(deck, hand, card).validationActions)
            }
        }
        
        return ValidationEngine.executeValidation(validationActions)
    }
    
    /// Validates the given Hand in the given Deck.
    public class func validate(_ hand: Hand, _ deck: Deck) -> [ValidationError] {
        var validationActions: [ValidationAction] = []
        
        validationActions.append(contentsOf: HandValidator(deck, hand).validationActions)
            
        for card in hand.cards {
            validationActions.append(contentsOf: CardValidator(deck, hand, card).validationActions)
        }
        
        return ValidationEngine.executeValidation(validationActions)
    }
    
    /// Validates the given Card in the given Hand in the given Deck.
    public class func validate(_ card: Card, _ hand: Hand, _ deck: Deck) -> [ValidationError] {
        var validationActions: [ValidationAction] = []
        
        validationActions.append(contentsOf: CardValidator(deck, hand, card).validationActions)
        
        return ValidationEngine.executeValidation(validationActions)
    }
    
    class func executeValidation(_ validationActions: [ValidationAction]) -> [ValidationError] {
//        let queue = DispatchQueue(label: "com.ibm.research.CardKit.ValidationEngine", attributes: DispatchQueue.Attributes.concurrent)
        
        let errorSemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
        var validationErrors: [ValidationError] = []
        
        DispatchQueue.concurrentPerform(iterations: validationActions.count) { i in
            let action = validationActions[i]
            let errors = action()
            
            let _ = errorSemaphore.wait(timeout: DispatchTime.distantFuture)
            validationErrors.append(contentsOf: errors)
            errorSemaphore.signal()
        }
        
        return validationErrors
    }
}
