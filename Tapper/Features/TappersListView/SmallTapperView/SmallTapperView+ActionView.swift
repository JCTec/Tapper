import SwiftUI

extension TappersListView.SmallTapperView {
  struct ActionView: View {
    let tapper: Tapper

    var body: some View {
      HStack(spacing: .zero) {
        ActionButton(
          action: {
            self.tapper.reduceValue()
          },
          imageName: "minus",
          foregroundColor: self.tapper.textColor,
          accessibilityLabel: "Decrement \(self.tapper.name)",
          accessibilityIdentifier: "decrement-\(self.tapper.name)"
        )
        .disabled(!self.tapper.canReduceValue)
        
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.augmentValue()
          },
          imageName: "plus",
          foregroundColor: self.tapper.textColor,
          accessibilityLabel: "Increment \(self.tapper.name)",
          accessibilityIdentifier: "increment-\(self.tapper.name)"
        )
      }
      .bold()
    }
  }
}
