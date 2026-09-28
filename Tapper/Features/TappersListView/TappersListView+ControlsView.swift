import SwiftUI

extension TappersListView {
  struct ControlsView: View {
    @Binding var sortMode: SortMode
    @Binding var searchText: String
    let showsSearch: Bool

    var body: some View {
      VStack(alignment: .leading, spacing: .spacing.small) {
        HStack {
          Menu {
            Picker("Sort By", selection: self.$sortMode) {
              ForEach(SortMode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.systemImageName)
                  .tag(mode)
              }
            }
          } label: {
            Label("Sort: \(self.sortMode.rawValue)", systemImage: "arrow.up.arrow.down")
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
              .padding(.horizontal, .spacing.medium)
              .frame(height: 40.0)
              .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
              .overlay(
                RoundedRectangle(cornerRadius: .cornerRadius.large)
                  .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
              )
          }
          .accessibilityIdentifier("sortTappersMenu")

          Spacer()
        }

        if self.showsSearch {
          SearchView(searchText: self.$searchText)
        }
      }
      .padding(.horizontal, .spacing.medium)
    }
  }
}
