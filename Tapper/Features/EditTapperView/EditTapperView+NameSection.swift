import SwiftUI

extension EditTapperView {
  struct NameSection: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
      Section("Name") {
        TextField("Name", text: self.$viewModel.name)
          .textInputAutocapitalization(.words)
          .accessibilityIdentifier("tapperNameField")
      }
    }
  }
}
