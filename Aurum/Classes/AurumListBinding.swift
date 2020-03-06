//
//  AurumListBinding.swift
//  Aurum
//
//  Created by Nikita Arkhipov on 06.02.2020.
//

import UIKit
import ReactiveKit
import Bond

public protocol AurumListConnectorType: class{
    associatedtype Data: Equatable
    associatedtype Action: AurumAction
    typealias Reducer = Subject<Action, Never>
    typealias CellPressedListener = (Int) -> Void
    
    var reducer: Reducer? { get set }
    var cellPressed: CellPressedListener? { get set }
    
    func update(with: [Data])
}

public protocol AurumSectionListConnectorType: AurumListConnectorType{
    associatedtype Item
    var itemsExtractor: ((Data) -> [Item])? { get set }
    var sectionPressed: CellPressedListener? { get set }
}

public class AurumCollectionConnector<Model: Equatable, Cell: UICollectionViewCell, Action: AurumAction>: NSObject, AurumListConnectorType, UICollectionViewDelegateFlowLayout{
    public typealias Setuper = (Cell, Model, [Model], Int, Reducer) -> Void
    
    let setuper: Setuper
    let size: CGSize
    
    var items: [Model] = []
    
    public var reducer: Subject<Action, Never>?
    public let reloadList: (() -> Void)
    public var cellPressed: CellPressedListener?

    public init(_ collection: UICollectionView, size: CGSize, setuper: @escaping Setuper) {
        reloadList = { [weak collection] in collection?.reloadData() }
        self.size = size
        self.setuper = setuper
        super.init()
        collection.connector = self
    }
    
    public func update(with: [Model]){
        items = with
        reloadList()
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellPressed?(indexPath.item)
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

public class AurumTableConnector<Model: Equatable, Cell: UITableViewCell, Action: AurumAction>: NSObject, AurumListConnectorType, UITableViewDelegate, UITableViewDataSource{
    public typealias Setuper = (Cell, Model, [Model], Int, Reducer) -> Void

    let setuper: Setuper
    
    var items: [Model] = []
    
    public var reducer: Subject<Action, Never>?
    public let reloadList: (() -> Void)
    public var cellPressed: CellPressedListener?

    public init(_ table: UITableView, setuper: @escaping Setuper) {
        reloadList = { [weak table] in table?.reloadData() }
        self.setuper = setuper
        super.init()
        table.connector = self
    }
    
    public func update(with: [Model]){
        items = with
        reloadList()
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
        cellPressed?(indexPath.row)
    }
}

public class AurumSectionTableConnector<Section: Equatable, Item: Equatable, SectionCell: UITableViewCell, Cell: UITableViewCell, Action: AurumAction>: NSObject, AurumSectionListConnectorType, UITableViewDelegate, UITableViewDataSource{
    
    var sections: [Section] = []
    let reloadList: (() -> Void)

    public var itemsExtractor: ((Section) -> [Item])?
    public var reducer: Subject<Action, Never>?
    public var sectionPressed: CellPressedListener?
    public var cellPressed: CellPressedListener?

    public typealias SectionCellSetuper = (SectionCell, Section, [Section], Int, Reducer) -> Void
    public typealias CellSetuper = (Cell, Item, [Item], IndexPath, Reducer) -> Void

    let sectionSetuper: SectionCellSetuper
    let setuper: CellSetuper
    let shouldAddSectionTapListener: Bool
    
    public init(_ table: UITableView, shouldAddSectionTapListener: Bool = true, sectionSetuper: @escaping SectionCellSetuper, setuper: @escaping CellSetuper) {
        reloadList = { [weak table] in table?.reloadData() }
        self.shouldAddSectionTapListener = shouldAddSectionTapListener
        self.sectionSetuper = sectionSetuper
        self.setuper = setuper
        super.init()
        table.connector = self
    }

    public func update(with: [Section]) {
        sections = with
        reloadList()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsExtractor?(sections[section]).count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = "\(type(of: SectionCell.self))"
        let id = String(name.prefix(upTo: name.firstIndex(of: ".")!))
        let cell = tableView.dequeueReusableCell(withIdentifier: id) as! SectionCell
        cell.reactive.bag.dispose()
        if shouldAddSectionTapListener{
            let button = UIButton(type: .custom)
            button.frame = cell.bounds
            button.reactive.tap.observeNext { [weak self] in
                self?.sectionPressed?(section)
            }.dispose(in: cell.reactive.bag)
            cell.addSubview(button)
        }
        let model = sections[section]
        if let reducer = reducer { sectionSetuper(cell, model, sections, section, reducer) }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = "\(type(of: Cell.self))"
        let id = String(name.prefix(upTo: name.firstIndex(of: ".")!))
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! Cell
        cell.reactive.bag.dispose()
        if let itemsExtractor = itemsExtractor,
            let reducer = reducer{
            let section = sections[indexPath.section]
            let items = itemsExtractor(section)
            let item = items[indexPath.row]
            setuper(cell, item, items, indexPath, reducer)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cellPressed?(indexPath.row)
    }
}

public class AurumListBinding<S: AurumState, LC: AurumListConnectorType>: AurumBinding<S, LC.Action>{
    typealias Extractor = (S) -> [LC.Data]
    typealias ActionProvider = (Int) -> LC.Action?

    let extractor: Extractor
    let connector: LC
    var cellAction: ActionProvider?

    init(extractor: @escaping Extractor, connector: LC) {
        self.extractor = extractor
        self.connector = connector
    }

    public override func setup(state: Property<S>, reduce: Subject<LC.Action, Never>) {
        connector.reducer = reduce
        _ = state.map(extractor).removeDuplicates().observeNext(with: connector.update)

        if let action = cellAction{
            connector.cellPressed = { i in
                if let a = action(i){ reduce.next(a) }
            }
        }
    }
}

public class AurumSectionListBinding<S: AurumState, LC: AurumSectionListConnectorType>: AurumListBinding<S, LC>{
    typealias ItemExtractor = (LC.Data) -> [LC.Item]

    var sectionAction: ActionProvider?

    init(sectionExtractor: @escaping Extractor, itemExtractor: @escaping ItemExtractor, connector: LC) {
        connector.itemsExtractor = itemExtractor
        super.init(extractor: sectionExtractor, connector: connector)
    }
    
    public override func setup(state: Property<S>, reduce: Subject<LC.Action, Never>) {
        super.setup(state: state, reduce: reduce)
        if let action = sectionAction{
            connector.sectionPressed = { i in
                if let a = action(i){ reduce.next(a) }
            }
        }
    }
}

//Create binding: Data -> Connector
public func *><S: AurumState, LC: AurumListConnectorType>(left: @escaping (S) -> [LC.Data], right: LC) -> AurumListBinding<S, LC>{
    return AurumListBinding(extractor: left, connector: right)
}

public func *><S: AurumState, LC: AurumSectionListConnectorType>(left: ((S) -> [LC.Data], (LC.Data) -> [LC.Item]), right: LC) -> AurumListBinding<S, LC>{
    return AurumSectionListBinding(sectionExtractor: left.0, itemExtractor: left.1, connector: right)
}

//Create full binding: ListBinding -> Action
public func *><S: AurumState, LC: AurumListConnectorType>(left: AurumListBinding<S, LC>, right: @escaping (Int) -> LC.Action?) -> AurumBinding<S, LC.Action>{
    left.cellAction = right
    return left
}

public func *><S: AurumState, LC: AurumSectionListConnectorType>(left: AurumSectionListBinding<S, LC>, right: ((Int) -> LC.Action?, (Int) -> LC.Action?)) -> AurumBinding<S, LC.Action>{
    left.sectionAction = right.0
    left.cellAction = right.1
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
