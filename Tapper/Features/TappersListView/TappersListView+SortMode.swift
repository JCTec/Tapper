import Foundation

extension TappersListView {
  enum SortMode: String, CaseIterable, Identifiable {
    case name = "Name"
    case value = "Value"
    case increment = "Increment"

    var id: Self { self }

    var systemImageName: String {
      switch self {
        case .name:
          return "textformat"
        case .value:
          return "number"
        case .increment:
          return "plus.forwardslash.minus"
      }
    }
  }
}
