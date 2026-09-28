import SwiftUI

extension TappersListView {
  struct SearchView: View {
    @Binding var searchText: String

    var body: some View {
      HStack(spacing: .spacing.small) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)

        TextField("Find a tapper", text: self.$searchText)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .accessibilityIdentifier("searchTappersField")

        if !self.searchText.isEmpty {
          Button(action: {
            self.searchText = ""
          }, label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          })
          .buttonStyle(.plain)
          .accessibilityLabel("Clear Search")
          .accessibilityIdentifier("clearSearchButton")
        }
      }
      .padding(.horizontal, .spacing.medium)
      .frame(height: 44.0)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      .overlay(
        RoundedRectangle(cornerRadius: .cornerRadius.large)
          .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
      )
    }
  }
}
