//
//  TapperApp.swift
//  Tapper
//
//  Created by Juan Carlos on 05/01/24.
//

import SwiftUI
import SwiftData

@main
struct TapperApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Tapper.self,
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  var body: some Scene {
    WindowGroup {
      TapperNavigationView()
    }
    .modelContainer(sharedModelContainer)
  }
}
