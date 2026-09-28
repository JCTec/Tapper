import SwiftUI

extension EditTapperView {
  struct IncrementSection: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
      Section("Increment") {
        TextField(
          "1",
          value: self.$viewModel.sumatory,
          format: .number
        )
        .keyboardType(.numberPad)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("incrementField")

        Stepper(
          value: self.$viewModel.sumatory,
          in: 1...999,
          step: 1,
          label: {
            Text("Increment \(self.viewModel.sumatory)")
          }
        )
        .accessibilityIdentifier("incrementStepper")
      }
    }
  }
}
