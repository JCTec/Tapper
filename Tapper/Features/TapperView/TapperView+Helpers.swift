import SwiftUI

extension TapperView {
  func playCounterFeedback() {
    self.generator.impactOccurred()

    withAnimation(.spring(response: 0.18, dampingFraction: 0.68)) {
      self.isCounterPulsing = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.86)) {
        self.isCounterPulsing = false
      }
    }
  }
}
