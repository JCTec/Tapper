import SwiftUI

extension TappersListView {
  struct ContentView: View {
    @Binding var path: NavigationPath
    let hasTappers: Bool
    let visibleTappers: [Tapper]
    let layout: [GridItem]

    var body: some View {
      Group {
        if !self.hasTappers {
          ContentUnavailableView(
            "No Tappers",
            systemImage: "hand.tap",
            description: Text("Create your first tapper to start counting.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityIdentifier("emptyTappersView")
        } else if self.visibleTappers.isEmpty {
          ContentUnavailableView(
            "No Matching Tappers",
            systemImage: "magnifyingglass",
            description: Text("Try a different name.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityIdentifier("noMatchingTappersView")
        } else {
          ScrollView(.vertical) {
            LazyVGrid(columns: self.layout, spacing: .spacing.medium) {
              ForEach(self.visibleTappers) { tapper in
                ZStack(alignment: .top) {
                  SmallTapperView(
                    tapper: tapper
                  )

                  Button(action: {
                    self.path.append(TapperCoordinator.viewTapper(tapper))
                  }, label: {
                    Color.clear
                      .frame(maxWidth: .infinity)
                      .frame(height: TappersListView.cardOpenTapAreaHeight)
                      .contentShape(Rectangle())
                  })
                  .buttonStyle(.plain)
                  .accessibilityLabel(tapper.name)
                  .accessibilityValue("\(tapper.counterValue)")
                  .accessibilityIdentifier("openTapper-\(tapper.name)")
                }
              }
            }
            .padding(.horizontal, .spacing.medium)
            .padding(.bottom, .spacing.large)
          }
          .scrollBounceBehavior(.basedOnSize)
        }
      }
    }
  }
}
