import SwiftUI

extension TapperView {
  struct TopView: View {
    let tapper: Tapper
    let onClose: () -> Void
    let onReset: () -> Void
    let onEdit: () -> Void

    var body: some View {
      HStack(spacing: .spacing.medium) {
        IconButton(
          action: self.onClose,
          imageName: "xmark",
          foregroundColor: self.tapper.textColor,
          accessibilityLabel: "Close Tapper",
          accessibilityIdentifier: "closeTapperButton"
        )

        Spacer()

        IconButton(
          action: self.onReset,
          imageName: "arrow.counterclockwise",
          foregroundColor: self.tapper.textColor,
          accessibilityLabel: "Reset Counter",
          accessibilityIdentifier: "resetTapperButton"
        )

        IconButton(
          action: self.onEdit,
          imageName: "slider.horizontal.3",
          foregroundColor: self.tapper.textColor,
          accessibilityLabel: "Edit Tapper",
          accessibilityIdentifier: "editTapperButton"
        )
      }
      .padding(.horizontal, .spacing.xLarge)
      .padding(.top, .spacing.medium)
    }
  }
}

extension TapperView.TopView {
  fileprivate struct IconButton: View {
    let action: () -> Void
    let imageName: String
    let foregroundColor: Color
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3.weight(.bold))
          .foregroundColor(self.foregroundColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.foregroundColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.plain)
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}
