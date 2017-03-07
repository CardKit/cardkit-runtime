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

public class CKTimer: ExecutableAction {
    public override func main() {
        guard let duration: Double = self.value(forInput: "Duration") else {
            return
        }
        
        // wait :duration: seconds
        Thread.sleep(forTimeInterval: duration)
    }
}
