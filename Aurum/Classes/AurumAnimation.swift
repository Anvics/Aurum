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
    public init(){}
    
    public func perform(closure: @escaping () -> Void) {
        closure()
    }
}

public class SpringAnimation: AurumAnimation{
    let duration: TimeInterval
    let delay: TimeInterval
    let dumping: CGFloat
    let velocity: CGFloat
    let options: UIView.AnimationOptions
    
    public init(duration: TimeInterval = 0.3, delay: TimeInterval = 0, dumping: CGFloat = 0.8, initialVelocity: CGFloat = 0, options: UIView.AnimationOptions = .allowUserInteraction) {
        self.duration = duration
        self.delay = delay
        self.dumping = dumping
        self.velocity = initialVelocity
        self.options = options
    }
    
    public func perform(closure: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: dumping, initialSpringVelocity: velocity, options: options, animations: closure, completion: nil)
    }
}
