//
//  ExecutableActionCard.swift
//  CardKit
//
//  Created by Justin Weisz on 7/28/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

import CardKit

/// ExecutableActionCard performs the actual, executable action of an ActionCard. This class is meant to
/// be subclassed. Subclasses must override the main() method to provide their executable functioanlity.
/// This method will be called on a background thread so operations used by this method may block if desired,
/// without blocking the main app thread. This method may also spawn additional background threads, e.g.
/// using dispatch_async(). However, upon return of main(), the ExecutionEngine will consider this card
/// as having finished its execution. Therefore, you may need to block returning until background threads have
/// completed executing, e.g. using dispatch_semaphore_wait or dispatch_group_wait or other mechanics.
public class ExecutableActionCard: NSOperation, CarriesActionCardState {
    var actionCard: ActionCard
    var inputs: InputBindings = [:]
    var tokens: TokenBindings = [:]
    var yields: YieldBindings = [:]
    
    // this is 'required' so we can instantiate it from the metatype
    required public init(with card: ActionCard) {
        self.actionCard = card
    }
    
    //MARK: CarriesActionCardState
    
    func setup(inputs: InputBindings, tokens: TokenBindings) {
        self.inputs = inputs
        self.tokens = tokens
    }
    
    //MARK: NSOperation
    
    public override func main() {
        fatalError("main() method cannot be executed on ExecutableActionCard, it must be overridden in a subclass")
    }
}
