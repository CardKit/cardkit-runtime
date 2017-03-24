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
    case unboundInputSlot(ExecutableAction, String)
    case nilValueForInput(ExecutableAction, String)
    case boundInputNotConvertibleToExpectedType(ExecutableAction, String, JSON, Any.Type)
    case expectedTokenSlotNotFound(ExecutableAction, String)
    case unboundTokenSlot(ExecutableAction, TokenSlot)
    case yieldAtIndexNotFound(ExecutableAction, Int)
    case attemptToStoreDataForInvalidYield(ExecutableAction, Yield, JSON)
    case attemptToStoreDataOfUnexpectedType(ExecutableAction, Yield, String, String)
    case attemptToRetrieveDataForInvalidYield(ExecutableAction, Yield)
    case nilValueForYield(ExecutableAction, Yield)
    case boundYieldNotConvertibleToExpectedType(ExecutableAction, Yield, JSON, Any.Type)
}
