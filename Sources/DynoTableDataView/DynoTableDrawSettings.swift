//
//  File.swift
//  
//
//  Created by RedPanda on 9-Jan-20.
//

import Foundation
import SwiftUI

public struct DynoTableDrawSettings {
    let headerHeight : CGFloat = 60
    let minRowHeight : CGFloat = 60
    let maxRowHeight : CGFloat = 60
    let failedLoad: (Error) -> AnyView = { _ in Text("Failed to load data. Tap to retry").background(Color.red).asAnyView()}
    let waitingLoad: AnyView = Text("🕑").frame(width: 50, height: 50).asAnyView()

    let allowHide : Bool = true
    let allowResize: Bool = true
    let allowRefresh: Bool = true
    let allowResort: Bool = true
    let showMenu: Bool = true
    
    let headerBgColour: Color = Color.blue
    let gridBgColour: Color = Color.white
    let gridLineColour: Color = Color.primary
    let headerTextColour: Color = Color.white
    let gridTextColour: Color = Color.black
    let gridLineWidth: CGFloat = 1.0
}
