//
//  ExecutableToken.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/22/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

open class ExecutableToken: CarriesTokenCardState {
    var tokenCard: TokenCard
    
    // used by TriggersEmergencyStop
    fileprivate var queue = DispatchQueue(label: "com.research.ibm.CardKitRuntime.EmergencyStopQueue")
    fileprivate var emergencyStopRequested: Bool = false
    
    public init(with card: TokenCard) {
        self.tokenCard = card
    }
}

extension ExecutableToken: PerformsEmergencyStop {
    /// Triggers an Emergency Stop on the token. It is possible that multiple
    /// `ExecutableAction`s will trigger an Emergency Stop on the same token, so
    /// we use a dispatch queue to enforce that the `handleEmergencyStop()`
    /// method will only be called once.
    public func emergencyStop(errors: [Error]) -> EmergencyStopResult {
        // all calls to `emergencyStop()` will be added to a serial queue
        var stopResult: EmergencyStopResult = .ignored
        queue.sync {
            // if we're late to the party, go home
            if self.emergencyStopRequested == true {
                return
            }
            
            // we are the first block in the queue, so handle the e-stop
            self.emergencyStopRequested = true
            
            self.handleEmergencyStop(errors: errors, { result in
                stopResult = result
            })
        }
        return stopResult
    }
}

extension ExecutableToken: HandlesEmergencyStop {
    /// Perofmrs the Emergency Stop when the trigger is received
    open func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void)) {
        // default implementation is to do nothing; subclasses should override this
        // method to perform token-specific e-stop procedures.
        completion(.success)
    }
}
