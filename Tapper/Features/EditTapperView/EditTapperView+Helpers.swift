import SwiftUI

extension EditTapperView {
  var previewTextColor: Color {
    let previewTapper = Tapper(
      name: self.viewModel.name.isEmpty ? "Tapper" : self.viewModel.name,
      sumatory: max(self.viewModel.sumatory, 1),
      allowsNegativeValue: self.viewModel.allowsNegativeValue,
      backgroundColorHex: self.viewModel.selectedBackgroundColorHex,
      counterValue: self.viewModel.counterValue
    )

    return previewTapper.textColor
  }

  static func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
