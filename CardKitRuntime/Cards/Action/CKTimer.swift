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
        var duration: Double = 1.0
        
        do {
            duration = try self.value(forInput: "Duration")
        } catch let error {
            self.error = error
            return
        }
        
        // wait :duration: seconds
        Thread.sleep(forTimeInterval: duration)
    }
}
