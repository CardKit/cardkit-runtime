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
        guard let binding = self.valueForInput(named: "ClockTime") else {
            self.error = .nilValueForInput(self, "ClockTime")
            return
        }
        guard case let .swiftDate(date) = binding else {
            self.error = .typeMismatchForInput(self, "ClockTime", .swiftDate, binding)
            return
        }
        
        // wait until the specified date
        Thread.sleep(until: date)
    }
}
