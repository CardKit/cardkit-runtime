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
        do {
            let duration: Double = try self.value(forInput: "Duration")
            
            // wait :duration: seconds
            Thread.sleep(forTimeInterval: duration)
            
        } catch let error as ActionExecutionError {
            self.error = error
            return
        } catch {
            return
        }
    }
}
