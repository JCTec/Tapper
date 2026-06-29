import SwiftUI
import SwiftData

struct TappersListView: View {
  static let cardMinimumWidth: CGFloat = 160.0
  static let cardOpenTapAreaHeight: CGFloat = 112.0
  static let layout = [
    GridItem(.adaptive(minimum: Self.cardMinimumWidth), spacing: .spacing.medium)
  ]
  
  @Environment(\.modelContext) var modelContext
  @Binding var path: NavigationPath
  @Query(sort: \Tapper.name) var tappers: [Tapper]
  
  var titleView: some View {
    HStack(alignment: .center, spacing: .zero) {
      Text("Tappers")
        .font(.largeTitle)
        .bold()
      
      Spacer()
      
      Button(action: {
        self.addTapper()
      }, label: {
        Image(systemName: "plus")
          .font(.title3)
      })
      .accessibilityLabel("Add Tapper")
      .accessibilityIdentifier("addTapperButton")
    }.padding(.horizontal, .spacing.large)
  }
  
  var contentView: some View {
    Group {
      if self.tappers.isEmpty {
        ContentUnavailableView(
          "No Tappers",
          systemImage: "hand.tap",
          description: Text("Create your first tapper to start counting.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("emptyTappersView")
      } else {
        ScrollView(.vertical) {
          LazyVGrid(columns: Self.layout, spacing: .spacing.medium) {
            ForEach(self.tappers) { tapper in
              ZStack(alignment: .top) {
                SmallTapperView(
                  tapper: tapper
                )

                Button(action: {
                  self.path.append(TapperCoordinator.viewTapper(tapper))
                }, label: {
                  Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.cardOpenTapAreaHeight)
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
  
  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      self.titleView
      
      self.contentView
    }
    .background(
      Color.background
        .ignoresSafeArea(.all)
    )
  }
  
  func addTapper() {
    self.path.append(TapperCoordinator.createTapper)
  }
}

@MainActor
@available(iOS 17, *)
struct _TappersListViewPreview: View {
  @State var path = NavigationPath()

  var body: some View {
    TappersListView(path: self.$path)
      .modelContainer(Self.previewContainer)
  }
}

#Preview {
  if #available(iOS 17, *) {
    return _TappersListViewPreview()
  } else {
    return Text("iOS 17 Only Preview")
  }
}
