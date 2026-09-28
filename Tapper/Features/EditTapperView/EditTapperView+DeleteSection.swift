import SwiftUI

extension EditTapperView {
  struct DeleteSection: View {
    let onDelete: () -> Void

    var body: some View {
      Section {
        Button(role: .destructive, action: {
          self.onDelete()
        }, label: {
          Text("Delete Tapper")
        })
        .accessibilityIdentifier("deleteTapperSectionButton")
      }
    }
  }
}
