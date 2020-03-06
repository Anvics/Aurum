//
//  ImageComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 04.02.2020.
//

import Foundation
import ReactiveKit
import Bond

public class ImageData: AurumComponentData, AurumDataCreatable{
    let image: UIImage?
    let backgroundColor: UIColor?
    let alpha: CGFloat?
    let isHidden: Bool?
    
    required public init(data: UIImage?){
        self.image = data
        self.backgroundColor = nil
        self.alpha = nil
        self.isHidden = nil
    }
    
    public init(image: UIImage? = nil, backgroundColor: UIColor? = nil, alpha: CGFloat? = nil, isHidden: Bool? = nil) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.alpha = alpha
        self.isHidden = isHidden
    }
    
    public func update(component: UIImageView){
        let c = component
        resolve(image) { c.image = $0 }
        resolve(backgroundColor) { c.backgroundColor = $0 }
        resolve(alpha) { c.alpha = $0 }
        resolve(isHidden) { c.isHidden = $0 }
    }
}

public func ==(left: ImageData, right: ImageData) -> Bool{
    return left.image == right.image &&
        left.backgroundColor == right.backgroundColor &&
        left.alpha == right.alpha &&
        left.isHidden == right.isHidden
}

extension UIImageView: AurumComponent{
    public typealias Data = ImageData
    public var event: SafeSignal<Void> { return SafeSignal(just: ()) }
}
