//
//  ContentView.swift
//  DynoDbViewer
//
//  Created by RedPanda on 31-Oct-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import SwiftUI
import Dyno
import Combine

#if os(macOS)
import Cocoa
#endif


extension View {
    @inlinable public func asAnyView() -> AnyView {
        return AnyView(self)
    }
}

extension View {
    @inlinable public func onHoverAllPlatforms(perform action: @escaping (Bool) -> Void) -> some View {
        #if os(macOS)
            return self.onHover(perform: action)
        #else
            return self
        #endif
    }
}


public let DEFAULT_DYNO_TABLE_DRAW_SETTINGS = DynoTableDrawSettings()

public struct DynoTableDataView<F:DynoTableFrame>: View {
    @ObservedObject var dataLoader : DynoTableLoader<F>
    @State var tableState : DynoTableViewState<F> = DynoTableViewState()
    let drawSettings : DynoTableDrawSettings
            
    public init(dyno 🦕: Dyno,
                table: String? = nil,
                drawSettings: DynoTableDrawSettings = DEFAULT_DYNO_TABLE_DRAW_SETTINGS,
                autoRefreshPeriod: Int? = nil) {
        self.dataLoader = DynoTableLoader<F>(dynoLoader: F.load, dyno: 🦕, table: table, autoRefreshPeriod: autoRefreshPeriod)
        self.drawSettings = drawSettings
    }
    
    private func resultGrid(geometry: GeometryProxy, results: F) -> some View {
        VStack(alignment: .center, spacing:0) {
            results.headers(tableState: self.$tableState, dataLoader: self.dataLoader, drawSettings: self.drawSettings)
            ScrollView(.vertical) {
                VStack(alignment: .center, spacing:0) {
                    ForEach( self.tableState.sorting(results.content), id:\.self) { item in
                        item.tabulate(tableState: self.$tableState, tableDataFrame: results, drawSettings: self.drawSettings)
                            .frame(idealWidth: geometry.size.width, minHeight: self.drawSettings.minRowHeight, maxHeight: self.drawSettings.maxRowHeight)
                    }
                }
            }
        }
    }
    
    private func viewForLoaderState(geometry: GeometryProxy, loaderStage: DynoTableLoaderStage<F>) -> some View {
        return ZStack {
            self.showResultView(geometry: geometry, loaderStage: loaderStage)
            
            if loaderStage.isWaiting() {
                self.drawSettings.waitingLoad.asAnyView()
            }
        }
    }
    
    private func showResultView(geometry: GeometryProxy, loaderStage: DynoTableLoaderStage<F>) -> AnyView {
        switch loaderStage {
            
        case .loadFailed(let e):
            return self.drawSettings.failedLoad(e)
                .onTapGesture { self.dataLoader.reload() } //self.dataLoader.load(forState: self.$tableState)}
                .asAnyView()
            
        case .loadSucceeded(let results):
            return self.resultGrid(geometry: geometry, results: results).asAnyView()
            
        default:
            return EmptyView().asAnyView()
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            self.viewForLoaderState(geometry: geometry, loaderStage: self.dataLoader.loaderStage)
        }
        .onAppear(perform: { self.dataLoader.load(forState: self.$tableState)} )
        .onDisappear(perform: dataLoader.cancel)
    }
}

struct TableDataView_Previews: PreviewProvider {
    static var previews: some View {
        return EmptyView()
    //    TableDataView<Dinosaur>(loader: { Just( testDinos ).mapError { e in DynoError(e)}.eraseToAnyPublisher() })
    }
}

