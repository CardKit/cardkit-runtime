/**
 * Copyright 2018 IBM Corp. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
