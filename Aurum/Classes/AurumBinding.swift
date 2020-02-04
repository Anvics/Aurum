//
//  AurumBinder.swift
//  Bond
//
//  Created by Nikita Arkhipov on 03.02.2020.
//

import Foundation
import ReactiveKit
import Bond

public class AurumBinding<S: AurumState, A: AurumAction>{
    public func setup(state: Property<S>, reduce: Subject<A, Never>) { }
    public func set(animation: AurumAnimation) { }
}

public class AurumComponentBinding<S: AurumState, C: AurumComponent, A: AurumAction>: AurumBinding<S, A>{
    typealias Extractor = (S) -> C.Data?
    typealias ActionProvider = (C.ProducedData) -> A?
    
    var extractor: Extractor?
    let component: C
    var action: ActionProvider?

    init(extractor: @escaping Extractor, component: C) {
        self.extractor = extractor
        self.component = component
    }
    
    init(component: C, action: @escaping ActionProvider) {
        self.component = component
        self.action = action
    }
    
    public override func setup(state: Property<S>, reduce: Subject<A, Never>) {
        if let extractor = extractor{
            let animation = component.animation ?? NoAnimation()
            _ = state.map(extractor).ignoreNils().removeDuplicates().observeNext(with: animation.with(component.update))
        }
        if let action = action{
            component.event.map(action).ignoreNils().bind(to: reduce)
        }
    }
    
    public override func set(animation: AurumAnimation) {
        if component.animation != nil { return }
        component.animation = animation
    }
}

public class Bindings<S: AurumState, A: AurumAction> {
    let bindings: [AurumBinding<S, A>]
    
    public init(){
        self.bindings = []
    }
    
    public init(_ bindings: AurumBinding<S, A>...){
        self.bindings = bindings
    }
    
    func setup(store: AurumStore<S, A>){
        bindings.forEach { $0.setup(state: store.state, reduce: store.reducer) }
    }
    
    public func with(_ animation: AurumAnimation) -> Bindings<S, A>{
        bindings.forEach { $0.set(animation: animation) }
        return self
    }
}

infix operator *>: AdditionPrecedence

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: @escaping (S) -> C.Data?, right: C) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(extractor: left, component: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: KeyPath<S, C.Data>, right: C) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(extractor: { $0[keyPath: left] }, component: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: C, right: @escaping (C.ProducedData) -> A?) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(component: left, action: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: C, right: A) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(component: left, action: { _ in right })
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: AurumComponentBinding<S, C, A>, right: @escaping (C.ProducedData) -> A?) -> AurumComponentBinding<S, C, A>{
    left.action = right
    return left
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: AurumComponentBinding<S, C, A>, right: A) -> AurumComponentBinding<S, C, A>{
    left.action = { _ in right }
    return left
}
