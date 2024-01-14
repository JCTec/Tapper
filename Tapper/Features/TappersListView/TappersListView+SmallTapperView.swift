import SwiftUI

extension TappersListView {
  struct SmallTapperView: View {
    static let squareWidth: CGFloat = 130.0
    
    let tapper: Tapper
    
    var titleView: some View {
      HStack(spacing: .zero) {
        Text(self.tapper.name)
          .font(.title2)
          .foregroundColor(self.tapper.textColor)
          .bold()
          .padding(.leading, .spacing.medium)

        Spacer()
      }
      .padding(.top, .spacing.small)
    }
    
    var actionView: some View {
      HStack(spacing: .zero) {
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.reduceValue()
          },
          imageName: "minus",
          foregroundColor: self.tapper.textColor
        )
        
        Spacer()

        Text("\(self.tapper.counterValue)")
          .font(.largeTitle)
          .foregroundColor(self.tapper.textColor)
        
        Spacer()
        
        ActionButton(
          action: {
            self.tapper.augmentValue()
          },
          imageName: "plus",
          foregroundColor: self.tapper.textColor
        )
        
        Spacer()
      }
      .bold()
      .padding(.bottom, .spacing.small)
    }
    
    var body: some View {
      VStack(spacing: .zero) {
        self.titleView

        Spacer()
        
        self.actionView
      }
      .frame(maxWidth: .infinity, minHeight: Self.squareWidth)
      .background(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .foregroundColor(self.tapper.backgroundColor)
      )
      .padding(.all, .spacing.small)
    }
  }
}

extension TappersListView.SmallTapperView {
  fileprivate struct ActionButton: View {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    let action: () -> Void
    let imageName: String
    let foregroundColor: Color
    
    var body: some View {
      Button(action: {
        self.action()
        self.generator.impactOccurred()
      }, label: {
        Image(systemName: self.imageName)
          .font(.title3)
          .foregroundColor(self.foregroundColor)
      })
    }
  }
}
