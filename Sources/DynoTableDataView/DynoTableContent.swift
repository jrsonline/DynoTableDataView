//
//  TableDataSource.swift
//  DynoDbViewer
//
//  Created by RedPanda on 15-Nov-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Dyno

/// Items which you want to represent in a DynoTableDataView need to conform to DynoTableContent (ie, the rows).
///
/// If you don't need a special representation of an object/row, and you are OK with the default from
/// Dyno, instead use DynoDataFrame to load the objects (then, you don't need to have a type conforming to DynoTableContent).
public protocol DynoTableContent: Hashable {
    associatedtype ColumnId : Hashable
    func display(for id: ColumnId) -> AnyView
    
    static func header(for id: ColumnId) -> AnyView
    static func sorter(for id: ColumnId?) -> ((Self,Self) -> Bool)
}



/// DynoTable<C> represents a table containing content of type C. DynoTable conforms to DynoTableFrame.
///
/// DynoTable<C> creates a default loader, leveraging the fact that C is Decodable.
///
/// You might use it like this:
///
///     let contentView =
///         DynoTableDataView<DynoTable<Dinosaur>>(dyno: Dyno(), table:"Dinosaurs")
public struct DynoTable<C>
where C : DynoTableContent, C : Decodable, C.ColumnId : CaseIterable
{
    public var content : [C] = []
}

extension DynoTable : DynoTableFrame
where  C.ColumnId : CaseIterable {
    public var columns : [C.ColumnId] { get { Array(C.ColumnId.allCases) }}

    static public func load(withDyno 🦕: Dyno, fromTable table: String?) -> AnyPublisher<Self,Error> {
        guard let table = table else { fatalError("DynoDataFrame.load must be passed a table to load from") }
        return 🦕.scan(table: table,
                         type: C.self)
            .map { Self(content:$0.result) }
            .eraseToAnyPublisher()
    }
}


