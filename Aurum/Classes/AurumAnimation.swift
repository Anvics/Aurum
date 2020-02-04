//
//  AurumAnimation.swift
//  Aurum
//
//  Created by Nikita Arkhipov on 04.02.2020.
//

import Foundation

public protocol AurumAnimation{
    func perform(closure: @escaping () -> Void)
}

public extension AurumAnimation{
    func with<T>(_ f: @escaping (T) -> Void) -> ((T) -> Void){
        return { v in
            self.perform { f(v) }
        }
    }
}

public class NoAnimation: AurumAnimation{
    public func perform(closure: @escaping () -> Void) {
        closure()
    }
}
