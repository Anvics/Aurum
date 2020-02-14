//
//  AurumBinder.swift
//  Bond
//
//  Created by Nikita Arkhipov on 03.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public class AurumBinding<S: AurumState, A: AurumAction>{
    public func setup(state: Property<S>, reduce: Subject<A, Never>) { }
    public func set(animation: AurumAnimation) { }
    
    public func bindings() -> AurumBindings<S, A>{ return AurumBindings(self) }
}

public class AurumBaseComponentBinding<S: AurumState, C: AurumBaseComponent, A: AurumAction>: AurumBinding<S, A>{
    typealias Extractor = (S) -> C.BaseData?
    
    let extractor: Extractor?
    let component: C

    init(extractor: Extractor?, component: C) {
        self.extractor = extractor
        self.component = component
    }

    public override func set(animation: AurumAnimation) {
        if component.animation != nil { return }
        component.animation = animation
    }
    
    public override func setup(state: Property<S>, reduce: Subject<A, Never>) {
        if let extractor = extractor{
            let animation = component.animation ?? NoAnimation()
            _ = state.map(extractor).ignoreNils().removeDuplicates().observeNext(with: animation.with(component.baseUpdate))
        }
    }
}

public class AurumComponentBinding<S: AurumState, C: AurumComponent, A: AurumAction>: AurumBinding<S, A>{
    typealias Extractor = (S) -> C.Data?
    typealias ActionProvider = (C.Signal.Element) -> A?

    let extractor: Extractor?
    let component: C
    var action: ActionProvider?
    
    init(extractor: Extractor?, component: C) {
        self.extractor = extractor
        self.component = component
    }
    
    init(component: C, action: @escaping ActionProvider) {
        self.extractor = nil
        self.component = component
        self.action = action
    }
    
    public override func set(animation: AurumAnimation) {
        if component.animation != nil { return }
        component.animation = animation
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
}



public extension Array{
    func bindings<S, A>() -> AurumBindings<S, A> where Element == AurumBinding<S, A>{
        return AurumBindings(self)
    }
}

public class AurumBindings<S: AurumState, A: AurumAction> {
    let bindings: [AurumBinding<S, A>]
    
    public init(){
        self.bindings = []
    }
    
    public init(_ bindings: [AurumBinding<S, A>]){
        self.bindings = bindings
    }
    
    public init(_ bindings: AurumBinding<S, A>...){
        self.bindings = bindings
    }
    
    func setup(store: AurumStore<S, A>){
        bindings.forEach { $0.setup(state: store.state, reduce: store.reducer) }
    }
    
    public func with(_ animation: AurumAnimation) -> AurumBindings<S, A>{
        bindings.forEach { $0.set(animation: animation) }
        return self
    }
}

public func +<S, A>(left: AurumBinding<S, A>, right: AurumBinding<S, A>) -> AurumBindings<S, A>{
    return AurumBindings([left, right])
}

public func +<S, A>(left: AurumBindings<S, A>, right: AurumBinding<S, A>) -> AurumBindings<S, A>{
    return AurumBindings(left.bindings + [right])
}

public func +<S, A>(left: AurumBindings<S, A>, right: AurumBindings<S, A>) -> AurumBindings<S, A>{
    return AurumBindings(left.bindings + right.bindings)
}

infix operator *>: BitwiseShiftPrecedence

//Create binding Data -> BaseComponent
public func *><S: AurumState, C: AurumBaseComponent, A: AurumAction>(left: @escaping (S) -> C.BaseData?, right: C) -> AurumBaseComponentBinding<S, C, A>{
    return AurumBaseComponentBinding(extractor: left, component: right)
}

public func *><S: AurumState, C: AurumBaseComponent, A: AurumAction>(left: @escaping (S) -> C.BaseData.Data?, right: C) -> AurumBaseComponentBinding<S, C, A> where C.BaseData: AurumDataCreatable{
    return AurumBaseComponentBinding(extractor: { C.BaseData(data: left($0)) }, component: right)
}

public func *><S: AurumState, C: AurumBaseComponent, A: AurumAction>(left: KeyPath<S, C.BaseData>, right: C) -> AurumBaseComponentBinding<S, C, A>{
    return AurumBaseComponentBinding(extractor: { $0[keyPath: left] }, component: right)
}

//Create binding Data -> Component
public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: @escaping (S) -> C.Data?, right: C) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(extractor: left, component: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: @escaping (S) -> C.Data.Data?, right: C) -> AurumComponentBinding<S, C, A> where C.Data: AurumDataCreatable{
    return AurumComponentBinding(extractor: { C.Data(data: left($0)) }, component: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: KeyPath<S, C.Data>, right: C) -> AurumComponentBinding<S, C, A>{
    return AurumComponentBinding(extractor: { $0[keyPath: left] }, component: right)
}

//Create binding Component -> Action
public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: C, right: @escaping (C.Signal.Element) -> A?) -> AurumBinding<S, A>{
    return AurumComponentBinding(component: left, action: right)
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: C, right: A) -> AurumBinding<S, A>{
    return AurumComponentBinding(component: left, action: { _ in right })
}

//Create full binding (Data -> Component) -> Action
public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: AurumComponentBinding<S, C, A>, right: @escaping (C.Signal.Element) -> A?) -> AurumBinding<S, A>{
    left.action = right
    return left
}

public func *><S: AurumState, C: AurumComponent, A: AurumAction>(left: AurumComponentBinding<S, C, A>, right: A) -> AurumBinding<S, A>{
    left.action = { _ in right }
    return left
}

