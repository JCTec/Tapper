import ColorKit
import SwiftData
import SwiftUI

extension EditTapperView {
  enum ValidationError: LocalizedError, Equatable {
    case emptyName
    case invalidIncrement
    case invalidCounterValue
    case invalidBackgroundColor

    var errorDescription: String? {
      switch self {
        case .emptyName:
          return "Name is required."
        case .invalidIncrement:
          return "Increment must be greater than zero."
        case .invalidCounterValue:
          return "Counter value cannot be negative unless negative values are allowed."
        case .invalidBackgroundColor:
          return "Choose a valid background color."
      }
    }
  }

  struct ValidatedValues: Equatable {
    let name: String
    let sumatory: Int
    let allowsNegativeValue: Bool
    let backgroundColorHex: String
    let counterValue: Int
  }

  final class ViewModel: ObservableObject {
    @Published var name: String
    @Published var sumatory: Int
    @Published var counterValue: Int
    @Published var allowsNegativeValue: Bool
    @Published var backgroundColor: Color
    @Published var errorMessage: String?
    
    let tapper: Tapper?
    
    init(tapper: Tapper = Tapper(), isEditing: Bool = false) {
      self.tapper = isEditing ? tapper : nil
      self.name = tapper.name
      self.sumatory = tapper.sumatory
      self.counterValue = tapper.counterValue
      self.allowsNegativeValue = tapper.allowsNegativeValue
      self.backgroundColor = tapper.backgroundColor
    }

    var isEditing: Bool {
      return self.tapper != nil
    }

    var validationMessage: String? {
      do {
        _ = try self.validatedValues()
        return nil
      } catch {
        return error.localizedDescription
      }
    }

    var canSave: Bool {
      return self.validationMessage == nil
    }

    func validatedValues() throws -> ValidatedValues {
      let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !trimmedName.isEmpty else {
        throw ValidationError.emptyName
      }

      guard self.sumatory > 0 else {
        throw ValidationError.invalidIncrement
      }

      guard self.allowsNegativeValue || self.counterValue >= 0 else {
        throw ValidationError.invalidCounterValue
      }

      let backgroundColorHex = UIColor(self.backgroundColor).hex

      guard UIColor(hex: backgroundColorHex) != nil else {
        throw ValidationError.invalidBackgroundColor
      }

      return ValidatedValues(
        name: trimmedName,
        sumatory: self.sumatory,
        allowsNegativeValue: self.allowsNegativeValue,
        backgroundColorHex: backgroundColorHex,
        counterValue: self.counterValue
      )
    }

    @discardableResult
    func save(in modelContext: ModelContext) throws -> Tapper {
      let values = try self.validatedValues()
      let tapper = self.tapper ?? Tapper()

      tapper.name = values.name
      tapper.sumatory = values.sumatory
      tapper.allowsNegativeValue = values.allowsNegativeValue
      tapper.backgroundColorHex = values.backgroundColorHex
      tapper.counterValue = values.counterValue

      if self.tapper == nil {
        modelContext.insert(tapper)
      }

      try modelContext.save()
      return tapper
    }

    func delete(in modelContext: ModelContext) throws {
      guard let tapper = self.tapper else { return }
      modelContext.delete(tapper)
      try modelContext.save()
    }
  }
}

struct EditTapperView: View {
  @Binding var path: NavigationPath
  @StateObject var viewModel: ViewModel
  @Environment(\.modelContext) var modelContext
  @State private var isShowingDeleteConfirmation = false

  var body: some View {
    Form {
      Section("Name") {
        TextField("Name", text: self.$viewModel.name)
          .textInputAutocapitalization(.words)
          .accessibilityIdentifier("tapperNameField")
      }
      
      Section("Increment") {
        TextField(
          "1",
          value: self.$viewModel.sumatory,
          format: .number
        )
        .keyboardType(.numberPad)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("incrementField")
      }
      
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
      }

      if let validationMessage = self.viewModel.validationMessage {
        Section {
          Text(validationMessage)
            .font(.footnote)
            .foregroundStyle(.red)
            .accessibilityIdentifier("validationMessage")
        }
      }

      if self.viewModel.isEditing {
        Section {
          Button(role: .destructive, action: {
            self.isShowingDeleteConfirmation = true
          }, label: {
            Text("Delete Tapper")
          })
          .accessibilityIdentifier("deleteTapperButton")
        }
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
      self.path.removeLast()
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
    self.path.removeLast()
  }

  static func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

#Preview {
  NavigationStack {
    EditTapperView(path: .constant(NavigationPath()), viewModel: .init(isEditing: true))
      .navigationBarTitle("Edit Tapper")
  }
}
