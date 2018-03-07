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
        
        DispatchQueue.concurrentPerform(iterations: validationActions.count) { idx in
            let action = validationActions[idx]
            let errors = action()
            
            _ = errorSemaphore.wait(timeout: DispatchTime.distantFuture)
            validationErrors.append(contentsOf: errors)
            errorSemaphore.signal()
        }
        
        return validationErrors
    }
}
