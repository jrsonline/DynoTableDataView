//
//  TableState.swift
//  DynoDbViewer
//
//  Created by RedPanda on 15-Nov-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import Foundation
import SwiftUI
import StrictlySwiftLib


public struct DynoTableViewState<Frame:DynoTableFrame> {
    var sortColumn: Frame.ColumnId? = nil
    var order: TableSortOrder = .none
    var columnPositions: [Frame.ColumnId:Int] = [:]
    var originalColumnPositions: [Frame.ColumnId:Int] = [:]
    var columnWidthFactors: [Frame.ColumnId:CGFloat] = [:]

    mutating internal func loaded(frame: Frame) {
        self.columnPositions = Dictionary(uniqueKeysWithValues:zip(frame.columns, 0...))
        self.originalColumnPositions = self.columnPositions
        self.columnWidthFactors = Dictionary(uniqueKeysWithValues:zip(frame.columns, forever(1) ))
    }

    internal enum TableSortOrder {
        case none
        case ascending
        case descending
        
        func sortOrderGraphic() -> String {
            switch self {
            case .none: return ""
            case .ascending: return "▼"
            case .descending: return "▲"
            }
        }
        
        internal func next() -> TableSortOrder {
            switch self {
            case .none: return .descending
            case .descending: return .ascending
            case .ascending: return .none
            }
        }
    }
    
    mutating internal func nextFor(newId: Frame.ColumnId) {
        if newId == sortColumn {
            self.order = self.order.next()
        } else {
            self.sortColumn = newId
            self.order = .descending
        }
    }
    
    // Factors the available size first by the columns, and then subsequently by any column width factors
    internal func columnWidth(id: Frame.ColumnId, overallWidth: CGFloat) -> CGFloat {
        return max(overallWidth/CGFloat(visibleColumnCount)*(self.columnWidthFactors[id] ?? 1), 20)
    }
    
    mutating internal func setColumnWidth(id: Frame.ColumnId, rightSide: Bool, translation: CGFloat, overallWidth: CGFloat) {
        // we also set the neighbouring column width -- assuming we can't drag on the left of the first column or the right of the last column
        // if we are dragging on the right-hand side of a column, then the neighbour is the one with the next index.
        // if on the left, then the neighbour is the one with the prior index.
        guard let draggedColumnIndex = columnPositions[id] else { return }
        let neighbouringColumnIndex = rightSide ? draggedColumnIndex+1 : draggedColumnIndex-1
        guard let neighbouringColumn = (columnPositions.first(where: { $0.value == neighbouringColumnIndex})?.key) else { return }
        
        // arrange things so that we are effectively always dragging on the right-hand side of the column, so the neighbour is to the right.
        // ie,       COLUMN_C0   |  COLUMN_C1
        let c0 = rightSide ? id : neighbouringColumn
        let c1 = rightSide ? neighbouringColumn : id
        
        // calculate new column width... only if we don't make the column too large though
        let factorDelta = (translation < 0) ? max(translation/overallWidth * CGFloat(visibleColumnCount),
                                                  (20/overallWidth*CGFloat(visibleColumnCount) ) - self.columnWidthFactors[c0]!)
                                            : min(translation/overallWidth * CGFloat(visibleColumnCount),
                                                   self.columnWidthFactors[c1]! - (20/overallWidth*CGFloat(visibleColumnCount) ) )
        self.columnWidthFactors[c0]! += factorDelta
        self.columnWidthFactors[c1]! -= factorDelta
    }
    
    mutating internal func resetWidths() {
        for k in self.columnWidthFactors.keys {
            self.columnWidthFactors[k] = 1.0
        }
    }
    
    func sorting(_ array: [Frame.Content]) -> [Frame.Content] {
        guard self.order != .none else { return array }
        
        let sortOrder = (self.order == .descending) ? (Frame.Content.sorter(for: self.sortColumn)) : ({ (a,b) in !Frame.Content.sorter(for: self.sortColumn)(a,b) })
        return array.sorted(by: sortOrder)
    }
    
    mutating internal func hideColumn(id: Frame.ColumnId) {
        guard self.visibleColumnCount > 1 else { return }
        self.columnPositions[id] = nil
    }
    
    var visibleColumnCount : Int  { get { self.columnPositions.values.count} }
    
    mutating func unhideColumns() {
        self.columnPositions = self.originalColumnPositions
    }
    
    func viewForSort() -> some View {
        HStack {
            Spacer()
            Text(order.sortOrderGraphic())
        }
        .padding(.trailing, 12)
    }
}
