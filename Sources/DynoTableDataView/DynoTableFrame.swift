//
//  DynoTableFrame.swift
//  DynoDbViewer
//
//  Created by RedPanda on 26-Dec-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import Foundation
import Combine
import Dyno

/// The DynoTableFrame represents a table structure (column information + row data).
///
/// You can usually instead use DynoTable which is a concrete implementation. You might use this if the Content type is
/// not Decodable, for example.
public protocol DynoTableFrame : Equatable {
    associatedtype ColumnId
    associatedtype Content : DynoTableContent where Content.ColumnId == ColumnId

    var columns: [ColumnId] { get }
    var content: [Content] { get }
    
    static func load(withDyno 🦕: Dyno, fromTable table: String?) -> AnyPublisher<Self,Error>
}

extension DynoTableFrame {
    var count : Int { get { return content.count }}
    var rows : [Content]  { get { return content }}
}
