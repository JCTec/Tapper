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
  
  var topView: some View {
    HStack {
      Button(action: {
        self.path.removeLast()
      }, label: {
        Image(systemName: "multiply.circle.fill")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
          .bold()
      })
      
      Spacer()
      
      Button(action: {
        self.path.append(TapperCoordinator.editTapper(self.tapper))
      }, label: {
        Image(systemName: "info.circle.fill")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
          .bold()
      })
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
          imageName: "minus"
        )

        Spacer()

        Text("\(self.tapper.counterValue)")
          .font(.system(size: 56.0))
        
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.augmentValue()
          },
          imageName: "plus"
        )

        Spacer()
      }
      .bold()

      Text(self.tapper.name)
        .font(.title)
      
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
  }
}

extension TapperView {
  struct ActionButton: View {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    let action: () -> Void
    let imageName: String
    
    var body: some View {
      Button(action: {
        self.action()
        self.generator.impactOccurred()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3)
          .frame(width: 80.0, height: 80.0)
      })
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
