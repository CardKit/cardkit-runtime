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
