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
        guard let binding = self.valueForInput(named: "Duration") else {
            self.error = .NilValueForInput(self, "Duration")
            return
        }
        guard case let .SwiftDouble(duration) = binding else {
            self.error = .TypeMismatchForInput(self, "Duration", .SwiftDouble, binding)
            return
        }
        
        // wait :duration: seconds
        NSThread.sleepForTimeInterval(duration)
    }
}
