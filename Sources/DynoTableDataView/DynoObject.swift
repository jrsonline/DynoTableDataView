//
//  DynoObject.swift
//  DynoDbViewer
//
//  Created by RedPanda on 28-Nov-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Dyno

/// Represents an arbitrary object retrieved from a DynamoDb database.
///
/// Use this if you don't want to create a specific struct to hold the retrieved object. This is generally poor practice and only used in specific cases (eg, a "general DynamoDb table reader"). Most applications would bind tables closely to Swift structs.
public struct DynoObject : Identifiable {
    let data : [String: DynoAttributeValue]
    public let id: String = UUID().uuidString
    
    init(data: [String: DynoAttributeValue]) {
        self.data = data
    }
}

extension DynoObject : DynoTableContent {
    public func display(for id: String) -> AnyView {
        guard let attribute = data[id] else { return EmptyView().asAnyView() }
        return Text(Self.attributeToString(attribute)).asAnyView()
    }
    
    static private func attributeToString(_ attr: DynoAttributeValue) -> String {
        switch attr {
        case .B(_):
            return "<binary data>"
        case .BOOL(let isTrue):
            return  isTrue ? "Yes" : "No"
        case .BS(_):
            return "<binary set>"
        case .M(let mmap):
            return mmap.map { "\($0.0)=\(Self.attributeToString($0.1))"}.joined(separator: ",")
        case .S(let string):
            return string
        case .N(let number):
            return number
        case .NS(let listOfNumbers):
            return listOfNumbers.joined(separator: ",")
        case .NULL(_):
            return "NULL"
        case .SS(let listOfStrings):
            return listOfStrings.joined(separator: ",")
        case .L(let list):
            return list.map { Self.attributeToString($0) }.joined(separator: ",")
        }
    }
    
    static public func header(for id: String) -> AnyView {
        return Text(id).asAnyView()

    }
    
    static public func sorter(for id: String?) -> ((DynoObject, DynoObject) -> Bool) {
        guard let id = id else { return {(_,_) in true} }
        
        // everything except numbers, we sort as text (including number sets, because honestly who knows what the right answer is here
        return { (a,b) in
            guard let a_attr = a.data[id], let b_attr = b.data[id] else { return true }
            switch (a_attr, b_attr) {
            case let (.N(a_n), .N(b_n)):
                guard let aAsNumber = Double(a_n), let bAsNumber = Double(b_n) else { return true }
                return aAsNumber < bAsNumber
            default:
                return self.attributeToString(a_attr) < self.attributeToString(b_attr)
            }
        }
    }
}

/// Use this when you create
public struct DynoObjectFrame : DynoTableFrame {
    
    public let columns : [String]
    public let content : [DynoObject]
    
    init(content: [[String:DynoAttributeValue]]) {
        self.columns = Self.getColumnsFromContent(content: content)
        self.content = content.map (DynoObject.init)
    }
    
    static private func getColumnsFromContent(content: [[String:DynoAttributeValue]]) -> [String] {
        // just look at the first item and infer everything from that
        // TODO: should look at them all and do the superset.
        guard let first = content.first else { return [] }
        return Array(first.keys).sorted()
    }

    static public func load(withDyno 🦕 : Dyno, fromTable table: String?) -> AnyPublisher<DynoObjectFrame,Error> {
        guard let dataTable = table else { fatalError("No data table set up for load") }
        
        return 🦕.scanToTypeDescriptors(table: dataTable)
            .compactMap { (d:DynoResult<[[String:DynoAttributeValue]]>) in
                DynoObjectFrame(content: d.result)
        }
        .eraseToAnyPublisher()
    }
    
    public typealias ColumnId = String
}
