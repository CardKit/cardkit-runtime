//
//  ExecutionError.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

// swiftlint:disable identifier_name

import Foundation

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
    case actionCardErrorsTriggeredEmergencyStop([Error], [TokenCard : EmergencyStopResult])
}

// MARK: ActionExecutionError

public enum ActionExecutionError: Error {
    case expectedInputSlotNotFound(ExecutableAction, String)
    case unboundInputSlot(ExecutableAction, String)
    case boundInputNotConvertibleToExpectedType(ExecutableAction, String, Data, Any.Type)
    case expectedTokenSlotNotFound(ExecutableAction, String)
    case unboundTokenSlot(ExecutableAction, TokenSlot)
    case yieldAtIndexNotFound(ExecutableAction, Int)
    case attemptToStoreInvalidYield(ExecutableAction, Yield)
    case attemptToStoreYieldOfUnexpectedType(ExecutableAction, Yield, String, String)
    case attemptToRetrieveInvalidYield(ExecutableAction, Yield)
    case nilValueForYield(ExecutableAction, Yield)
    case boundYieldNotConvertibleToExpectedType(ExecutableAction, Yield, Data, Any.Type)
    case emergencyStop(Error)
}
