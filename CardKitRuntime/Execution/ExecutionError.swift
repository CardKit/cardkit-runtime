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
    case DeckDoesNotValidate([ValidationError])
    case NoExecutionTypeDefinedForActionCardDescriptor(ActionCardDescriptor) //swiftlint:disable:this type_name
    case NoTokenInstanceDefinedForTokenCard(TokenCard)
    case NoTokenCardPresentWithIdentifier(CardIdentifier)
    case TokenSlotBoundToUnboundValue(ActionCard, TokenSlot)
    case UnboundInputEncountered(ActionCard, InputSlot)
    case ExecutionCancelled
    case ActionCardError(ActionExecutionError)
}

//MARK: ActionExecutionError

public enum ActionExecutionError: ErrorType {
    case NilValueForInput(ExecutableActionCard, String)
    case TypeMismatchForInput(ExecutableActionCard, String, InputType, InputDataBinding)
    case ExpectedYieldNotFound(ExecutableActionCard)
    case ExpectedTokenSlotNotFound(ExecutableActionCard, String)
    case UnboundTokenSlot(ExecutableActionCard, TokenSlot)
}
