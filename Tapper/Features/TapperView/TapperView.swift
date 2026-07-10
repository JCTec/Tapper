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
  @State private var isCounterPulsing = false
  @ScaledMetric private var counterFontSize: CGFloat = 92.0
  
  var topView: some View {
    HStack(spacing: .spacing.medium) {
      Button(action: {
        self.closeTapper()
      }, label: {
        Image(systemName: "xmark")
          .font(.title3.weight(.bold))
          .foregroundColor(self.tapper.textColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.tapper.textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.plain)
      .accessibilityLabel("Close Tapper")
      .accessibilityIdentifier("closeTapperButton")
      
      Spacer()

      Button(action: {
        self.isShowingResetConfirmation = true
      }, label: {
        Image(systemName: "arrow.counterclockwise")
          .font(.title3.weight(.bold))
          .foregroundColor(self.tapper.textColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.tapper.textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.plain)
      .accessibilityLabel("Reset Counter")
      .accessibilityIdentifier("resetTapperButton")
      
      Button(action: {
        self.path.append(TapperCoordinator.editTapper(self.tapper))
      }, label: {
        Image(systemName: "slider.horizontal.3")
          .font(.title3.weight(.bold))
          .foregroundColor(self.tapper.textColor)
          .frame(width: 44.0, height: 44.0)
          .background(self.tapper.textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.plain)
      .accessibilityLabel("Edit Tapper")
      .accessibilityIdentifier("editTapperButton")
    }
    .padding(.horizontal, .spacing.xLarge)
    .padding(.top, .spacing.medium)
  }
  
  var bottomView: some View {
    VStack(alignment: .center, spacing: .spacing.large) {
      Spacer()

      VStack(alignment: .center, spacing: .spacing.medium) {
        Image(systemName: "hand.tap.fill")
          .font(.system(size: 54.0, weight: .bold))
          .symbolEffect(.bounce, value: self.tapper.counterValue)

        Text(self.tapper.counterValue.formatted())
          .font(.system(size: self.counterFontSize, weight: .bold, design: .monospaced))
          .lineLimit(1)
          .minimumScaleFactor(0.32)
          .monospacedDigit()
          .contentTransition(.numericText())
          .scaleEffect(self.isCounterPulsing ? 1.05 : 1.0)
          .animation(.spring(response: 0.24, dampingFraction: 0.72), value: self.isCounterPulsing)
          .animation(.spring(response: 0.28, dampingFraction: 0.82), value: self.tapper.counterValue)
          .accessibilityIdentifier("fullCounterValue")

        Text(self.tapper.name)
          .font(.title.weight(.semibold))
          .lineLimit(2)
          .minimumScaleFactor(0.7)
          .multilineTextAlignment(.center)
          .padding(.horizontal, .spacing.large)
          .accessibilityIdentifier("fullTapperName")

        HStack(spacing: .spacing.medium) {
          Label("Increment \(self.tapper.sumatory)", systemImage: "plus.forwardslash.minus")

          if self.tapper.allowsNegativeValue {
            Label("Negatives", systemImage: "minus.circle")
          }
        }
        .font(.footnote.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .foregroundColor(self.tapper.textColor.opacity(0.76))
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, .spacing.medium)

      HStack(spacing: .spacing.large) {
        ActionButton(
          action: {
            self.decrementTapper()
          },
          imageName: "minus",
          accessibilityLabel: "Decrement Counter",
          accessibilityIdentifier: "fullDecrementButton"
        )
        .disabled(!self.tapper.canReduceValue)
        
        ActionButton(
          action: {
            self.incrementTapper()
          },
          imageName: "plus",
          accessibilityLabel: "Increment Counter",
          accessibilityIdentifier: "fullIncrementButton"
        )
      }
      .bold()
      
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
          self.incrementTapper()
        }
        .onLongPressGesture {
          self.decrementTapper()
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

  func playCounterFeedback() {
    self.generator.impactOccurred()

    withAnimation(.spring(response: 0.18, dampingFraction: 0.68)) {
      self.isCounterPulsing = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.86)) {
        self.isCounterPulsing = false
      }
    }
  }
}

extension TapperView {
  struct ActionButton: View {
    let action: () -> Void
    let imageName: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    
    var body: some View {
      Button(action: {
        self.action()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title2.weight(.bold))
          .frame(width: 80.0, height: 80.0)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
          .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius.large)
              .stroke(.primary.opacity(0.12), lineWidth: .borderWidth.standard)
          )
      })
      .buttonStyle(TapperPressButtonStyle())
      .contentShape(Rectangle())
      .accessibilityLabel(self.accessibilityLabel)
      .accessibilityIdentifier(self.accessibilityIdentifier)
    }
  }

  struct TapperPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.74), value: configuration.isPressed)
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
