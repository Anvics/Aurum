//
//  AurumSimulation.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import Foundation

//public protocol SimulatedActionType {
//    func isProcessed<M: AurumModule>(module: M) -> Bool
//}
//
//public class SimulatedAction<Module: AurumModule>: SimulatedActionType{
//
//    let actions: [Module.Configurator.Reducer.Action]
//    let shouldPerform: (Module.Configurator.Reducer.State) -> Bool
//
//    public init(module: Module.Type, action: Module.Configurator.Reducer.Action, shouldPerform: @escaping (Module.Configurator.Reducer.State) -> Bool = { _ in true }) {
//        self.actions = [action]
//        self.shouldPerform = shouldPerform
//    }
//
//    public init(module: Module.Type, actions: [Module.Configurator.Reducer.Action], shouldPerform: @escaping (Module.Configurator.Reducer.State) -> Bool = { _ in true }) {
//        self.actions = actions
//        self.shouldPerform = shouldPerform
//    }
//
//    public func isProcessed<M: AurumModule>(module: M) -> Bool{
//        guard let s = module.store.state as? Module.Configurator.Reducer.State,
//            let acts = actions as? [M.Configurator.Reducer.Action],
//            M.self == Module.self && shouldPerform(s) else { return false }
//
//        acts.forEach(module.store.reduce)
//
//        return true
//    }
//}
//
//public class SimulatedActionPerformer<Module: AurumModule>: SimulatedActionType{
//
//    let shouldPerform: (Module.Configurator.Reducer.State) -> Bool
//    let actionPerformer: (Module.Configurator.Reducer.State, Module.Configurator.Actor) -> Void
//
//    public init(module: Module.Type, shouldPerform: @escaping (Module.Configurator.Reducer.State) -> Bool = { _ in true }, actionPerformer: @escaping (Module.Configurator.Reducer.State, Module.Configurator.Actor) -> Void) {
//        self.shouldPerform = shouldPerform
//        self.actionPerformer = actionPerformer
//    }
//
//    public func isProcessed<M: AurumModule>(module: M) -> Bool{
//        guard let s = module.store.state as? Module.Configurator.Reducer.State,
//            let actor = module.store.actor as? Module.Configurator.Actor,
//            M.self == Module.self && shouldPerform(s) else { return false }
//
//        actionPerformer(s, actor)
//
//        return true
//    }
//}
//
