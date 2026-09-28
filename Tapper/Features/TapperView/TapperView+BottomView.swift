import SwiftUI

extension TapperView {
  struct BottomView: View {
    let tapper: Tapper
    let isCounterPulsing: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    @ScaledMetric private var counterFontSize: CGFloat = 92.0

    var body: some View {
      VStack(alignment: .center, spacing: .spacing.large) {
        Spacer()

        VStack(alignment: .center, spacing: .spacing.medium) {
          Image(systemName: "hand.tap.fill")
            .font(.system(size: 54.0, weight: .bold))
            .symbolEffect(.bounce, value: self.tapper.counterValue)

          Text(self.tapper.counterValue.formatted())
            .font(.system(size: self.counterFontSize, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.32)
            .monospacedDigit()
            .contentTransition(.numericText())
            .scaleEffect(self.isCounterPulsing ? 1.05 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: self.isCounterPulsing)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: self.tapper.counterValue)
            .accessibilityIdentifier("fullCounterValue")

          Text(self.tapper.name)
            .font(.title.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .padding(.horizontal, .spacing.large)
            .accessibilityIdentifier("fullTapperName")

          HStack(spacing: .spacing.medium) {
            Label("Increment \(self.tapper.sumatory)", systemImage: "plus.forwardslash.minus")

            if self.tapper.allowsNegativeValue {
              Label("Negatives", systemImage: "minus.circle")
            }
          }
          .font(.footnote.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.75)
          .foregroundColor(self.tapper.textColor.opacity(0.76))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, .spacing.medium)

        HStack(spacing: .spacing.large) {
          ActionButton(
            action: {
              self.onDecrement()
            },
            imageName: "minus",
            accessibilityLabel: "Decrement Counter",
            accessibilityIdentifier: "fullDecrementButton"
          )
          .disabled(!self.tapper.canReduceValue)

          ActionButton(
            action: {
              self.onIncrement()
            },
            imageName: "plus",
            accessibilityLabel: "Increment Counter",
            accessibilityIdentifier: "fullIncrementButton"
          )
        }
        .bold()

        Spacer()
      }
      .monospaced()
      .foregroundColor(self.tapper.textColor)
      .frame(maxWidth: .infinity)
    }
  }
}
