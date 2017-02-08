//
//  ExecutionError.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import Freddy

import CardKit

// MARK: ExecutionError

public enum ExecutionError: Error {
    case deckDoesNotValidate([ValidationError])
    case noExecutionTypeDefinedForActionCardDescriptor(ActionCardDescriptor)
    case noTokenInstanceDefinedForTokenCard(TokenCard)
    case noTokenCardPresentWithIdentifier(CardIdentifier)
    case tokenSlotBoundToUnboundValue(ActionCard, TokenSlot)
    case unboundInputEncountered(ActionCard, InputSlot)
    case executionCancelled
    case actionCardError(Error)
}

// MARK: ActionExecutionError

public enum ActionExecutionError: Error {
    case expectedInputSlotNotFound(ExecutableActionCard, String)
    case nilValueForInput(ExecutableActionCard, String)
    case boundInputNotConvertibleToExpectedType(ExecutableActionCard, String, JSON, Any.Type)
    case expectedTokenSlotNotFound(ExecutableActionCard, String)
    case unboundTokenSlot(ExecutableActionCard, TokenSlot)
    case expectedYieldNotFound(ExecutableActionCard)
}
