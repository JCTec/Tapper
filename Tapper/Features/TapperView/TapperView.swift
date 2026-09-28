//
//  TapperView.swift
//  Tapper
//
//  Created by Juan Carlos on 05/01/24.
//

import SwiftUI

struct TapperView: View {
  @Binding var path: NavigationPath
  
  let generator = UIImpactFeedbackGenerator(style: .heavy)

  var tapper: Tapper
  @State private var isShowingResetConfirmation = false
  @State var isCounterPulsing = false

  var body: some View {
    ZStack(alignment: .topLeading) {
      self.tapper.backgroundColor
        .ignoresSafeArea(.all)
        .onTapGesture {
          self.incrementTapper()
        }
        .onLongPressGesture {
          self.decrementTapper()
        }
      
      TopView(
        tapper: self.tapper,
        onClose: {
          self.closeTapper()
        },
        onReset: {
          self.isShowingResetConfirmation = true
        },
        onEdit: {
          self.editTapper()
        }
      )
      
      BottomView(
        tapper: self.tapper,
        isCounterPulsing: self.isCounterPulsing,
        onIncrement: {
          self.incrementTapper()
        },
        onDecrement: {
          self.decrementTapper()
        }
      )
    }
    .confirmationDialog(
      "Reset this counter?",
      isPresented: self.$isShowingResetConfirmation,
      titleVisibility: .visible
    ) {
      Button("Reset Counter", role: .destructive) {
        self.resetTapper()
      }
      .accessibilityIdentifier("confirmResetTapperButton")

      Button("Cancel", role: .cancel) {}
    }
  }

  func closeTapper() {
    if self.path.count > 0 {
      self.path.removeLast()
    }
  }

  func editTapper() {
    self.path.append(TapperCoordinator.editTapper(self.tapper))
  }

  func incrementTapper() {
    self.tapper.augmentValue()
    self.playCounterFeedback()
  }

  func decrementTapper() {
    let previousValue = self.tapper.counterValue
    self.tapper.reduceValue()

    if self.tapper.counterValue != previousValue {
      self.playCounterFeedback()
    }
  }

  func resetTapper() {
    let previousValue = self.tapper.counterValue
    self.tapper.resetValue()

    if previousValue != self.tapper.counterValue {
      self.playCounterFeedback()
    }
  }
}

#Preview {
  TapperView(
    path: .constant(NavigationPath()),
    tapper: Tapper(
      id: UUID(),
      name: "Taps",
      sumatory: 1,
      allowsNegativeValue: false,
      backgroundColorHex: "630b52",
      counterValue: 1
    )
  )
}
