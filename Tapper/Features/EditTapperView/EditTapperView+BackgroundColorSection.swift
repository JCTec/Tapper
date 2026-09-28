import SwiftUI

extension EditTapperView {
  struct BackgroundColorSection: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
      Section("Background Color") {
        Toggle(
          isOn: self.$viewModel.allowsNegativeValue,
          label: {
            Text("Allow Negative Values")
          }
        )
        .accessibilityIdentifier("allowNegativeValuesToggle")

        ColorPicker("Select Color", selection: self.$viewModel.backgroundColor, supportsOpacity: false)
          .accessibilityIdentifier("backgroundColorPicker")

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44.0), spacing: .spacing.small)], spacing: .spacing.small) {
          ForEach(ViewModel.colorPresets) { preset in
            Button(action: {
              self.viewModel.applyColorPreset(preset)
            }, label: {
              RoundedRectangle(cornerRadius: .cornerRadius.large)
                .fill(preset.color)
                .frame(height: 44.0)
                .overlay(
                  RoundedRectangle(cornerRadius: .cornerRadius.large)
                    .stroke(Color.primary.opacity(self.viewModel.selectedBackgroundColorHex == preset.hex ? 0.7 : 0.14), lineWidth: self.viewModel.selectedBackgroundColorHex == preset.hex ? .borderWidth.medium : .borderWidth.standard)
                )
                .overlay {
                  if self.viewModel.selectedBackgroundColorHex == preset.hex {
                    Image(systemName: "checkmark")
                      .font(.caption.weight(.bold))
                      .foregroundStyle(.primary)
                      .padding(6.0)
                      .background(.regularMaterial, in: Circle())
                  }
                }
            })
            .buttonStyle(.plain)
            .accessibilityLabel(preset.name)
            .accessibilityIdentifier("colorPreset-\(preset.name)")
          }
        }
      }
    }
  }
}
