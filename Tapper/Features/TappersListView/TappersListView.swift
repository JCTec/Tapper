import SwiftUI
import SwiftData

struct TappersListView: View {
  static let squareHeight: CGFloat = 175.0
  static let layout = [
    GridItem(.fixed(Self.squareHeight)),
    GridItem(.fixed(Self.squareHeight))
  ]
  
  @Environment(\.modelContext) var modelContext
  @Binding var path: NavigationPath
  @Query var tappers: [Tapper]
  
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
    }.padding(.horizontal, .spacing.large)
  }
  
  var contentView: some View {
    ScrollView(.vertical) {
      LazyVGrid(columns: Self.layout, spacing: .zero) {
        ForEach(self.tappers) { tapper in
          Button(action: {
            self.path.append(tapper)
          }, label: {
            SmallTapperView(
              tapper: tapper
            )
          })
        }
      }
    }.scrollBounceBehavior(.basedOnSize)
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

