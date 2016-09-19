//
//  ValidationError.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/8/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: ValidationSeverity

public enum ValidationSeverity: String {
    case error
    case warning
}

extension ValidationSeverity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .error:
            return "error"
        case .warning:
            return "warning"
        }
    }
}

// MARK: ValidationError

public enum ValidationError {
    case deckError(ValidationSeverity, DeckIdentifier, DeckValidationError)
    case handError(ValidationSeverity, DeckIdentifier, HandIdentifier, HandValidationError)
    case cardError(ValidationSeverity, DeckIdentifier, HandIdentifier, CardIdentifier, CardValidationError)
}
