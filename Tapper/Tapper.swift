import SwiftUI
import ColorKit
import SwiftData

@Model
final class Tapper {
  static let defaultBackgroundColorHex = "ffffff"
  static let defaultIncrement = 1

  var id: UUID = UUID()
  var name: String = ""
  var sumatory: Int = Tapper.defaultIncrement
  var allowsNegativeValue: Bool = false
  var backgroundColorHex: String = Tapper.defaultBackgroundColorHex
  var counterValue: Int = 0
    
  @Transient var backgroundUIColor: UIColor? {
    return UIColor(hex: self.backgroundColorHex) ?? UIColor(hex: Self.defaultBackgroundColorHex)
  }

  @Transient var canReduceValue: Bool {
    guard self.sumatory > 0 else { return false }
    return self.allowsNegativeValue || (self.counterValue - self.sumatory) >= 0
  }
  
  @Transient var textColor: Color {
    guard let backgroundUIColor = self.backgroundUIColor else { return .snowWhite }
    let contrastRatio = backgroundUIColor.contrastRatio(with: .dark)
    
    switch contrastRatio {
      case .acceptable, .acceptableForLargeText:
        return .dark
      default:
        return .snowWhite
    }
  }
  
  @Transient var backgroundColor: Color {
    guard let backgroundUIColor = self.backgroundUIColor else { return .snowWhite }
    return Color(uiColor: backgroundUIColor)
  }

  init(
    id: UUID = UUID(),
    name: String,
    sumatory: Int,
    allowsNegativeValue: Bool,
    backgroundColorHex: String,
    counterValue: Int
  ) {
    self.id = id
    self.name = name
    self.sumatory = sumatory
    self.allowsNegativeValue = allowsNegativeValue
    self.backgroundColorHex = backgroundColorHex
    self.counterValue = counterValue
  }
  
  init() {
    self.id = UUID()
    self.name = ""
    self.sumatory = Self.defaultIncrement
    self.allowsNegativeValue = false
    self.backgroundColorHex = Self.defaultBackgroundColorHex
    self.counterValue = 0
  }
  
  func augmentValue() {
    guard self.sumatory > 0 else { return }
    self.counterValue += self.sumatory
  }
  
  func reduceValue() {
    guard self.canReduceValue else { return }
    
    self.counterValue -= self.sumatory
  }

  func resetValue() {
    self.counterValue = 0
  }
}

extension Tapper: Hashable, Equatable {
  static func == (lhs: Tapper, rhs: Tapper) -> Bool {
      return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
      hasher.combine(id)
  }
}
