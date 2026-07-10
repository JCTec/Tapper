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

  struct ColorPreset: Identifiable, Equatable {
    let name: String
    let hex: String

    var id: String { self.hex }

    var color: Color {
      return Color(uiColor: UIColor(hex: self.hex) ?? .white)
    }
  }

  final class ViewModel: ObservableObject {
    static let colorPresets = [
      ColorPreset(name: "Snow", hex: "ffffff"),
      ColorPreset(name: "Lagoon", hex: "62b6cb"),
      ColorPreset(name: "Mint", hex: "84a59d"),
      ColorPreset(name: "Sun", hex: "f6bd60"),
      ColorPreset(name: "Coral", hex: "f28482"),
      ColorPreset(name: "Indigo", hex: "3d405b"),
      ColorPreset(name: "Ink", hex: "1b1b1e")
    ]

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

    var selectedBackgroundColorHex: String {
      return UIColor(self.backgroundColor).hex.lowercased()
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

    func applyColorPreset(_ preset: ColorPreset) {
      self.backgroundColor = preset.color
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

  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading, spacing: .spacing.small) {
          Text(self.viewModel.name.isEmpty ? "Tapper" : self.viewModel.name)
            .font(.title3.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)

          Text(self.viewModel.counterValue.formatted())
            .font(.system(size: 42.0, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .contentTransition(.numericText())

          Label("Increment \(max(self.viewModel.sumatory, 1))", systemImage: "plus.forwardslash.minus")
            .font(.caption.weight(.semibold))
            .foregroundColor(self.previewTextColor.opacity(0.72))
        }
        .foregroundColor(self.previewTextColor)
        .frame(maxWidth: .infinity, minHeight: 118.0, alignment: .leading)
        .padding(.spacing.medium)
        .background(self.viewModel.backgroundColor, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
        .overlay(
          RoundedRectangle(cornerRadius: .cornerRadius.large)
            .stroke(self.previewTextColor.opacity(0.14), lineWidth: .borderWidth.standard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("editorPreviewCard")
      }
      .listRowBackground(Color.clear)
      .listRowInsets(EdgeInsets(top: .spacing.small, leading: .spacing.medium, bottom: .spacing.small, trailing: .spacing.medium))

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

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44.0), spacing: .spacing.small)], spacing: .spacing.small) {
          ForEach(ViewModel.colorPresets) { preset in
            Button(action: {
              self.viewModel.applyColorPreset(preset)
            }, label: {
              RoundedRectangle(cornerRadius: .cornerRadius.large)
                .fill(preset.color)
                .frame(height: 44.0)
                .overlay(
                  RoundedRectangle(cornerRadius: .cornerRadius.large)
                    .stroke(Color.primary.opacity(self.viewModel.selectedBackgroundColorHex == preset.hex ? 0.7 : 0.14), lineWidth: self.viewModel.selectedBackgroundColorHex == preset.hex ? .borderWidth.medium : .borderWidth.standard)
                )
                .overlay {
                  if self.viewModel.selectedBackgroundColorHex == preset.hex {
                    Image(systemName: "checkmark")
                      .font(.caption.weight(.bold))
                      .foregroundStyle(.primary)
                      .padding(6.0)
                      .background(.regularMaterial, in: Circle())
                  }
                }
            })
            .buttonStyle(.plain)
            .accessibilityLabel(preset.name)
            .accessibilityIdentifier("colorPreset-\(preset.name)")
          }
        }
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
          .accessibilityIdentifier("deleteTapperSectionButton")
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
