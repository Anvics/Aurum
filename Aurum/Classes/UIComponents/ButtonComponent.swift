//
//  ButtonComponent.swift
//  Bond
//
//  Created by Nikita Arkhipov on 03.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public class ButtonData: BaseComponentData{
    let title: String?
    let titleColor: UIColor?
    let image: UIImage?
    let backgroundImage: UIImage?
    let backgroundColor: UIColor?
    
    public init(title: String? = nil, titleColor: UIColor? = nil, image: UIImage? = nil, backgroundImage: UIImage? = nil, backgroundColor: UIColor? = nil, forceSetNils: Bool = false) {
        self.title = title
        self.titleColor = titleColor
        self.image = image
        self.backgroundImage = backgroundImage
        self.backgroundColor = backgroundColor
        super.init(forceSetNils: forceSetNils)
    }
    
    func update(_ b: UIButton){
        resolve(title) { b.setTitle($0, for: .normal) }
        resolve(titleColor) { b.setTitleColor($0, for: .normal) }
        resolve(image) { b.setImage($0, for: .normal) }
        resolve(backgroundImage) { b.setBackgroundImage($0, for: .normal) }
        resolve(backgroundColor) { b.backgroundColor = $0 }
    }
}

extension UIButton: UIComponent{
    private struct AssociatedKeys {
        static var Subject = "Subject"
    }

    public var produced: Subject<Void, Never> {
        if let produced = objc_getAssociatedObject(self, &UIButton.AssociatedKeys.Subject) {
            return produced as! Subject<Void, Never>
        } else {
            let produced = Subject<Void, Never>()
            objc_setAssociatedObject(self, &UIButton.AssociatedKeys.Subject, produced, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return produced
        }
    }
    
    public func setup() {
        reactive.tap.bind(to: produced)
    }
    
    public func update(data: ButtonData){
        data.update(self)
    }
}
