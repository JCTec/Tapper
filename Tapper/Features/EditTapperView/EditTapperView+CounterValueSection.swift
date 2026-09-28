import SwiftUI

extension EditTapperView {
  struct CounterValueSection: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
      Section("Counter Value") {
        TextField(
          "Counter Value",
          value: self.$viewModel.counterValue,
          format: .number
        )
        .keyboardType(.numbersAndPunctuation)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("counterValueField")
      }
    }
  }
}
