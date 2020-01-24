//
//  AurumActor.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import UIKit

public struct AurumLink{
    let storyboard: String
    let id: String
 
    public init(storyboard: String, id: String) {
        self.storyboard = storyboard
        self.id = id
    }
    
    func instantiate() -> UIViewController{
        return UIStoryboard(name: storyboard, bundle: nil).instantiateViewController(withIdentifier: id)
    }
}

public enum AurumTransitionType{
    var isEmbedding: Bool{
        switch self {
        case .embed(_), .embedFullscreen, .cleanEmbed(_), .cleanEmbedFullscreen: return true
        default: return false
        }
    }
    
    var isCleanEmbedding: Bool{
        switch self {
        case .cleanEmbed(_), .cleanEmbedFullscreen: return true
        default: return false
        }
    }
    
    case present, push, show, baseReplace, replace(UIView.AnimationOptions), embed(UIView), embedFullscreen, cleanEmbed(UIView), cleanEmbedFullscreen
}

public enum AurumRouteCloseType{
    case close, dismiss, pop, popToRoot, unembed
}

public class AurumModuleData<A: AurumAction>{
    public let controller: UIViewController
    public let inputActionListener: (A) -> Void
    
    init(controller: UIViewController, inputActionListener: @escaping (A) -> Void) {
        self.controller = controller
        self.inputActionListener = inputActionListener
    }
}

public class AurumActor<Action: AurumAction, InputAction: AurumAction, OutputAction: AurumAction> {
    
    typealias Reducer = (Action) -> Void
    typealias InputReducer = (InputAction) -> Void
    typealias OutputReducer = (OutputAction) -> Void
    
    private weak var rootController: UIViewController?
    private weak var controller: UIViewController?

    private let reducer: Reducer
    private let inputReducer: InputReducer
    private let outputReducer: OutputReducer
    
    init(rootController: UIViewController?, controller: UIViewController?, reducer: @escaping Reducer, inputReducer: @escaping InputReducer, outputReducer: @escaping OutputReducer) {
        self.rootController = rootController ?? controller
        self.controller = controller
        self.reducer = reducer
        self.inputReducer = inputReducer
        self.outputReducer = outputReducer
    }
    
    public func reduce(_ action: Action){
        reducer(action)
    }
    
    public func output(_ action: OutputAction){
        outputReducer(action)
    }
    
    public func route(to toController: UIViewController, transition: AurumTransitionType = .show, animated: Bool = true){
        switch transition {
        case .present: rootController?.present(toController, animated: animated, completion: nil)
        case .push: rootController?.navigationController?.push(toController, animated: animated)
        case .show: rootController?.show(toController, animated: animated)
        case .baseReplace: rootController?.replaceWith(toController, animation: .transitionFlipFromLeft)
        case .replace(let animation): rootController?.replaceWith(toController, animation: animation)
        case .embedFullscreen, .cleanEmbedFullscreen:
            if transition.isCleanEmbedding { controller?.view.unembedAll() }
            if let vc = controller { toController.embedIn(view: vc.view, container: vc) }
        case .embed(let view), .cleanEmbed(let view):
            if transition.isCleanEmbedding { view.unembedAll() }
            if let vc = controller { toController.embedIn(view: view, container: vc) }
        }
    }
    
    public func route(link: AurumLink, transition: AurumTransitionType = .show, animated: Bool = true){
        route(to: link.instantiate(), transition: transition, animated: animated)
    }
    
    @discardableResult public func route<Module: AurumModuleConfigurator>(module: Module.Type, data: Module.RequiredData, transition: AurumTransitionType = .show, animated: Bool = true, outputListener: ((Module.OutputAction) -> Void)? = nil) -> AurumModuleData<Module.InputAction>{
        let config = Module()
        let data = config.create(data: data, rootController: transition.isEmbedding ? rootController : nil, outputListener: outputListener)
        route(to: data.controller, transition: transition, animated: animated)
        return data
    }
    
    @discardableResult public func route<Module: AurumModuleConfigurator>(module: Module.Type, transition: AurumTransitionType = .show, animated: Bool = true, outputListener: ((Module.OutputAction) -> Void)? = nil) -> AurumModuleData<Module.InputAction> where Module.RequiredData == Void{
        return route(module: module, data: (), transition: transition, animated: animated, outputListener: outputListener)
    }
    
    public func close(type: AurumRouteCloseType = .close, animated: Bool = true){
        switch type {
        case .close: controller?.close(animated: animated)
        case .dismiss: controller?.dismiss(animated: animated)
        case .pop: controller?.pop(animated: animated)
        case .popToRoot: controller?.popToRoot(animated: animated)
        case .unembed: controller?.unembed()
        }
    }
}
