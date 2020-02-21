//
//  AurumListBinding.swift
//  Aurum
//
//  Created by Nikita Arkhipov on 06.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public protocol AurumListConnector: class{
    associatedtype Data: Equatable
    associatedtype Action: AurumAction
    typealias Reducer = Subject<Action, Never>
    typealias ActionListener = (Int) -> Void
    
    var reducer: Reducer? { get set }
    var actionListener: ActionListener? { get set }
    var reloadList: (() -> Void)? { get set }
    
    func update(with: [Data])
}

public protocol AurumCollectionConnector: AurumListConnector, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{ }

public protocol AurumTableConnector: AurumListConnector, UITableViewDelegate, UITableViewDataSource{ }

public class AurumCollectionBaseConnector<Model: Equatable, Cell: UICollectionViewCell, Action: AurumAction>: NSObject, AurumCollectionConnector{
    typealias Setuper = (Cell, Model, [Model], Int, Reducer) -> Void

    let setuper: Setuper
    let size: CGSize
    
    var items: [Model] = []
    
    public var reducer: Subject<Action, Never>?
    public var reloadList: (() -> Void)?
    public var actionListener: ActionListener?

    init(size: CGSize, setuper: @escaping Setuper) {
        self.size = size
        self.setuper = setuper
    }
    
    public func update(with: [Model]){
        items = with
        reloadList?()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        actionListener?(indexPath.item)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = "\(type(of: Cell.self))"
        let id = String(name.prefix(upTo: name.firstIndex(of: ".")!))
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! Cell
        cell.reactive.bag.dispose()
        let model = items[indexPath.item]
        if let reducer = reducer { setuper(cell, model, items, indexPath.item, reducer) }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize{
        return size
    }
}

public class AurumTableBaseConnector<Model: Equatable, Cell: UITableViewCell, Action: AurumAction>: NSObject, AurumTableConnector{
    typealias Setuper = (Cell, Model, [Model], Int, Reducer) -> Void

    let setuper: Setuper
    
    var items: [Model] = []
    
    public var reducer: Subject<Action, Never>?
    public var reloadList: (() -> Void)?
    public var actionListener: ActionListener?

    init(setuper: @escaping Setuper) {
        self.setuper = setuper
    }
    
    public func update(with: [Model]){
        items = with
        reloadList?()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = "\(type(of: Cell.self))"
        let id = String(name.prefix(upTo: name.firstIndex(of: ".")!))
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! Cell
        cell.reactive.bag.dispose()
        let model = items[indexPath.row]
        if let reducer = reducer { setuper(cell, model, items, indexPath.row, reducer) }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        actionListener?(indexPath.row)
    }
}

public class AurumListBinding<S: AurumState, LC: AurumListConnector>: AurumBinding<S, LC.Action>{
    typealias Extractor = (S) -> [LC.Data]
    typealias ActionProvider = (Int) -> LC.Action?

    let extractor: Extractor
    let connector: LC
    var action: ActionProvider?

    init(extractor: @escaping Extractor, connector: LC) {
        self.extractor = extractor
        self.connector = connector
    }

    public override func setup(state: Property<S>, reduce: Subject<LC.Action, Never>) {
        connector.reducer = reduce
        _ = state.map(extractor).removeDuplicates().observeNext(with: connector.update)

        if let action = action{
            connector.actionListener = { i in
                if let a = action(i){ reduce.next(a) }
            }
        }
    }
}

public class AurumCollectionProvider<Data: Equatable, Cell: UICollectionViewCell, A: AurumAction>{
    public typealias Reducer = Subject<A, Never>
    public typealias Setuper = (Cell, Data, [Data], Int, Reducer) -> Void

    let collection: UICollectionView
    let size: CGSize
    let setup: Setuper
    
    public init(_ collection: UICollectionView, size: CGSize, setup: @escaping Setuper) {
        self.collection = collection
        self.size = size
        self.setup = setup
    }
}

public class AurumTableProvider<Data: Equatable, Cell: UITableViewCell, A: AurumAction>{
    public typealias Reducer = Subject<A, Never>
    public typealias Setuper = (Cell, Data, [Data], Int, Reducer) -> Void

    let table: UITableView
    let setup: Setuper
    
    public init(_ table: UITableView, setup: @escaping Setuper) {
        self.table = table
        self.setup = setup
    }
}

//Create binding: Data -> (Collection, Connector)
//Collection
public func *><S: AurumState, LC: AurumCollectionConnector>(left: @escaping (S) -> [LC.Data], right: (UICollectionView, LC)) -> AurumListBinding<S, LC>{
    right.0.connector = right.1
    right.1.reloadList = right.0.reloadData
    return AurumListBinding(extractor: left, connector: right.1)
}

public func *><S: AurumState, D: Equatable, C: UICollectionViewCell, A: AurumAction>(left: @escaping (S) -> [D], right: AurumCollectionProvider<D, C, A>) -> AurumListBinding<S, AurumCollectionBaseConnector<D, C, A>>{
    let connector = AurumCollectionBaseConnector(size: right.size, setuper: right.setup)
    right.collection.connector = connector
    connector.reloadList = right.collection.reloadData
    return AurumListBinding(extractor: left, connector: connector)
}

//Table
public func *><S: AurumState, LC: AurumTableConnector>(left: @escaping (S) -> [LC.Data], right: (UITableView, LC)) -> AurumListBinding<S, LC>{
    right.0.connector = right.1
    right.1.reloadList = right.0.reloadData
    return AurumListBinding(extractor: left, connector: right.1)
}

public func *><S: AurumState, D: Equatable, C: UITableViewCell, A: AurumAction>(left: @escaping (S) -> [D], right: AurumTableProvider<D, C, A>) -> AurumListBinding<S, AurumTableBaseConnector<D, C, A>>{
    let connector = AurumTableBaseConnector(setuper: right.setup)
    right.table.connector = connector
    connector.reloadList = right.table.reloadData
    return AurumListBinding(extractor: left, connector: connector)
}

//Create full binding: ListBinding -> Action
public func *><S: AurumState, LC: AurumListConnector>(left: AurumListBinding<S, LC>, right: @escaping (Int) -> LC.Action?) -> AurumBinding<S, LC.Action>{
    left.action = right
    return left
}

public extension UICollectionView{
    struct AurumUICollectionViewKeys {
        static var Connector = "Connector"
    }

    var connector: NSObjectProtocol?{
        get { return objc_getAssociatedObject(self, &AurumUICollectionViewKeys.Connector) as? NSObject }
        set {
            objc_setAssociatedObject(self, &AurumUICollectionViewKeys.Connector, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            delegate = newValue as? UICollectionViewDelegateFlowLayout
            dataSource = newValue as? UICollectionViewDataSource
        }
    }
}

public extension UITableView{
    struct AurumUITableViewKeys {
        static var Connector = "Connector"
    }

    var connector: NSObjectProtocol?{
        get { return objc_getAssociatedObject(self, &AurumUITableViewKeys.Connector) as? NSObject }
        set {
            objc_setAssociatedObject(self, &AurumUITableViewKeys.Connector, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            delegate = newValue as? UITableViewDelegate
            dataSource = newValue as? UITableViewDataSource
        }
    }
}
