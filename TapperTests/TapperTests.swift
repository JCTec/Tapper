import SwiftData
import XCTest
@testable import Tapper

@MainActor
final class TapperTests: XCTestCase {
  func testIncrementAddsConfiguredStep() {
    let tapper = Tapper(
      name: "Pushups",
      sumatory: 5,
      allowsNegativeValue: false,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 10
    )

    tapper.augmentValue()

    XCTAssertEqual(tapper.counterValue, 15)
  }

  func testDecrementStopsAtZeroUnlessNegativeValuesAreAllowed() {
    let nonNegativeTapper = Tapper(
      name: "Water",
      sumatory: 2,
      allowsNegativeValue: false,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 1
    )
    let negativeTapper = Tapper(
      name: "Score",
      sumatory: 2,
      allowsNegativeValue: true,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 1
    )

    nonNegativeTapper.reduceValue()
    negativeTapper.reduceValue()

    XCTAssertEqual(nonNegativeTapper.counterValue, 1)
    XCTAssertEqual(negativeTapper.counterValue, -1)
  }

  func testResetReturnsCounterToZero() {
    let tapper = Tapper(
      name: "Rounds",
      sumatory: 1,
      allowsNegativeValue: false,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 42
    )

    tapper.resetValue()

    XCTAssertEqual(tapper.counterValue, 0)
  }

  func testInvalidIncrementDoesNotMutateCounter() {
    let zeroIncrementTapper = Tapper(
      name: "Zero",
      sumatory: 0,
      allowsNegativeValue: true,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 10
    )
    let negativeIncrementTapper = Tapper(
      name: "Negative",
      sumatory: -3,
      allowsNegativeValue: true,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 10
    )

    zeroIncrementTapper.augmentValue()
    zeroIncrementTapper.reduceValue()
    negativeIncrementTapper.augmentValue()
    negativeIncrementTapper.reduceValue()

    XCTAssertEqual(zeroIncrementTapper.counterValue, 10)
    XCTAssertEqual(negativeIncrementTapper.counterValue, 10)
  }

  func testDefaultColorIsValid() {
    let tapper = Tapper()

    XCTAssertEqual(tapper.backgroundColorHex, Tapper.defaultBackgroundColorHex)
    XCTAssertNotNil(tapper.backgroundUIColor)
  }

  func testDraftValidationTrimsNameAndBuildsValues() throws {
    let viewModel = EditTapperView.ViewModel()
    viewModel.name = "  Habits  "
    viewModel.sumatory = 3
    viewModel.counterValue = 6

    let values = try viewModel.validatedValues()

    XCTAssertEqual(values.name, "Habits")
    XCTAssertEqual(values.sumatory, 3)
    XCTAssertEqual(values.counterValue, 6)
    XCTAssertFalse(values.allowsNegativeValue)
    XCTAssertFalse(values.backgroundColorHex.isEmpty)
  }

  func testDraftValidationRejectsInvalidValues() {
    let missingNameViewModel = EditTapperView.ViewModel()

    XCTAssertThrowsError(try missingNameViewModel.validatedValues()) { error in
      XCTAssertEqual(error as? EditTapperView.ValidationError, .emptyName)
    }

    let invalidIncrementViewModel = EditTapperView.ViewModel()
    invalidIncrementViewModel.name = "Steps"
    invalidIncrementViewModel.sumatory = 0

    XCTAssertThrowsError(try invalidIncrementViewModel.validatedValues()) { error in
      XCTAssertEqual(error as? EditTapperView.ValidationError, .invalidIncrement)
    }

    let invalidCounterViewModel = EditTapperView.ViewModel()
    invalidCounterViewModel.name = "Score"
    invalidCounterViewModel.counterValue = -1

    XCTAssertThrowsError(try invalidCounterViewModel.validatedValues()) { error in
      XCTAssertEqual(error as? EditTapperView.ValidationError, .invalidCounterValue)
    }
  }

  func testSaveCreatesTapper() throws {
    let container = try self.makeModelContainer()
    let viewModel = EditTapperView.ViewModel()
    viewModel.name = "Reading"
    viewModel.sumatory = 2
    viewModel.counterValue = 4

    let createdTapper = try viewModel.save(in: container.mainContext)
    let tappers = try container.mainContext.fetch(FetchDescriptor<Tapper>())

    XCTAssertEqual(tappers.count, 1)
    XCTAssertEqual(tappers.first, createdTapper)
    XCTAssertEqual(createdTapper.name, "Reading")
    XCTAssertEqual(createdTapper.sumatory, 2)
    XCTAssertEqual(createdTapper.counterValue, 4)
  }

  func testSaveUpdatesExistingTapperWithoutInsertingAnother() throws {
    let container = try self.makeModelContainer()
    let tapper = Tapper(
      name: "Old",
      sumatory: 1,
      allowsNegativeValue: false,
      backgroundColorHex: Tapper.defaultBackgroundColorHex,
      counterValue: 0
    )
    container.mainContext.insert(tapper)

    let viewModel = EditTapperView.ViewModel(tapper: tapper, isEditing: true)
    viewModel.name = "Updated"
    viewModel.sumatory = 5
    viewModel.counterValue = 15

    let savedTapper = try viewModel.save(in: container.mainContext)
    let tappers = try container.mainContext.fetch(FetchDescriptor<Tapper>())

    XCTAssertEqual(savedTapper, tapper)
    XCTAssertEqual(tappers.count, 1)
    XCTAssertEqual(tapper.name, "Updated")
    XCTAssertEqual(tapper.sumatory, 5)
    XCTAssertEqual(tapper.counterValue, 15)
  }

  private func makeModelContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: Tapper.self, configurations: config)
  }
}
