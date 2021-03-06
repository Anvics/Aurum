//
//  ImageComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 04.02.2020.
//

import Foundation
import ReactiveKit
import Bond

public class ImageData: AurumComponentData, AurumDataCreatable {
    let image: UIImage?
    let backgroundColor: UIColor?
    
    required public init(data: UIImage){
        self.image = data
        self.backgroundColor = nil
    }
    
    public init(text: UIImage? = nil, backgroundColor: UIColor? = nil) {
        self.image = text
        self.backgroundColor = backgroundColor
    }
    
    public func update(component: UIImageView){
        let c = component
        resolve(image) { c.image = $0 }
        resolve(backgroundColor) { c.backgroundColor = $0 }
    }
}

public func ==(left: ImageData, right: ImageData) -> Bool{
    return left.image == right.image &&
        left.backgroundColor == right.backgroundColor
}

extension UIImageView: AurumComponent{
    public typealias Data = ImageData
    public var event: SafeSignal<Void> { return SafeSignal(just: ()) }
}
