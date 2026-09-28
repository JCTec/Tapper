import SwiftUI

extension TappersListView.SmallTapperView {
  struct ActionButton: View {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    let action: () -> Void
    let imageName: String
    let foregroundColor: Color
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    
    var body: some View {
      Button(action: {
        self.action()
        self.generator.impactOccurred()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3.weight(.bold))
          .foregroundColor(self.foregroundColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.foregroundColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
          .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius.medium)
              .stroke(self.foregroundColor.opacity(0.18), lineWidth: .borderWidth.standard)
          )
      })
      .buttonStyle(PressButtonStyle(scale: 0.93, dampingFraction: 0.72))
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}
