import SwiftData
import SwiftUI

struct EditTapperView: View {
  @Binding var path: NavigationPath
  @State var viewModel: ViewModel
  @Environment(\.modelContext) var modelContext
  @State private var isShowingDeleteConfirmation = false

  var body: some View {
    Form {
      PreviewCard(viewModel: self.viewModel, textColor: self.previewTextColor)

      NameSection(viewModel: self.viewModel)

      IncrementSection(viewModel: self.viewModel)

      CounterValueSection(viewModel: self.viewModel)

      BackgroundColorSection(viewModel: self.viewModel)

      if let validationMessage = self.viewModel.validationMessage {
        Section {
          Text(validationMessage)
            .font(.footnote)
            .foregroundStyle(.red)
            .accessibilityIdentifier("validationMessage")
        }
      }

      if self.viewModel.isEditing {
        DeleteSection(onDelete: {
          self.isShowingDeleteConfirmation = true
        })
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.background)
    .confirmationDialog(
      "Delete this tapper?",
      isPresented: self.$isShowingDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete Tapper", role: .destructive) {
        self.deleteTapper()
      }
      .accessibilityIdentifier("confirmDeleteTapperButton")

      Button("Cancel", role: .cancel) {}
    }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          self.cancelEditing()
        }
        .accessibilityIdentifier("cancelTapperButton")
      }

      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          self.saveTapper()
        }
        .disabled(!self.viewModel.canSave)
        .accessibilityIdentifier("saveTapperButton")
      }

      if self.viewModel.isEditing {
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .destructive, action: {
            self.isShowingDeleteConfirmation = true
          }, label: {
            Image(systemName: "trash")
          })
          .accessibilityLabel("Delete Tapper")
          .accessibilityIdentifier("deleteTapperButton")
        }
      }

      ToolbarItem(placement: .keyboard) {
        HStack(alignment: .center, spacing: .zero) {
          Spacer()

          Button(action: {
            Self.dismissKeyboard()
          }, label: {
            Text("Done")
          })
        }
      }
    }
    .alert(
      "Could not save tapper",
      isPresented: Binding(
        get: {
          self.viewModel.errorMessage != nil
        },
        set: { isPresented in
          if !isPresented {
            self.viewModel.errorMessage = nil
          }
        }
      ),
      actions: {
        Button("OK", role: .cancel) {}
      },
      message: {
        Text(self.viewModel.errorMessage ?? "Try again.")
      }
    )
  }

  func saveTapper() {
    do {
      _ = try self.viewModel.save(in: self.modelContext)
      self.closeEditor()
    } catch {
      self.viewModel.errorMessage = error.localizedDescription
    }
  }

  func deleteTapper() {
    do {
      try self.viewModel.delete(in: self.modelContext)
      self.path = NavigationPath()
    } catch {
      self.viewModel.errorMessage = error.localizedDescription
    }
  }

  func cancelEditing() {
    self.closeEditor()
  }

  func closeEditor() {
    if self.path.count > 0 {
      self.path.removeLast()
    }
  }
}

#Preview {
  NavigationStack {
    EditTapperView(path: .constant(NavigationPath()), viewModel: .init(isEditing: true))
      .navigationBarTitle("Edit Tapper")
  }
}
