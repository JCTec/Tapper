import AppIntents
import SwiftUI
import SwiftData

@main
struct TapperApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Tapper.self,
    ])
    let launchArguments = ProcessInfo.processInfo.arguments
    let usesTemporaryStore = launchArguments.contains("-UITesting") || launchArguments.contains("-ShowcaseData")
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: usesTemporaryStore)
    
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

struct OpenTapperIntent: AppIntent {
  static var title: LocalizedStringResource = "Open Tapper"
  static var description = IntentDescription("Open Tapper and start counting.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    return .result()
  }
}

struct TapperShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenTapperIntent(),
      phrases: [
        "Open \(.applicationName)",
        "Start counting with \(.applicationName)"
      ],
      shortTitle: "Open Tapper",
      systemImageName: "hand.tap.fill"
    )
  }
}
