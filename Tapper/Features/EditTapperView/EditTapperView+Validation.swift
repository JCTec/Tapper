import Foundation

extension EditTapperView {
  enum ValidationError: LocalizedError, Equatable {
    case emptyName
    case invalidIncrement
    case invalidCounterValue
    case invalidBackgroundColor

    var errorDescription: String? {
      switch self {
        case .emptyName:
          return "Name is required."
        case .invalidIncrement:
          return "Increment must be greater than zero."
        case .invalidCounterValue:
          return "Counter value cannot be negative unless negative values are allowed."
        case .invalidBackgroundColor:
          return "Choose a valid background color."
      }
    }
  }

  struct ValidatedValues: Equatable {
    let name: String
    let sumatory: Int
    let allowsNegativeValue: Bool
    let backgroundColorHex: String
    let counterValue: Int
  }
}
