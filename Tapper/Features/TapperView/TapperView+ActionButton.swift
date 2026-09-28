import SwiftUI

extension TapperView {
  struct ActionButton: View {
    let action: () -> Void
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    
    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title2.weight(.bold))
          .frame(width: 80.0, height: 80.0)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
          .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius.large)
              .stroke(.primary.opacity(0.12), lineWidth: .borderWidth.standard)
          )
      })
      .buttonStyle(PressButtonStyle(scale: 0.94, dampingFraction: 0.74))
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}
