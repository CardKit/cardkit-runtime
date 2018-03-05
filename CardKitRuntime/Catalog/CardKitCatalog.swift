//
//  CardKitCatalog.swift
//  CardKitRuntime
//
//  Created by Justin Weisz on 8/16/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import Foundation

import CardKit

public struct CardKitCatalog: DescriptorCatalog {
    public var descriptors: [CardDescriptor] = [
        CardKit.Action.Trigger.Time.Timer,
        CardKit.Action.Trigger.Time.WaitUntilTime,
        CardKit.Deck.Repeat,
        CardKit.Deck.Terminate,
        CardKit.Hand.End.OnAll,
        CardKit.Hand.End.OnAny,
        CardKit.Hand.Logic.LogicalAnd,
        CardKit.Hand.Logic.LogicalNot,
        CardKit.Hand.Logic.LogicalOr,
        CardKit.Hand.Next.Branch,
        CardKit.Hand.Next.Repeat,
        CardKit.Input.Logical.Boolean,
        CardKit.Input.Media.Audio,
        CardKit.Input.Media.Image,
        CardKit.Input.Numeric.Integer,
        CardKit.Input.Numeric.Real,
        CardKit.Input.Raw.RawData,
        CardKit.Input.Text.TextString,
        CardKit.Input.Time.ClockTime,
        CardKit.Input.Time.Duration,
        CardKit.Input.Time.Periodicity
    ]
    
    public var executableActionTypes: [ActionCardDescriptor: ExecutableAction.Type] = [
        CardKit.Action.Trigger.Time.Timer: CKTimer.self,
        CardKit.Action.Trigger.Time.WaitUntilTime: CKWaitUntilTime.self
    ]
}
