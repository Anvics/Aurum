//
//  AurumController.swift
//  AmberPlayground
//
//  Created by Nikita Arkhipov on 22.01.2020.
//  Copyright © 2020 Anvics. All rights reserved.
//

import UIKit

public protocol AurumStoreSetupable {
    func set<S, A>(store: AurumStore<S, A>)
}

public protocol AurumController: class, AurumStoreSetupable {
    associatedtype State: AurumState
    associatedtype Action: AurumAction
    var store: AurumStore<State, Action>! { get set }
}

extension AurumController{
    func set<S, A>(store: AurumStore<S, A>){
        guard let s = store as? AurumStore<State, Action> else { fatalError("\(type(of: self)) failed to set store: expected <\(State.self), \(Action.self)> got <\(S.self), \(A.self)>") }
        self.store = s
    }
}

private var UIView_Associated_Embeded: UInt8 = 0
extension UIView{
    var embedded: [UIViewController]{
        get {
            return objc_getAssociatedObject(self, &UIView_Associated_Embeded) as? [UIViewController] ?? []
        }
        set {
            objc_setAssociatedObject(self, &UIView_Associated_Embeded, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func unembedAll(){
        embedded.forEach { $0.unembed(shouldModifyEmbedArray: false) }
        embedded = []
    }
}

extension UIViewController{
    public func push(_ viewController: UIViewController, animated: Bool){
        navigationController?.pushViewController(viewController, animated: animated)
    }

    public func embedIn(view: UIView, container: UIViewController){
        self.view.frame = view.bounds
        container.addChild(self)
        view.addSubview(self.view)
        view.embedded.append(self)
        didMove(toParent: container)
    }
    
    public func show(_ viewController: UIViewController, animated: Bool){
        if navigationController != nil { push(viewController, animated: true) }
        else { present(viewController, animated: true, completion: nil) }
    }
    
    public func close(animated: Bool){
        if let nav = navigationController{ nav.popViewController(animated: animated) }
        else if parent != nil { unembed() }
        else{ dismiss(animated: animated, completion: nil) }
    }
    
    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
    
    public func pop(animated: Bool){
        navigationController?.popViewController(animated: animated)
    }
    
    public func popToRoot(animated: Bool){
        navigationController?.popToRootViewController(animated: animated)
    }
    
    public func unembed(shouldModifyEmbedArray: Bool = true){
        removeFromParent()
        if let index = view.superview?.embedded.firstIndex(of: self), shouldModifyEmbedArray{
            view.superview?.embedded.remove(at: index)
        }
        view.removeFromSuperview()
        didMove(toParent: nil)
    }
    
    public func replaceWith(_ vc: UIViewController, animation: UIView.AnimationOptions){
        guard let currentVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        UIView.transition(from: currentVC.view, to: vc.view, duration: 0.4, options: animation) { _ in
            UIApplication.shared.keyWindow?.rootViewController = vc
        }
    }
}
