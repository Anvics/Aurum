//
//  AurumReducer.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import Foundation

public protocol AurumState {}

public protocol AurumAction {}
public class AurumEmptyAction: AurumAction{}

public protocol AurumReducer {
    associatedtype State: AurumState
    associatedtype Action: AurumAction
    associatedtype InputAction: AurumAction
    associatedtype OutputAction: AurumAction

    typealias Actor = AurumActor<Action, InputAction, OutputAction>
    
    func reduce(state: State, action: Action, actor: Actor) -> State?
    func reduceInput(state: State, action: InputAction, actor: Actor) -> State?
}

extension AurumReducer{
    public func wrapped() -> AurumReducerWrapper<State, Action, InputAction, OutputAction>{
        return AurumReducerWrapper(reducer: self)
    }
}

public class AurumReducerWrapper<State: AurumState, Action: AurumAction, InputAction: AurumAction, OutputAction: AurumAction>{
    typealias Actor = AurumActor<Action, InputAction, OutputAction>
    
    let reduce: (State, Action, Actor) -> State?
    let reduceInput: (State, InputAction, Actor) -> State?
    
    init<R: AurumReducer>(reducer: R) where R.State == State, R.Action == Action, R.InputAction == InputAction, R.OutputAction == OutputAction{
        reduce = reducer.reduce
        reduceInput = reducer.reduceInput
    }
}
