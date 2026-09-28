import SwiftUI

extension TappersListView {
  var shouldShowSearch: Bool {
    return self.tappers.count >= 10
  }

  var layout: [GridItem] {
    let minimumWidth = self.horizontalSizeClass == .regular ? Self.regularCardMinimumWidth : Self.cardMinimumWidth
    return [
      GridItem(.adaptive(minimum: minimumWidth), spacing: .spacing.medium)
    ]
  }

  var visibleTappers: [Tapper] {
    let filteredTappers = self.tappers.filter { tapper in
      guard !self.searchText.isEmpty else { return true }
      return tapper.name.localizedCaseInsensitiveContains(self.searchText)
    }

    switch self.sortMode {
      case .name:
        return filteredTappers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      case .value:
        return filteredTappers.sorted {
          if $0.counterValue == $1.counterValue {
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
          }

          return $0.counterValue > $1.counterValue
        }
      case .increment:
        return filteredTappers.sorted {
          if $0.sumatory == $1.sumatory {
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
          }

          return $0.sumatory > $1.sumatory
        }
    }
  }

  func seedShowcaseDataIfNeeded() {
    guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.tappers.isEmpty else { return }

    [
      Tapper(name: "Push-ups", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "ffd84d", counterValue: 6),
      Tapper(name: "Sit-ups", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "ef4538", counterValue: 15),
      Tapper(name: "Squats", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "62c866", counterValue: 2)
    ].forEach { tapper in
      self.modelContext.insert(tapper)
    }

    try? self.modelContext.save()
  }
}
