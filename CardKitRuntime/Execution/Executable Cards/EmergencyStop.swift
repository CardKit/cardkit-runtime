//
//  EmergencyStop.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 3/8/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation

protocol SignalsEmergencyStop {
    /// Triggers an Emergency Stop. `errors` are the errors that triggered the Emergency Stop.
    func emergencyStop(errors: [Error])
}

protocol PerformsEmergencyStop {
    /// Performs an Emergency Stop. `errors` are the errors that triggered the Emergency Stop.
    /// Note the difference between `SignalsEmergencyStop` and `PerformsEmergencyStop` is
    /// that the former assumes the caller does not handle the errors generated
    /// by the Emergency Stop (e.g. because it's just a signal to perform the Emergency
    /// Stop), versus this protocol assumes that the caller of `emergencyStop()` will handle them.
    func emergencyStop(errors: [Error]) -> EmergencyStopResult
}

extension PerformsEmergencyStop {
    /// Triggers an Emergency Stop on the token. It is possible that multiple
    /// `ExecutableAction`s will trigger an Emergency Stop on the same token, so
    /// we use a dispatch queue to enforce that the `handleEmergencyStop()`
    /// method will only be called once.
    func emergencyStop(error: Error) -> EmergencyStopResult {
        return self.emergencyStop(errors: [error])
    }
}

protocol HandlesEmergencyStop {
    /// Performs the Emergency Stop when the trigger is received. `errors` are the errors
    /// that triggered the Emergency Stop.
    func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void))
}

public enum EmergencyStopResult {
    case success
    case failure([Error])
    case ignored
}
