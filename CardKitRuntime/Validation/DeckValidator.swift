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

// MARK: DeckValidationError

public enum DeckValidationError {
    /// No cards were present in the deck
    case noCardsInDeck
    
    /// No hands were present in the deck
    case noHandsInDeck
    
    /// Multiple hands were found in the Deck sharing the same HandIdentifier (args: Hand identifier, count)
    case multipleHandsWithSameIdentifier(HandIdentifier, Int)
    
    /// A card was placed into multiple hands (args: Card identifier, set of hands in which the card was found)
    case cardUsedInMultipleHands(CardIdentifier, [HandIdentifier])
    
    /// A Card and a Hand were found sharing the same identifier (equivalent String values)
    case cardAndHandShareSameIdentifier(String)
    
    /// A Card and the Deck were found sharing the same identifier (equivalent String values)
    case cardAndDeckShareSameIdentifier(String)
    
    /// A Hand and the Deck were found sharing the same identifier (equivalent String values)
    case handAndDeckShareSameIdentifier(String)
    
    /// A Yield was used before it was produced (args: consuming Card identifier, consuming Hand identifier, producing Card identifier, Yield identifier, producing Hand identifier)
    case yieldConsumedBeforeProduced(CardIdentifier, HandIdentifier, CardIdentifier, YieldIdentifier, HandIdentifier)
    
    /// ActionCard A was bound to ActionCard B, but ActionCard B could not be found in the Deck. (args: ActionCard A identifier, ActionCard A hand identifier, ActionCard B identifier)
    case yieldProducerNotFoundInDeck(CardIdentifier, HandIdentifier, CardIdentifier)
}

// MARK: DeckValidator

class DeckValidator: Validator {
    fileprivate let deck: Deck
    
    init(_ deck: Deck) {
        self.deck = deck
    }
    
    var validationActions: [ValidationAction] {
        var actions: [ValidationAction] = []
        
        // NoCardsInDeck
        actions.append({
            return self.checkNoCardsInDeck(self.deck)
        })
        
        // NoHandsInDeck
        actions.append({
            return self.checkNoHandsInDeck(self.deck)
        })
        
        // MultipleHandsWithSameIdentifier
        actions.append({
            return self.checkMultipleHandsWithSameIdentifier(self.deck)
        })
        
        // CardUsedInMultipleHands
        actions.append({
            return self.checkCardUsedInMultipleHands(self.deck)
        })
        
        // CardAndHandShareSameIdentifier
        actions.append({
            return self.checkCardAndHandShareSameIdentifier(self.deck)
        })
        
        // CardAndDeckShareSameIdentifier
        actions.append({
            return self.checkCardAndDeckShareSameIdentifier(self.deck)
        })
        
        // HandAndDeckShareSameIdentifier
        actions.append({
            return self.checkHandAndDeckShareSameIdentifier(self.deck)
        })
        
        // YieldConsumedBeforeProduced
        // YieldProducerNotFoundInDeck
        actions.append({
            return self.checkYields(self.deck)
        })
        
        return actions
    }
    
    func checkNoCardsInDeck(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if deck.cardCount == 0 {
            errors.append(ValidationError.deckError(.warning, deck.identifier, .noCardsInDeck))
        }
        
        return errors
    }
    
    func checkNoHandsInDeck(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if deck.hands.isEmpty {
            errors.append(ValidationError.deckError(.warning, deck.identifier, .noHandsInDeck))
        }
        
        return errors
    }
    
    func checkMultipleHandsWithSameIdentifier(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        var identifierCounts: [HandIdentifier: Int] = [:]
        
        for hand in deck.hands {
            let count = identifierCounts[hand.identifier] ?? 0
            identifierCounts[hand.identifier] = count + 1
        }
        
        for (identifier, count) in identifierCounts {
            if count > 1 {
                errors.append(ValidationError.deckError(.error, deck.identifier, .multipleHandsWithSameIdentifier(identifier, count)))
            }
        }
        
        return errors
    }
    
    func checkCardUsedInMultipleHands(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        var cardInHands: [CardIdentifier: [HandIdentifier]] = [:]
        
        for hand in deck.hands {
            for card in hand.cards {
                var hands = cardInHands[card.identifier] ?? []
                hands.append(hand.identifier)
                cardInHands[card.identifier] = hands
            }
        }
        
        for (identifier, hands) in cardInHands {
            if hands.count > 1 {
                errors.append(ValidationError.deckError(.warning, deck.identifier, .cardUsedInMultipleHands(identifier, hands)))
            }
        }
        
        return errors
    }
    
    func checkCardAndHandShareSameIdentifier(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        var cardIdentifiers: Set<String> = Set()
        var handIdentifiers: Set<String> = Set()
        
        for card in deck.cards {
            cardIdentifiers.insert(card.identifier.description)
        }
        
        for hand in deck.hands {
            handIdentifiers.insert(hand.identifier.description)
        }
        
        // check if Card identifiers are contained in Hand
        for cardIdentifier in cardIdentifiers {
            if handIdentifiers.contains(cardIdentifier) {
                errors.append(ValidationError.deckError(.error, deck.identifier, .cardAndHandShareSameIdentifier(cardIdentifier)))
            }
        }
        
        // check if Hand identifiers are contained in Card
        for handIdentifier in handIdentifiers {
            if cardIdentifiers.contains(handIdentifier) {
                errors.append(ValidationError.deckError(.error, deck.identifier, .cardAndHandShareSameIdentifier(handIdentifier)))
            }
        }
        
        return errors
    }
    
    func checkCardAndDeckShareSameIdentifier(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for card in deck.cards {
            if card.identifier.description == deck.identifier.description {
                errors.append(ValidationError.deckError(.error, deck.identifier, .cardAndDeckShareSameIdentifier(card.identifier.description)))
            }
        }
        
        return errors
    }
    
    func checkHandAndDeckShareSameIdentifier(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for hand in deck.hands {
            if hand.identifier.description == deck.identifier.description {
                errors.append(ValidationError.deckError(.error, deck.identifier, .handAndDeckShareSameIdentifier(hand.identifier.description)))
            }
        }
        
        return errors
    }
    
    func checkYields(_ deck: Deck) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        func handContainingCard(with identifier: CardIdentifier) -> Hand? {
            for hand in deck.hands {
                if hand.contains(identifier) {
                    return hand
                }
            }
            return nil
        }
        
        func checkYieldUsage(_ hand: Hand, actionCardsWithProducedYields: Set<CardIdentifier>) {
            for card in hand.actionCards {
                for (_, binding) in card.inputBindings {
                    // if this card is bound to a yielding action card...
                    if case .boundToYieldingActionCard(let identifier, let yield) = binding {
                        // and that card hasn't yet produced its yields...
                        if !actionCardsWithProducedYields.contains(identifier) {
                            // then the yield is being used before it was produced!
                            // figure out which hand the actionCard belongs to
                            if let producingHand = handContainingCard(with: identifier) {
                                errors.append(ValidationError.deckError(.error, deck.identifier, .yieldConsumedBeforeProduced(card.identifier, hand.identifier, identifier, yield.identifier, producingHand.identifier)))
                            } else {
                                errors.append(ValidationError.deckError(.error, deck.identifier, .yieldProducerNotFoundInDeck(card.identifier, hand.identifier, identifier)))
                            }
                        }
                    }
                }
            }
        }
        
        return errors
    }
}
