//
//  AurumListBinding.swift
//  Aurum
//
//  Created by Nikita Arkhipov on 06.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public class AurumListActionListener{
    typealias ActionListener = (IndexPath) -> Void
    
    let listener: ActionListener
    
    init(actionListener: @escaping ActionListener) {
        self.listener = actionListener
    }
}

public protocol AurumListConnector: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    associatedtype DataType: Equatable
    associatedtype CellType: UICollectionViewCell
        
    func setup(cell: CellType, data: DataType, array: [DataType], indexPath: IndexPath)
    func update(with: [DataType])
}

public class AurumListBaseConnector<D: Equatable, C: UICollectionViewCell>: NSObject, AurumListConnector{
    typealias Setuper = (C, D, [D], IndexPath) -> Void

    let setuper: Setuper    
    let size: CGSize
    
    var items: [D] = []

    init(size: CGSize, setuper: @escaping Setuper) {
        self.size = size
        self.setuper = setuper
    }
    
    public func cell(collection: UICollectionView, at: IndexPath) -> UICollectionViewCell {
        let cellType = "\(type(of: CellType.self))"
        let id = String(cellType.prefix(upTo: cellType.firstIndex(of: ".")!))
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: at) as! CellType
        let model = items[at.item]
        setup(cell: cell, data: model, array: items, indexPath: at)
        return cell
    }

    public func setup(cell: C, data: D, array: [D], indexPath: IndexPath){
        setuper(cell, data, array, indexPath)
    }

    public func update(with: [D]){
        items = with
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        actionListener?.listener(indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cell(collection: collectionView, at: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return size
    }
}

public class AurumListBinding<S: AurumState, LC: AurumListConnector, A: AurumAction>: AurumBinding<S, A>{
    typealias Extractor = (S) -> [LC.DataType]
    typealias ActionProvider = (IndexPath) -> A?

    let extractor: Extractor
    let component: UICollectionView
    let connector: LC
    var action: ActionProvider?

    init(extractor: @escaping Extractor, component: UICollectionView, connector: LC) {
        self.extractor = extractor
        self.component = component
        self.connector = connector
    }

    public override func setup(state: Property<S>, reduce: Subject<A, Never>) {
        component.delegate = connector
        component.dataSource = connector

        _ = state.map(extractor).removeDuplicates().observeNext(with: connector.update)

        if let action = action{
            connector.set { ip in
                if let a = action(ip){ reduce.next(a) }
            }
        }
    }
}

public class AurumListProvider<D: Equatable, C: UICollectionViewCell>{
    let list: UICollectionView
    let size: CGSize
    let setup: (C, D, [D], IndexPath) -> Void
    
    public init(list: UICollectionView, size: CGSize, setup: @escaping (C, D, [D], IndexPath) -> Void) {
        self.list = list
        self.size = size
        self.setup = setup
    }
}

//Create binding Data -> (Collection, Connector)
public func *><S: AurumState, LC: AurumListConnector, A: AurumAction>(left: @escaping (S) -> [LC.DataType], right: (UICollectionView, LC)) -> AurumListBinding<S, LC, A>{
    right.0.connector = right.1
    right.1.collectionView = right.0
    return AurumListBinding(extractor: left, component: right.0, connector: right.1)
}

public func *><S: AurumState, D: Equatable, C: UICollectionViewCell, A: AurumAction>(left: @escaping (S) -> [D], right: AurumListProvider<D, C>) -> AurumListBinding<S, AurumListBaseConnector<D, C>, A>{
    let connector = AurumListBaseConnector(setuper: right.setup)
    right.list.connector = connector
    connector.collectionView = right.list
    return AurumListBinding(extractor: left, component: right.list, connector: connector)
}


//Create full binding (Data -> (Collection, Connector)) -> Action
public func *><S: AurumState, LC: AurumListConnector, A: AurumAction>(left: AurumListBinding<S, LC, A>, right: @escaping (IndexPath) -> A?) -> AurumBinding<S, A>{
    left.action = right
    return left
}

struct AurumAurumListConnectorKeys {
    static var CollectionView = "CollectionView"
    static var Items = "Items"
    static var ActionListener = "ActionListener"
}

public extension AurumListConnector{
    var collectionView: UICollectionView! {
        get {
            if let collection = objc_getAssociatedObject(self, &AurumAurumListConnectorKeys.CollectionView) as? UICollectionView{ return collection }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AurumAurumListConnectorKeys.CollectionView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var actionListener: AurumListActionListener?{
        get {
            if let listener = objc_getAssociatedObject(self, &AurumAurumListConnectorKeys.ActionListener) as? AurumListActionListener{ return listener }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AurumAurumListConnectorKeys.ActionListener, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func set(actionListener: @escaping (IndexPath) -> Void){
        self.actionListener = AurumListActionListener(actionListener: actionListener)
    }
}

struct AurumUICollectionViewKeys {
    static var Connector = "Connector"
}

public extension UICollectionView{
    var connector: NSObjectProtocol?{
        get {
            if let connector = objc_getAssociatedObject(self, &AurumUICollectionViewKeys.Connector) as? NSObject{ return connector }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AurumUICollectionViewKeys.Connector, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
