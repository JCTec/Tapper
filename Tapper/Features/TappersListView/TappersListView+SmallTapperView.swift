import SwiftUI

extension TappersListView {
  struct SmallTapperView: View {
    static let minimumHeight: CGFloat = 160.0
    
    let tapper: Tapper
    
    var titleView: some View {
      VStack(alignment: .leading, spacing: .spacing.small) {
        Text(self.tapper.name)
          .font(.title2)
          .foregroundColor(self.tapper.textColor)
          .bold()
          .lineLimit(2)
          .minimumScaleFactor(0.75)
          .multilineTextAlignment(.leading)

        Text("\(self.tapper.counterValue)")
          .font(.system(size: 44.0, weight: .bold, design: .monospaced))
          .foregroundColor(self.tapper.textColor)
          .lineLimit(1)
          .minimumScaleFactor(0.45)
          .monospacedDigit()
      }
      .frame(maxWidth: .infinity, minHeight: 86.0, alignment: .leading)
    }
    
    var actionView: some View {
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
    
    var body: some View {
      VStack(spacing: .zero) {
        self.titleView
          .padding(.horizontal, .spacing.medium)
          .padding(.top, .spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
        
        self.actionView
          .padding(.horizontal, .spacing.medium)
          .padding(.top, .spacing.medium)
          .padding(.bottom, .spacing.small)
      }
      .frame(maxWidth: .infinity, minHeight: Self.minimumHeight)
      .background(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .foregroundColor(self.tapper.backgroundColor)
      )
    }
  }
}

extension TappersListView.SmallTapperView {
  fileprivate struct ActionButton: View {
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
          .font(.title3)
          .foregroundColor(self.foregroundColor)
      })
      .buttonStyle(.plain)
      .frame(width: 44.0, height: 44.0)
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }
}
