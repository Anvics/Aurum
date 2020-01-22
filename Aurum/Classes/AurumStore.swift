//
//  AurumStore.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import Foundation
import UIKit
import ReactiveKit

public class AurumStore<State: AurumState, Action: AurumAction>{
    let state: Property<State>
    
    private let reduceAction: (Action) -> Void
    
    init<InputAction: AurumAction, OutputAction: AurumAction>(performer: AurumStorePerformer<State, Action, InputAction, OutputAction>){
        state = performer.state
        reduceAction = performer.reduce
    }
    
    func reduce(action: Action){
        reduceAction(action)
    }
}

public class AurumStorePerformer<State: AurumState, Action: AurumAction, InputAction: AurumAction, OutputAction: AurumAction>{
    let state: Property<State>
    
    var outputListener: ((OutputAction) -> Void)?

    weak var rootController: UIViewController?
    weak var controller: UIViewController?

    typealias Actor = AurumActor<Action, InputAction, OutputAction>
    typealias Reducer = AurumReducerWrapper<State, Action, InputAction, OutputAction>
    typealias MiddlewareProvider = AurumMiddlewareProviderWrapper<State, Action, InputAction, OutputAction>
    
    private var reducer: Reducer
    private var provider: MiddlewareProvider

    lazy var actor: Actor = { Actor(rootController: rootController, controller: controller, reducer: reduce, inputReducer: inputReduce, outputReducer: outputReduce) }()

    init(state: State, reducer: Reducer, provider: MiddlewareProvider, rootController: UIViewController?, controller: UIViewController, outputListener: ((OutputAction) -> Void)?){
        self.state = Property(state)
        self.reducer = reducer
        self.provider = provider
        self.rootController = rootController
        self.controller = controller
        self.outputListener = outputListener
    }

    private func performReduction<A>(action: A, provider: (A, State) -> [AurumMiddleware], reducer: (State, A, Actor) -> State?){
        Aurum.toggled(action: action)
        let m = provider(action, state.value)

        func complete(){
            if let s = reducer(state.value, action, actor){
                state.value = s
                m.forEach { $0.postprocess() }
            }
        }

        func processAt(index: Int){
            if index == m.count { complete(); return }
            m[index].process { processAt(index: index + 1) }
        }

        m.forEach { $0.preprocess() }
        processAt(index: 0)
    }

    func reduce(action: Action){
        performReduction(action: action, provider: provider.middleware, reducer: reducer.reduce)
    }

    func inputReduce(action: InputAction){
        performReduction(action: action, provider: provider.inputMiddleware, reducer: reducer.reduceInput)
    }

    private func outputReduce(action: OutputAction){
        outputListener?(action)
    }
    
    func wrapped() -> AurumStore<State, Action>{
        return AurumStore(performer: self)
    }
}


