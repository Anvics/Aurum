//
//  AurumModuleConfigurator.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import UIKit

public protocol AurumModuleConfigurator {
    associatedtype RequiredData
    associatedtype State: AurumState
    associatedtype Action: AurumAction
    associatedtype InputAction: AurumAction
    associatedtype OutputAction: AurumAction
    
    typealias Actor = AurumActor<Action, InputAction, OutputAction>
    typealias Reducer = AurumReducerWrapper<State, Action, InputAction, OutputAction>
    typealias MiddlewareProvider = AurumMiddlewareProviderWrapper<State, Action, InputAction, OutputAction>
    
    init()
    
    func initialize(data: RequiredData) -> (State, Reducer, MiddlewareProvider, AurumLink)
    
    func didLoad<A: Actor>(state: State, actor: A)
}

public extension AurumModuleConfigurator{
    func didLoad<A: Actor>(state: State, actor: A){ }
    
    func create(data: RequiredData, rootController: UIViewController? = nil, outputListener: ((OutputAction) -> Void)? = nil) -> AurumModuleData<InputAction>{
        let (state, reducer, provider, link) = initialize(data: data)
        let vc = link.instantiate()
        let store = AurumStorePerformer(state: state, reducer: reducer, provider: provider, rootController: rootController, controller: vc, outputListener: outputListener)

        guard let vcs = vc as? AurumStoreSetupable else { fatalError("\(type(of: vc)) does not conforms to AurumController") }

        vcs.set(store: store.wrapped())

        _ = vc.view//hack to force load view

        vcs.setupBindings()

        didLoad(state: state, actor: store.actor)
        
        return AurumModuleData(controller: vc, inputActionListener: store.inputReduce)
    }
    
}

public extension AurumModuleConfigurator where RequiredData == Void{
    func create(rootController: UIViewController? = nil, outputListener: ((OutputAction) -> Void)? = nil) -> AurumModuleData<InputAction>{
        return create(data: (), rootController: rootController, outputListener: outputListener)
    }
}
