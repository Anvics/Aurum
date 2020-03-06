//
//  ButtonComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 03.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public class ButtonData: AurumComponentData, AurumDataCreatable {
    let title: String?
    let titleColor: UIColor?
    let image: UIImage?
    let backgroundImage: UIImage?
    let backgroundColor: UIColor?
    let isEnabled: Bool?
    let alpha: CGFloat?
    let isHidden: Bool?

    required public init(data: String?){
        self.title = data
        self.titleColor = nil
        self.image = nil
        self.backgroundImage = nil
        self.backgroundColor = nil
        self.isEnabled = nil
        self.alpha = nil
        self.isHidden = nil
    }

    public init(title: String? = nil, titleColor: UIColor? = nil, image: UIImage? = nil, backgroundImage: UIImage? = nil, backgroundColor: UIColor? = nil, isEnabled: Bool? = nil, alpha: CGFloat? = nil, isHidden: Bool? = nil) {
        self.title = title
        self.titleColor = titleColor
        self.image = image
        self.backgroundImage = backgroundImage
        self.backgroundColor = backgroundColor
        self.isEnabled = isEnabled
        self.alpha = alpha
        self.isHidden = isHidden
    }
    
    public func update(component: UIButton){
        let c = component
        resolve(title) { c.setTitle($0, for: .normal) }
        resolve(titleColor) { c.setTitleColor($0, for: .normal) }
        resolve(image) { c.setImage($0, for: .normal) }
        resolve(backgroundImage) { c.setBackgroundImage($0, for: .normal) }        
        resolve(backgroundColor) { c.backgroundColor = $0 }
        resolve(isEnabled) {
            c.isEnabled = $0
            if self.alpha == nil { c.alpha = $0 ? 1 : 0.5 }
        }
        resolve(alpha) { c.alpha = $0 }
        resolve(isHidden) { c.isHidden = $0 }
    }
}

public func ==(left: ButtonData, right: ButtonData) -> Bool{
    return left.title == right.title &&
        left.titleColor == right.titleColor &&
        left.image == right.image &&
        left.backgroundImage == right.backgroundImage &&
        left.backgroundColor == right.backgroundColor &&
        left.alpha == right.alpha &&
        left.isEnabled == right.isEnabled &&
        left.isHidden == right.isHidden
}

extension UIButton: AurumComponent{
    public typealias Data = ButtonData
    public typealias ProducedData = Void
    public var event: SafeSignal<ProducedData> { return reactive.tap }
}
