//
//  ViewComponent.swift
//  Alamofire
//
//  Created by Nikita Arkhipov on 05/02/2020.
//

import UIKit
import ReactiveKit
import Bond

public class ViewData: AurumComponentData, AurumDataCreatable{

    let backgroundColor: UIColor?
    let alpha: CGFloat?
    let isHidden: Bool?
    
    ///data = isVisible
    required public init(data: Bool?){
        self.backgroundColor = nil
        self.alpha = data?.cgfloat
        self.isHidden = nil
    }
    
    public init(backgroundColor: UIColor? = nil, alpha: CGFloat? = nil, isHidden: Bool? = nil) {
        self.backgroundColor = backgroundColor
        self.alpha = alpha
        self.isHidden = isHidden
    }
    
    public func update(component: UIView){
        let c = component
        resolve(backgroundColor) { c.backgroundColor = $0 }
        resolve(alpha) { c.alpha = $0 }
        resolve(isHidden) { c.isHidden = $0 }
    }
}

public func ==(left: ViewData, right: ViewData) -> Bool{
    return left.backgroundColor == right.backgroundColor &&
        left.isHidden == right.isHidden
}

extension UIView: AurumBaseComponent{
    public typealias BaseData = ViewData
}

extension Bool{
    var cgfloat: CGFloat{ self ? 1 : 0 }
}
