import SwiftUI

struct PressButtonStyle: ButtonStyle {
  var scale: CGFloat
  var dampingFraction: Double

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? self.scale : 1.0)
      .animation(.spring(response: 0.18, dampingFraction: self.dampingFraction), value: configuration.isPressed)
  }
}
