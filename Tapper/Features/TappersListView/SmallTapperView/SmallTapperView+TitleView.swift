import SwiftUI

extension TappersListView.SmallTapperView {
  struct TitleView: View {
    let tapper: Tapper
    @ScaledMetric private var counterFontSize: CGFloat = 48.0

    var body: some View {
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
  }
}
