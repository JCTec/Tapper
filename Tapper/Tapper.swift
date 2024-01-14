import SwiftUI
import ColorKit
import SwiftData

@Model
final class Tapper {
  var id: UUID = UUID()
  var name: String = ""
  var sumatory: Int = 1
  var allowsNegativeValue: Bool = false
  var backgroundColorHex: String = "ffffff"
  var counterValue: Int = 0
    
  @Transient var backgroundUIColor: UIColor? {
    return UIColor(hex: self.backgroundColorHex)
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
    guard let backgroundUIColor = self.backgroundUIColor else { return .pink }
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
    self.sumatory = 1
    self.allowsNegativeValue = false
    self.backgroundColorHex = ""
    self.counterValue = 0
  }
  
  func augmentValue() {
    self.counterValue += self.sumatory
  }
  
  func reduceValue() {
    if (self.counterValue - self.sumatory) < 0 {
      guard self.allowsNegativeValue else {
        return
      }
    }
    
    self.counterValue -= self.sumatory
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
