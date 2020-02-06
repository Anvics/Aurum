//
//  LabelComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 04.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public class LabelData: AurumComponentData, AurumDataCreatable{
    let text: String?
    let textColor: UIColor?
    let font: UIFont?
    let backgroundColor: UIColor?
    let isHidden: Bool?
    
    required public init(data: String?){
        self.text = data
        self.textColor = nil
        self.font = nil
        self.backgroundColor = nil
        self.isHidden = nil
    }
 
    public init(text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, backgroundColor: UIColor? = nil, isHidden: Bool? = nil) {
        self.text = text
        self.textColor = textColor
        self.font = font
        self.backgroundColor = backgroundColor
        self.isHidden = isHidden
    }
    
    public func update(component: UILabel){
        let c = component
        resolve(text) { c.text = $0 }
        resolve(textColor) { c.textColor = $0 }
        resolve(font) { c.font = $0 }
        resolve(backgroundColor) { c.backgroundColor = $0 }
        resolve(isHidden) { c.isHidden = $0 }
    }
}

public func ==(left: LabelData, right: LabelData) -> Bool{
    return left.text == right.text &&
        left.textColor == right.textColor &&
        left.font == right.font &&
        left.backgroundColor == right.backgroundColor &&
        left.isHidden == right.isHidden
}

extension UILabel: AurumComponent{
    public typealias Data = LabelData
    public var event: SafeSignal<Void> { return SafeSignal(just: ()) }
}
