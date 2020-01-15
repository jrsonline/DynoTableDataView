//
//  File.swift
//  
//
//  Created by RedPanda on 9-Jan-20.
//

import Foundation
import SwiftUI
import Combine
import Dyno

extension DynoTableContent {
    public func tabulate<F>(tableState: Binding<DynoTableViewState<F>>,
                tableDataFrame: F, drawSettings: DynoTableDrawSettings) -> some View
        where F : DynoTableFrame, F.Content == Self {
        return GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(tableDataFrame.columns, id:\.self) { i in
                    self.drawColumn(i: i, geometry: geometry, tableState: tableState, drawSettings: drawSettings)
                }
                Spacer()
            }
        }
    }

    private func drawColumn<F>(i: Self.ColumnId,
                            geometry: GeometryProxy,
                            tableState: Binding<DynoTableViewState<F>>,
                            drawSettings: DynoTableDrawSettings) -> some View
        where F : DynoTableFrame, F.Content == Self {
        return Group {
            if tableState.wrappedValue.columnPositions[i] != nil {
                self.display(for: i)
                    .frame(width: tableState.wrappedValue.columnWidth(id: i, overallWidth: geometry.size.width),
                           height: geometry.size.height, alignment: .center)
                    .border(drawSettings.gridLineColour, width:drawSettings.gridLineWidth)
            }
        }
    }
}

extension DynoTableFrame {
    private static func drawHeaderWithSorter(i: Self.ColumnId,
                                             geometry: GeometryProxy,
                                             tableState: Binding<DynoTableViewState<Self>>,
                                             drawSettings: DynoTableDrawSettings) -> some View {
        let posn = tableState.wrappedValue.columnPositions[i]
        return Group {
            if posn != nil {
                ZStack {
                    Content.header(for: i).frame(width: tableState.wrappedValue.columnWidth(id: i, overallWidth: geometry.size.width),
                                                 height: drawSettings.headerHeight,
                                                 alignment: .center)
                        .foregroundColor(drawSettings.headerTextColour)
                        .border(drawSettings.gridLineColour, width: drawSettings.gridLineWidth)
                        .background(drawSettings.headerBgColour)
                    
                    if tableState.wrappedValue.sortColumn == i {
                        tableState.wrappedValue.viewForSort()
                    }
                    
                    if drawSettings.allowResize && posn! < (tableState.wrappedValue.visibleColumnCount-1)  {
                        Self.resizeHandles(rightSide: false,
                                           forColumn: i,
                                           geometry: geometry,
                                           tableState: tableState,
                                           ofHeight: drawSettings.headerHeight
                        )
                    }
                    
                    if drawSettings.allowResize && posn! > 0 {
                        Self.resizeHandles(rightSide: true,
                                           forColumn: i,
                                           geometry: geometry,
                                           tableState: tableState,
                                           ofHeight: drawSettings.headerHeight
                        )
                        
                    }
                }
            }
        }
    }
    
    private static func resizeHandles(rightSide: Bool,
                                      forColumn i:Self.ColumnId ,
                                      geometry: GeometryProxy,
                                      tableState: Binding<DynoTableViewState<Self>>,
                                      ofHeight height: CGFloat) -> some View {
        let glyph = rightSide ? "▸" : "◂"
        return HStack {
            if !rightSide {
                Spacer()
            }
            Text(glyph)
                .frame(height: height, alignment: .center)
                .background(Color.clear)
                .gesture(DragGesture()
                    .onChanged { value in tableState.wrappedValue.setColumnWidth(id: i, rightSide: !rightSide, translation: value.translation.width, overallWidth: geometry.size.width)}
            )
            .onHoverAllPlatforms { entering in
                #if os(macOS)
                if entering {
                    NSCursor.resizeLeftRight.push()
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.pop()
                }
                #endif
            }
            
            if rightSide {
                Spacer()
            }
        }.padding(.trailing, 1)
    }
    
    internal func headers(tableState: Binding<DynoTableViewState<Self>>,
                          dataLoader: DynoTableLoader<Self>,
                          drawSettings: DynoTableDrawSettings) -> some View {
        return GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(self.columns, id:\.self) { i in
                    Self.drawHeaderWithSorter(i: i, geometry: geometry, tableState: tableState, drawSettings: drawSettings)
                        .modifyIf( drawSettings.allowResort ) {
                            $0.onTapGesture {
                            tableState.wrappedValue.nextFor(newId: i)
                        }
                    }.modifyIf( drawSettings.showMenu ) { $0.contextMenu {
                        if drawSettings.allowHide {
                            Button(action: {
                                tableState.wrappedValue.hideColumn(id: i)
                            }) {
                                Text("Hide Column").disabled(tableState.wrappedValue.visibleColumnCount > 1)
                            }
                        }
                        VStack {
                            Divider()
                        }
                        if drawSettings.allowResize {
                            Button(action: {
                                tableState.wrappedValue.resetWidths()
                            }) {
                                Text("Reset Widths")
                            }
                        }
                        if drawSettings.allowHide {
                            
                            Button(action: {
                                tableState.wrappedValue.unhideColumns()
                            }) {
                                Text("Unhide All")
                            }
                        }
                        
                        if drawSettings.allowRefresh {
                            Button(action: {
                                dataLoader.load(forState: tableState)
                            }) {
                                Text("Refresh")
                            }}
                        }
                    }//modifier(HeaderMenu(column: i, tableState: tableState, dataLoader: dataLoader))  --> this doesn't work, I think a SwiftUI bug
                }
                Spacer()
            }
        }.frame(height:drawSettings.headerHeight)
    }
}


private struct HeaderMenu<Frame:DynoTableFrame>: ViewModifier {
    let column: Frame.ColumnId
    let tableState: Binding<DynoTableViewState<Frame>>
    let dataLoader: DynoTableLoader<Frame>
    
    func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: {
                self.tableState.wrappedValue.hideColumn(id: self.column)
            }) {
                Text("Hide Column").disabled(tableState.wrappedValue.visibleColumnCount > 1)
            }
            Button(action: {
            }) {
                Text("Fit Width")
            }
            VStack {
                Divider()
            }
            Button(action: {
                self.tableState.wrappedValue.unhideColumns()
            }) {
                Text("Unhide All")
            }
            Button(action: { self.dataLoader.load(forState: self.tableState)
            }) {
                Text("Refresh")
            }
        }
        
    }

}

extension View {
    func modifyIf<V:View>(_ condition: Bool, modifier: @escaping (Self) -> V) -> some View {
        Conditional(when: condition, modify: modifier, on: self)
    }
}

internal struct Conditional<V1:View, V2:View> : View {
    let when: Bool
    let modify: (V1)->(V2)
    let on: V1
    
    public var body: some View {
        ZStack {
            if when {
                modify(on)
            } else {
                on
            }
        }
    }
}
