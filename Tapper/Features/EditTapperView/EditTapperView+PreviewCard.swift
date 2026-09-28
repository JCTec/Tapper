import SwiftUI

extension EditTapperView {
  struct PreviewCard: View {
    let viewModel: ViewModel
    let textColor: Color

    var body: some View {
      Section {
        VStack(alignment: .leading, spacing: .spacing.small) {
          Text(self.viewModel.name.isEmpty ? "Tapper" : self.viewModel.name)
            .font(.title3.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

          Text(self.viewModel.counterValue.formatted())
            .font(.system(size: 42.0, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .contentTransition(.numericText())

          Label("Increment \(max(self.viewModel.sumatory, 1))", systemImage: "plus.forwardslash.minus")
            .font(.caption.weight(.semibold))
            .foregroundColor(self.textColor.opacity(0.72))
        }
        .foregroundColor(self.textColor)
        .frame(maxWidth: .infinity, minHeight: 118.0, alignment: .leading)
        .padding(.spacing.medium)
        .background(self.viewModel.backgroundColor, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
        .overlay(
          RoundedRectangle(cornerRadius: .cornerRadius.large)
            .stroke(self.textColor.opacity(0.14), lineWidth: .borderWidth.standard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editorPreviewCard")
      }
      .listRowBackground(Color.clear)
      .listRowInsets(EdgeInsets(top: .spacing.small, leading: .spacing.medium, bottom: .spacing.small, trailing: .spacing.medium))
    }
  }
}
