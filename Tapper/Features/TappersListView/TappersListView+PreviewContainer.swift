import SwiftUI
import SwiftData

extension _TappersListViewPreview {
  static let previewContainer: ModelContainer = {
    do {
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      let container = try ModelContainer(for: Tapper.self, configurations: config)
      
      container.mainContext.insert(
        Tapper(
          name: "Test",
          sumatory: 1,
          allowsNegativeValue: false,
          backgroundColorHex: "de5435",
          counterValue: 23
        )
      )
      
      container.mainContext.insert(
        Tapper(
          name: "Big Test",
          sumatory: 1,
          allowsNegativeValue: false,
          backgroundColorHex: "4955d6",
          counterValue: 12
        )
      )
      
      container.mainContext.insert(
        Tapper(
          name: "Even Longer Test",
          sumatory: 1,
          allowsNegativeValue: false,
          backgroundColorHex: "6ad15e",
          counterValue: 0
        )
      )
      
      container.mainContext.insert(
        Tapper(
          name: "White Test",
          sumatory: 1,
          allowsNegativeValue: false,
          backgroundColorHex: "ffffff",
          counterValue: 0
        )
      )
      
      container.mainContext.insert(
        Tapper(
          name: "Black Test",
          sumatory: 1,
          allowsNegativeValue: false,
          backgroundColorHex: "000000",
          counterValue: 0
        )
      )
      
      return container
    } catch {
      fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
    }
  }()
}
