//
//  CKTimer.swift
//  CardKit
//
//  Created by Justin Weisz on 7/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

//MARK: CKTimer

public class CKTimer: ExecutableActionCard {
    public override func main() {
        // wait the number of seconds specified by our Duration input
        guard let slot = self.actionCard.descriptor.inputSlots.slot(named: "Duration") else { return }
        guard let binding = self.inputs[slot] else { return }
        guard case let .SwiftDouble(duration) = binding else { return }
        
        // wait :duration: seconds
        NSThread.sleepForTimeInterval(duration)
    }
}
