//
//  ExecutionError.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

//MARK: ExecutionError

public enum ExecutionError: ErrorType {
    case DeckDoesNotValidate(Deck, [ValidationError])
    case NoExecutionTypeDefinedForActionCardDescriptor(ActionCardDescriptor)
    case NoTokenInstanceDefinedForTokenCard(TokenCard)
    case NoTokenCardPresentWithIdentifier(CardIdentifier)
    case TokenSlotBoundToUnboundValue(ActionCard, TokenSlot)
    case UnboundInputEncountered(ActionCard, InputSlot)
    case ExecutionCancelled
}
