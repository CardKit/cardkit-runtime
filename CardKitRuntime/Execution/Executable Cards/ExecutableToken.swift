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

import Foundation

import CardKit

// HandlesEmergencyStop cannot be declared in an extension (yet) because 
// the `handleEmergencyStop()` method needs to be overridden by subclasses,
// and swift does not (yet) support overriding methods declared in extensions.
open class ExecutableToken: CarriesTokenCardState, HandlesEmergencyStop {
    var tokenCard: TokenCard
    
    // used by TriggersEmergencyStop
    fileprivate var queue = DispatchQueue(label: "com.research.ibm.CardKitRuntime.EmergencyStopQueue")
    fileprivate var emergencyStopRequested: Bool = false
    
    public init(with card: TokenCard) {
        self.tokenCard = card
    }
    
    // MARK: HandlesEmergencyStop
    /// Performs the Emergency Stop when the trigger is received. Should be overridden by
    /// subclasses to actually perform the actions necessary for an emergency stop.
    open func handleEmergencyStop(errors: [Error], _ completion: ((EmergencyStopResult) -> Void)) {
        // default implementation is to do nothing; subclasses should override this
        // method to perform token-specific e-stop procedures.
        completion(.success)
    }
}

// MARK: - PerformsEmergencyStop

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
