//
//  TableDataSourceLoader.swift
//  DynoDbViewer
//
//  Created by RedPanda on 15-Nov-19.
//  Copyright © 2019 strictlyswift. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import Dyno

public struct DynoTableError : Error, Equatable {
    let msg: String
    init(msg: String) { self.msg = msg }
    init(err: Error) { self.msg = "\(err)" }
}

enum DynoTableResultState<Frame: DynoTableFrame> : Equatable {
    case empty
    case loaded(Frame)
    case error(DynoTableError)
    
}

public enum DynoTableLoaderStage<Frame:Equatable> : Equatable {
        case idle
        case refreshing
        case loadingInitialised
        case loadingUnderway
        case loadSucceeded(Frame)
        case loadFailed(DynoTableError)
    
    public func isWaiting() -> Bool {
        self == .loadingInitialised || self == .loadingUnderway
    }
}

extension Publisher {
    func map<NewOutput,NewFailure>( output: @escaping (Output) -> NewOutput, error: @escaping (Failure) -> NewFailure ) -> AnyPublisher<NewOutput, NewFailure> {
        return self.map { output($0) }
        .mapError { error($0) }
        .eraseToAnyPublisher()
    }
}

class DynoTableLoader<Frame : DynoTableFrame> : ObservableObject {
//    @Published private(set) var resultState: DynoTableResultState<Frame> = .empty
    @Published private(set) var loaderStage: DynoTableLoaderStage<Frame> = .idle
    internal var cancellable: AnyCancellable?
    
    let refreshPublisher = PassthroughSubject<DynoTableLoaderStage<Frame>,Never>()
    let dynoLoader : (Dyno, String?) -> AnyPublisher<Frame,Error>
    let table: String?
    let autoRefreshPeriod: Int?
    let 🦕 : Dyno
    let backgroundQueue: DispatchQueue
    
    init(dynoLoader: @escaping (Dyno, String?) -> AnyPublisher<Frame,Error> ,
         dyno 🦕 : Dyno,
         table: String? = nil,
         autoRefreshPeriod: Int? = nil) {
        self.table = table
        self.🦕 = 🦕
        self.dynoLoader = dynoLoader
        self.autoRefreshPeriod = autoRefreshPeriod
        self.backgroundQueue = DispatchQueue(label:"BackgroundQueue")
    }
    
    func load(forState tableState: Binding<DynoTableViewState<Frame>>) {
        self.cancellable =
            Timer.publish(every: Double(self.autoRefreshPeriod!), on: .main, in: .default)
                .autoconnect()
                .receive(on: self.backgroundQueue)
                .map { _ in DynoTableLoaderStage<Frame>.loadingUnderway }
                .catch { error in Just<DynoTableLoaderStage<Frame>>(.loadFailed(DynoTableError(err:error)))}
                .merge(with: refreshPublisher)
                .flatMap { _ in
                    self.dynoLoader(self.🦕, self.table)
                        .receive(on: self.backgroundQueue)
                        .map { frame in DynoTableLoaderStage<Frame>.loadSucceeded(frame) }
                        .catch { error in
                            Just<DynoTableLoaderStage<Frame>>(.loadFailed(DynoTableError(err:error)))
                    }
            }
            .sink { [weak self] result in
                DispatchQueue.main.async {
                    self?.loaderStage = result
                    
                    if case let .loadSucceeded(frame) = result {
                        tableState.wrappedValue.loaded(frame: frame)
                    }
                }
        }
    }
    
    /// Signal the refresh publisher to do a reload
    func reload() {
        self.🦕._resetConnection()
        refreshPublisher.send(.refreshing)
    }
    /*
// nope.. can't just look at subscription as we only subscribe once...
    func load2(forState tableState: Binding<DynoTableViewState<Frame>>) {
        self.cancellable =
            self.loader
                .handleEvents(receiveSubscription: { [weak self] s in DispatchQueue.main.async { 
                    self?.loaderStage = .loadingInitialised
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        if let ls = self?.loaderStage, ls == .loadingInitialised {
                            self?.loaderStage = .loadingUnderway
                        }
                    }
                    }
                    },receiveCancel: {
                        DispatchQueue.main.async {
                            self.loaderStage = .loadFinished
                            self.resultState = .error(DynoTableError(msg:"Cancelled"))
                        }
                })
                .sink(receiveCompletion: { [weak self] x in
                    DispatchQueue.main.async {
                        if case  .failure(let error) = x {
                            self?.loaderStage = .loadFinished
                            self?.resultState = .error(DynoTableError(err: error))
                        }
                    }
                    },
                      receiveValue:{ [weak self] frame in
                        DispatchQueue.main.async {
                            self?.resultState = .loaded(frame)
                            self?.loaderStage = .loadFinished
                            tableState.wrappedValue.loaded(frame: frame)
                        }
                })
    }
    */
    func cancel() {
        self.cancellable?.cancel()
    }
    
    deinit {
        self.cancel()
    }
    
    /// Show a simple activity spinner whilst the data is loading
    func activitySpinner() -> some View {
        Group {
            if self.loaderStage.isWaiting() {
                ActivityIndicator()
            }
            else {
                EmptyView()
            }
        }
    }
}

// From: https://jetrockets.pro/blog/activity-indicator-in-swiftui
public struct ActivityIndicator: View {
  @State private var isAnimating: Bool = false

  public var body: some View {
    GeometryReader { (geometry: GeometryProxy) in
      ForEach(0..<2) { index in
        Group {
          Circle()
            .frame(width: geometry.size.width / 4, height: geometry.size.height / 4)
            .scaleEffect(!self.isAnimating ? 1 - CGFloat(index) / 5 : 0.2 + CGFloat(index) / 5)
            .offset(y: geometry.size.width / 10 - geometry.size.height / 2)
            .foregroundColor(Color.blue)
          }.frame(width: geometry.size.width, height: geometry.size.height)
            .rotationEffect(!self.isAnimating ? .degrees(0) : .degrees(360))
            .animation(Animation
                .timingCurve(0.5, 0.15 + Double(index) / 5, 0.25, 1, duration: 1)
              .repeatForever(autoreverses: false))
        }

      }.aspectRatio(1, contentMode: .fit)
        .onAppear {
          self.isAnimating = true
        }
  }
}
