import SwiftUI

extension TappersListView {
  struct SmallTapperView: View {
    static let minimumHeight: CGFloat = 204.0
    
    let tapper: Tapper
    
    var body: some View {
      VStack(spacing: .zero) {
        TitleView(tapper: self.tapper)
          .padding(.horizontal, .spacing.medium)
          .padding(.top, .spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
        
        ActionView(tapper: self.tapper)
          .padding(.horizontal, .spacing.medium)
          .padding(.top, .spacing.medium)
          .padding(.bottom, .spacing.small)
      }
      .frame(maxWidth: .infinity, minHeight: Self.minimumHeight)
      .background(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .foregroundColor(self.tapper.backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: .cornerRadius.medium)
          .stroke(self.tapper.textColor.opacity(0.14), lineWidth: .borderWidth.standard)
      )
      .shadow(color: self.tapper.backgroundColor.opacity(0.22), radius: 14.0, x: 0.0, y: 7.0)
      .accessibilityElement(children: .contain)
    }
  }
}
