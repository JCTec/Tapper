import ColorKit
import Observation
import SwiftData
import SwiftUI

extension EditTapperView {
  @Observable
  final class ViewModel {
    static let colorPresets = [
      ColorPreset(name: "Snow", hex: "ffffff"),
      ColorPreset(name: "Lagoon", hex: "62b6cb"),
      ColorPreset(name: "Mint", hex: "84a59d"),
      ColorPreset(name: "Sun", hex: "f6bd60"),
      ColorPreset(name: "Coral", hex: "f28482"),
      ColorPreset(name: "Indigo", hex: "3d405b"),
      ColorPreset(name: "Ink", hex: "1b1b1e")
    ]

    var name: String
    var sumatory: Int
    var counterValue: Int
    var allowsNegativeValue: Bool
    var backgroundColor: Color
    var errorMessage: String?

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
