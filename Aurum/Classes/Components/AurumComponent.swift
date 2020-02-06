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
    associatedtype Component: AurumBaseComponent
    
    func update(component: Component)
}

func resolve<T>(_ value: T?, resolver: (T) -> Void){
    if let v = value { resolver(v) }
}

public protocol AurumDataCreatable {
    associatedtype Data
    init(data: Data?)
}

public protocol AurumBaseComponent: NSObjectProtocol {
    associatedtype BaseData: AurumComponentData where BaseData.Component == Self
}

public protocol AurumComponent: AurumBaseComponent {
    associatedtype Data: AurumComponentData where Data.Component == Self
    associatedtype ProducedData
    var event: SafeSignal<ProducedData> { get }
}

struct AurumComponentKeys {
    static var Animation = "Animation"
}

public extension AurumBaseComponent{
    func with(_ animation: AurumAnimation) -> Self{
        self.animation = animation
        return self
    }
    
    func baseUpdate(data: BaseData){
        data.update(component: self)
    }
    
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

public extension AurumComponent{
    func update(data: Data){
        data.update(component: self)
    }
}
