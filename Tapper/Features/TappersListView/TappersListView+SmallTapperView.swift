import SwiftUI

extension TappersListView {
  struct SmallTapperView: View {
    static let minimumHeight: CGFloat = 204.0
    
    let tapper: Tapper
    @ScaledMetric private var counterFontSize: CGFloat = 48.0
    
    var titleView: some View {
      VStack(alignment: .leading, spacing: .spacing.small) {
        HStack(alignment: .top, spacing: .spacing.small) {
          Image(systemName: "hand.tap.fill")
            .font(.subheadline.weight(.bold))
            .foregroundColor(self.tapper.textColor.opacity(0.82))
            .frame(width: 28.0, height: 28.0)
            .background(self.tapper.textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.medium))

          Text(self.tapper.name)
            .font(.title3.weight(.bold))
            .foregroundColor(self.tapper.textColor)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .multilineTextAlignment(.leading)
        }

        Text(self.tapper.counterValue.formatted())
          .font(.system(size: self.counterFontSize, weight: .bold, design: .monospaced))
          .foregroundColor(self.tapper.textColor)
          .lineLimit(1)
          .minimumScaleFactor(0.45)
          .monospacedDigit()
          .contentTransition(.numericText())
          .animation(.spring(response: 0.26, dampingFraction: 0.82), value: self.tapper.counterValue)

        HStack(spacing: .spacing.small) {
          Label("Increment \(self.tapper.sumatory)", systemImage: "plus.forwardslash.minus")

          if self.tapper.allowsNegativeValue {
            Label("Negative", systemImage: "minus.circle")
          }
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(self.tapper.textColor.opacity(0.72))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      }
      .frame(maxWidth: .infinity, minHeight: 116.0, alignment: .leading)
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
      .overlay(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .stroke(self.tapper.textColor.opacity(0.14), lineWidth: .borderWidth.standard)
      )
      .shadow(color: self.tapper.backgroundColor.opacity(0.22), radius: 14.0, x: 0.0, y: 7.0)
      .accessibilityElement(children: .contain)
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
          .font(.title3.weight(.bold))
          .foregroundColor(self.foregroundColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.foregroundColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.medium))
          .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius.medium)
              .stroke(self.foregroundColor.opacity(0.18), lineWidth: .borderWidth.standard)
          )
      })
      .buttonStyle(TapperPressButtonStyle())
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }

  fileprivate struct TapperPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.72), value: configuration.isPressed)
    }
  }
}
