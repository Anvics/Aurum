//
//  AurumComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 04.02.2020.
//

import Foundation
import ReactiveKit
import Bond

public protocol AurumComponentData: Equatable {
    associatedtype Component: AurumComponent
    
    func update(component: Component)
}

public extension AurumComponentData{
    func resolve<T>(_ value: T?, resolver: (T) -> Void){
        if let v = value { resolver(v) }
    }
}

public protocol AurumDataCreatable {
    associatedtype BaseData
    init(data: BaseData)
}

prefix operator ^

public prefix func ^<T: AurumDataCreatable>(value: T.BaseData) -> T{
    return T.init(data: value)
}

public protocol AurumComponent: NSObjectProtocol {
    associatedtype Data: AurumComponentData
    associatedtype ProducedData
    
    var event: SafeSignal<ProducedData> { get }

    func update(data: Data)
}

public extension AurumComponent{
    func with(_ animation: AurumAnimation) -> Self{
        self.animation = animation
        return self
    }
}

public extension AurumComponent where Data.Component == Self{
    func update(data: Data){
        data.update(component: self)
    }
}

struct AurumComponentKeys {
    static var Animation = "Content"
}

public extension AurumComponent{
    var animation: AurumAnimation? {
        get {
            if let anim = objc_getAssociatedObject(self, &AurumComponentKeys.Animation){ return anim as? AurumAnimation }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AurumComponentKeys.Animation, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
