import ColorKit
import SwiftUI

extension EditTapperView {
  struct ColorPreset: Identifiable, Equatable {
    let name: String
    let hex: String

    var id: String { self.hex }

    var color: Color {
      return Color(uiColor: UIColor(hex: self.hex) ?? .white)
    }
  }
}
