//
//  CardValidator.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/8/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: CardValidationError

public enum CardValidationError {
    /// The type of the Card Descriptor does not match the type of the Card Instance (args: expected type, actual type)
    case cardDescriptorTypeDoesNotMatchInstanceType(CardType, Any.Type)
    
    /// The TokenSlot has not been bound with a Token card, or it was bound to an Unbound value
    case tokenSlotNotBound(TokenSlot)
    
    /// The Token card bound to this card was not found in the Deck
    case boundTokenCardNotPresentInDeck(CardIdentifier)
    
    /// The TokenSlot was bound to a card that is not a TokenCard (args: the token slot, the identifier of the non-Token card to which it was bound)
    case tokenSlotNotBoundToTokenCard(TokenSlot, CardIdentifier)
    
    /// The InputSlot is non-optional but does not have an InputCard bound to it
    case mandatoryInputSlotNotBound(InputSlot)
    
    /// The InputSlot is bound, but has an Unbound value.
    case inputSlotBoundToUnboundValue(InputSlot)
    
    /// The InputSlot expected a different type of input than that provided by the InputCard (args: slot, expected type, bound InputCard identifier, provided type)
    case inputSlotBoundToUnexpectedType(InputSlot, String, CardIdentifier, String)
    
    /// The InputSlot was bound to an invalid Card type (Deck, Hand, or Token)
    case inputSlotBoundToInvalidCardType(InputSlot, InputType, CardIdentifier, CardType)
}

// MARK: CardValidator

class CardValidator: Validator {
    fileprivate let deck: Deck
    fileprivate let hand: Hand
    fileprivate let card: Card
    
    init(_ deck: Deck, _ hand: Hand, _ card: Card) {
        self.deck = deck
        self.hand = hand
        self.card = card
    }
    
    var validationActions: [ValidationAction] {
        var actions: [ValidationAction] = []
        
        // CardDescriptorTypeDoesNotMatchInstanceType
        actions.append({
            return self.checkCardDescriptorTypeDoesNotMatchInstanceType(self.deck, self.hand, self.card)
        })
        
        // TokenSlotNotBound
        actions.append({
            // only applies to ActionCards
            guard let actionCard = self.card as? ActionCard else { return [] }
            return self.checkTokenSlotNotBound(self.deck, self.hand, actionCard)
        })
        
        // BoundTokenCardNotPresentInDeck
        actions.append({
            // only applies to ActionCards
            guard let actionCard = self.card as? ActionCard else { return [] }
            return self.checkBoundTokenCardNotPresentInDeck(self.deck, self.hand, actionCard)
        })
        
        // TokenSlotNotBoundToTokenCard
        actions.append({
            // only applies to ActionCards
            guard let actionCard = self.card as? ActionCard else { return [] }
            return self.checkTokenSlotNotBoundToTokenCard(self.deck, self.hand, actionCard)
        })
        
        // MandatoryInputSlotNotBound
        actions.append({
            // only applies to ActionCards
            guard let actionCard = self.card as? ActionCard else { return [] }
            return self.checkMandatoryInputSlotNotBound(self.deck, self.hand, actionCard)
        })
        
        // InputSlotBoundToUnboundValue
        // InputSlotBoundToUnexpectedType
        // InputSlotBoundToInvalidCardType
        actions.append({
            // only applies to ActionCards
            guard let actionCard = self.card as? ActionCard else { return [] }
            return self.checkInputSlotBindings(self.deck, self.hand, actionCard)
        })
        
        return actions
    }
    
    func checkCardDescriptorTypeDoesNotMatchInstanceType(_ deck: Deck, _ hand: Hand, _ card: Card) -> [ValidationError] {
        switch card.cardType {
        case .action:
            guard let _ = card as? ActionCard else {
                return [ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .cardDescriptorTypeDoesNotMatchInstanceType(.action, type(of: card)))]
            }
        case .deck:
            guard let _ = card as? DeckCard else {
                return [ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .cardDescriptorTypeDoesNotMatchInstanceType(.deck, type(of: card)))]
            }
        case .hand:
            guard let _ = card as? HandCard else {
                return [ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .cardDescriptorTypeDoesNotMatchInstanceType(.hand, type(of: card)))]
            }
        case .input:
            guard let _ = card as? InputCard else {
                return [ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .cardDescriptorTypeDoesNotMatchInstanceType(.input, type(of: card)))]
            }
        case .token:
            guard let _ = card as? TokenCard else {
                return [ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .cardDescriptorTypeDoesNotMatchInstanceType(.token, type(of: card)))]
            }
        }
        
        // success!
        return []
    }
    
    func checkTokenSlotNotBound(_ deck: Deck, _ hand: Hand, _ card: ActionCard) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for tokenSlot in card.tokenSlots {
            if !card.isSlotBound(tokenSlot) {
                errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .tokenSlotNotBound(tokenSlot)))
            }
        }
        
        return errors
    }
    
    func checkBoundTokenCardNotPresentInDeck(_ deck: Deck, _ hand: Hand, _ card: ActionCard) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for tokenSlot in card.tokenSlots {
            // this is the TokenCard bound to the slot
            guard let identifier = card.cardIdentifierBound(to: tokenSlot) else { break }
            
            // make sure that token is part of the Deck's tokenCards
            let found = deck.tokenCards.reduce(false) { (ret, token) in ret || token.identifier == identifier }
            
            if !found {
                errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .boundTokenCardNotPresentInDeck(identifier)))
            }
        }
        
        return errors
    }
    
    func checkTokenSlotNotBoundToTokenCard(_ deck: Deck, _ hand: Hand, _ card: ActionCard) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for slot in card.tokenSlots {
            // unbound inputs are caught by another validation function
            let binding = card.binding(of: slot)
            switch binding {
            case .unbound:
                // don't throw an error here, we already checked for this
                continue
            case .boundToTokenCard(let identifier):
                // find this card in the deck
                let found = deck.tokenCards.reduce(false) { (ret, token) in ret || token.identifier == identifier }
                
                if !found {
                    errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .tokenSlotNotBoundToTokenCard(slot, identifier)))
                }
            }
        }
        
        return errors
    }
    
    func checkMandatoryInputSlotNotBound(_ deck: Deck, _ hand: Hand, _ card: ActionCard) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for slot in card.inputSlots {
            // !slot.isOptional && !card.isSlotBound(slot) is causing the swift compiler to freak out because of the &&. which makes no sense, because both sides of that are Bool.
            if !slot.isOptional {
                if !card.isSlotBound(slot) {
                    errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .mandatoryInputSlotNotBound(slot)))
                }
            }
        }
    
        return errors
    }
    
    func checkInputSlotBindings(_ deck: Deck, _ hand: Hand, _ card: ActionCard) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        for slot in card.inputSlots {
            // if there is no card bound to a mandatory slot, we would have already checked for this
            guard let binding = card.binding(of: slot) else { continue }
            let expectedDescriptor = slot.descriptor
            
            switch binding {
            case .unbound:
                errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .inputSlotBoundToUnboundValue(slot)))
            case .boundToInputCard(let inputCard):
                // make sure the InputCard's data type matches the expected type
                let actualDescriptor = inputCard.descriptor
                if expectedDescriptor != actualDescriptor {
                    errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .inputSlotBoundToUnexpectedType(slot, expectedDescriptor.inputType, inputCard.identifier, actualDescriptor.inputType)))
                }
            case .boundToYieldingActionCard(let identifier, let yield):
                // make sure the ActionCard's Yield type matches the expected type
                let actualType = yield.type
                if expectedDescriptor.inputType != actualType {
                    errors.append(ValidationError.cardError(.error, deck.identifier, hand.identifier, card.identifier, .inputSlotBoundToUnexpectedType(slot, expectedDescriptor.inputType, identifier, actualType)))
                }
            }
        }
        
        return errors
    }
}
