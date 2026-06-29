//
//  ContentView.swift
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
  
  var topView: some View {
    HStack(spacing: .spacing.medium) {
      Button(action: {
        self.closeTapper()
      }, label: {
        Image(systemName: "multiply.circle.fill")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
          .bold()
      })
      .accessibilityLabel("Close Tapper")
      .accessibilityIdentifier("closeTapperButton")
      
      Spacer()

      Button(action: {
        self.isShowingResetConfirmation = true
      }, label: {
        Image(systemName: "arrow.counterclockwise.circle.fill")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
          .bold()
      })
      .accessibilityLabel("Reset Counter")
      .accessibilityIdentifier("resetTapperButton")
      
      Button(action: {
        self.path.append(TapperCoordinator.editTapper(self.tapper))
      }, label: {
        Image(systemName: "info.circle.fill")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
          .bold()
      })
      .accessibilityLabel("Edit Tapper")
      .accessibilityIdentifier("editTapperButton")
    }
    .padding(.horizontal, .spacing.xLarge)
  }
  
  var bottomView: some View {
    VStack(alignment: .center) {
      
      Spacer()
      
      HStack {
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.reduceValue()
          },
          imageName: "minus",
          accessibilityLabel: "Decrement Counter",
          accessibilityIdentifier: "fullDecrementButton"
        )
        .disabled(!self.tapper.canReduceValue)

        Spacer()

        Text("\(self.tapper.counterValue)")
          .font(.system(size: 56.0, weight: .bold, design: .monospaced))
          .lineLimit(1)
          .minimumScaleFactor(0.45)
          .monospacedDigit()
          .accessibilityIdentifier("fullCounterValue")
        
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.augmentValue()
          },
          imageName: "plus",
          accessibilityLabel: "Increment Counter",
          accessibilityIdentifier: "fullIncrementButton"
        )

        Spacer()
      }
      .bold()

      Text(self.tapper.name)
        .font(.title)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spacing.large)
        .accessibilityIdentifier("fullTapperName")
      
      Spacer()
    }
    .monospaced()
    .foregroundColor(self.tapper.textColor)
    .frame(maxWidth: .infinity)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      self.tapper.backgroundColor
        .ignoresSafeArea(.all)
        .onTapGesture {
          self.tapper.augmentValue()
          self.generator.impactOccurred()
        }
        .onLongPressGesture {
          self.tapper.reduceValue()
          self.generator.impactOccurred()
        }
      
      self.topView
      
      self.bottomView
    }
    .confirmationDialog(
      "Reset this counter?",
      isPresented: self.$isShowingResetConfirmation,
      titleVisibility: .visible
    ) {
      Button("Reset Counter", role: .destructive) {
        self.tapper.resetValue()
        self.generator.impactOccurred()
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
}

extension TapperView {
  struct ActionButton: View {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    let action: () -> Void
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    
    var body: some View {
      Button(action: {
        self.action()
        self.generator.impactOccurred()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3)
      })
      .frame(width: 80.0, height: 80.0)
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
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
