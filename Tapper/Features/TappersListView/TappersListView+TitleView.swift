import SwiftUI

extension TappersListView {
  struct TitleView: View {
    let onAdd: () -> Void

    var body: some View {
      HStack(alignment: .center, spacing: .zero) {
        VStack(alignment: .leading, spacing: .spacing.small) {
          Text("Tappers")
            .font(.largeTitle)
            .bold()

          Text("Count anything. Keep the rhythm.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        
        Spacer()
        
        Button(action: {
          self.onAdd()
        }, label: {
          Image(systemName: "plus")
            .font(.title3)
            .frame(width: 44.0, height: 44.0)
            .background(Color.text.opacity(0.08), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
        })
        .buttonStyle(.plain)
        .accessibilityLabel("Add Tapper")
        .accessibilityIdentifier("addTapperButton")
      }
      .padding(.horizontal, .spacing.large)
    }
  }
}
