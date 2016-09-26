//
//  CKWaitUntilTime.swift
//  CardKit
//
//  Created by Justin Weisz on 7/29/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

// MARK: CKWaitUntilTime

public class CKWaitUntilTime: ExecutableActionCard {
    public override func main() {
        // wait the given date specified by our ClockTime input
        var date: Date = Date()
        
        do {
            date = try self.value(forInput: "ClockTime")
        } catch let error {
            self.error = error
            return
        }
        
        // wait until the specified date
        Thread.sleep(until: date)
    }
}
