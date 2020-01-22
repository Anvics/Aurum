//
//  AurumMiddleware.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import Foundation

public typealias EmptyClosure = () -> Void

public protocol AurumMiddleware {
    func preprocess()
    
    func process(complete: EmptyClosure)
    
    func postprocess()
}

extension AurumMiddleware{
    func preprocess(){}
    
    func process(complete: EmptyClosure){ complete() }
    
    func postprocess(){}
}

public protocol AurumMiddlwareProvider {
    associatedtype State: AurumState
    associatedtype Action: AurumAction
    associatedtype InputAction: AurumAction
    associatedtype OutputAction: AurumAction

    func provide(forAction action: Action, state: State) -> [AurumMiddleware]
    
    func provide(forInputAction action: InputAction, state: State) -> [AurumMiddleware]
    func provide(forOutputAction action: OutputAction, state: State) -> [AurumMiddleware]
}

extension AurumMiddlwareProvider{
    func provide(forInputAction action: InputAction, state: State) -> [AurumMiddleware] { return [] }
    func provide(forOutputAction action: OutputAction, state: State) -> [AurumMiddleware] { return [] }
    
    func wrapped() -> AurumMiddlewareProviderWrapper<State, Action, InputAction, OutputAction>{
        return AurumMiddlewareProviderWrapper(provider: self)
    }
}

public class AurumMiddlewareProviderWrapper<State: AurumState, Action: AurumAction, InputAction: AurumAction, OutputAction: AurumAction>{
    
    typealias MiddlewareProvider = (Action, State) -> [AurumMiddleware]
    typealias InputMiddlewareProvider = (InputAction, State) -> [AurumMiddleware]
    typealias OutputMiddlewareProvider = (OutputAction, State) -> [AurumMiddleware]

    let middleware: MiddlewareProvider
    let inputMiddleware: InputMiddlewareProvider
    let outputMiddleware: OutputMiddlewareProvider
    
    init<Provider: AurumMiddlwareProvider>(provider: Provider) where Provider.State == State, Provider.Action == Action, Provider.InputAction == InputAction, Provider.OutputAction == OutputAction{
        middleware = provider.provide
        inputMiddleware = provider.provide
        outputMiddleware = provider.provide
    }
}
