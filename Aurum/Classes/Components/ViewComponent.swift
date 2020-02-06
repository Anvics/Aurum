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
    let isHidden: Bool?
    
    required public init(data: Bool?){
        self.backgroundColor = nil
        self.isHidden = data
    }
    
    public init(backgroundColor: UIColor? = nil, isHidden: Bool? = nil) {
        self.backgroundColor = backgroundColor
        self.isHidden = isHidden
    }
    
    public func update(component: UIView){
        let c = component
        resolve(backgroundColor) { c.backgroundColor = $0 }
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
