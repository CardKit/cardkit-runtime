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
        do {
            let date: Date = try self.value(forInput: "ClockTime")
            
            // wait until the specified date
            Thread.sleep(until: date)
            
        } catch let error as ActionExecutionError {
            self.error = error
            return
        } catch {
            return
        }
    }
}
