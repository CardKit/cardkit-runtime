//
//  CKTimer.swift
//  CardKit
//
//  Created by Justin Weisz on 7/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: CKTimer

public class CKTimer: ExecutableActionCard {
    public override func main() {
        // wait the number of seconds specified by our Duration input
        guard let duration: Double = self.value(forInput: "Duration") else {
            self.error = .nilValueForInput(self, "Duration")
            return
        }
        
        // wait :duration: seconds
        Thread.sleep(forTimeInterval: duration)
    }
}
