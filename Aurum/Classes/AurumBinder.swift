//
//  AurumBinder.swift
//  Bond
//
//  Created by Nikita Arkhipov on 03.02.2020.
//

import Foundation
import ReactiveKit
import Bond

public class BaseComponentData{
    let forceSetNils: Bool
    
    init(forceSetNils: Bool) {
        self.forceSetNils = forceSetNils
    }
    
    func resolve<T>(_ value: T?, resolver: (T?) -> Void){
        if value != nil || forceSetNils { resolver(value) }
    }
}

public protocol UIComponent {
    associatedtype ComponentData
    associatedtype ProducedData
    
    var produced: Subject<ProducedData, Never> { get }
    
    func setup()
    
    func update(data: ComponentData)
}

public class BindingBase<S: AurumState, C: UIComponent>{
    let extractor: (S) -> C.ComponentData
    let component: C
    
    init(extractor: @escaping (S) -> C.ComponentData, component: C) {
        self.extractor = extractor
        self.component = component
    }
}

public typealias BindingSetup<S: AurumState, A: AurumAction> = (AurumStore<S, A>) -> Void

public class Binding<S: AurumState, C: UIComponent, A: AurumAction>{//: BindingSetupable {
    let extractor: (S) -> C.ComponentData
    let component: C
    let action: (C.ProducedData) -> A?
    
    init(extractor: @escaping (S) -> C.ComponentData, component: C, action: @escaping (C.ProducedData) -> A?) {
        self.extractor = extractor
        self.component = component
        self.action = action
    }
        
    func setup(store: AurumStore<S, A>) {
        component.setup()
        _ = store.state.map(extractor).observeNext { [weak self] s in
            self?.component.update(data: s)
        }
        component.produced.map(action).ignoreNils().bind(to: store.reducer)
    }
}

public class Bindings<S: AurumState, A: AurumAction>  {
    let bindings: [BindingSetup<S, A>]
    
    public init(_ bindings: BindingSetup<S, A>...) {
        self.bindings = bindings
    }
    
    private init(){
        bindings = []
    }
    
    func setup(store: AurumStore<S, A>) {
        bindings.forEach { $0(store) }
    }
    
    public static func none<S, A>() -> Bindings<S, A>{
        return Bindings<S, A>()
    }
}


public func ~><S: AurumState, C: UIComponent>(left: @escaping (S) -> C.ComponentData, right: C) -> BindingBase<S, C>{
    return BindingBase(extractor: left, component: right)
}

public func ~><S: AurumState, C: UIComponent>(left: KeyPath<S, C.ComponentData>, right: C) -> BindingBase<S, C>{
    return BindingBase(extractor: { $0[keyPath: left] }, component: right)
}

public func ~><S: AurumState, C: UIComponent, A: AurumAction>(left: BindingBase<S, C>, right: @escaping (C.ProducedData) -> A?) -> BindingSetup<S, A>{
    return Binding(extractor: left.extractor, component: left.component, action: right).setup
}

public func ~><S: AurumState, C: UIComponent, A: AurumAction>(left: BindingBase<S, C>, right: A) -> BindingSetup<S, A>{
    return Binding(extractor: left.extractor, component: left.component, action: { _ in right }).setup
}

public func ~><S: AurumState, C: UIComponent, A: AurumAction>(left: BindingBase<S, C>, right: Void) -> BindingSetup<S, A>{
    return Binding(extractor: left.extractor, component: left.component, action: { _ in nil }).setup
}
