//
//  ExecutionError.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/25/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: ExecutionError

public enum ExecutionError: Error {
    case deckDoesNotValidate([ValidationError])
    case noExecutionTypeDefinedForActionCardDescriptor(ActionCardDescriptor) //swiftlint:disable:this type_name
    case noTokenInstanceDefinedForTokenCard(TokenCard)
    case noTokenCardPresentWithIdentifier(CardIdentifier)
    case tokenSlotBoundToUnboundValue(ActionCard, TokenSlot)
    case unboundInputEncountered(ActionCard, InputSlot)
    case executionCancelled
    case actionCardError(ActionExecutionError)
}

// MARK: ActionExecutionError

public enum ActionExecutionError: Error {
    case nilValueForInput(ExecutableActionCard, String)
    case typeMismatchForInput(ExecutableActionCard, String, InputType, InputDataBinding)
    case expectedYieldNotFound(ExecutableActionCard)
    case expectedTokenSlotNotFound(ExecutableActionCard, String)
    case unboundTokenSlot(ExecutableActionCard, TokenSlot)
}
