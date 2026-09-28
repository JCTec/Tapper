import SwiftUI
import SwiftData

struct TappersListView: View {
  static let cardMinimumWidth: CGFloat = 160.0
  static let regularCardMinimumWidth: CGFloat = 220.0
  static let cardOpenTapAreaHeight: CGFloat = 132.0
  
  @Environment(\.modelContext) var modelContext
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Binding var path: NavigationPath
  @Query(sort: \Tapper.name) var tappers: [Tapper]
  @State var searchText = ""
  @State var sortMode = SortMode.name
  
  var body: some View {
    VStack(alignment: .leading, spacing: .spacing.medium) {
      TitleView(onAdd: {
        self.addTapper()
      })

      if !self.tappers.isEmpty {
        ControlsView(
          sortMode: self.$sortMode,
          searchText: self.$searchText,
          showsSearch: self.shouldShowSearch
        )
      }
      
      ContentView(
        path: self.$path,
        hasTappers: !self.tappers.isEmpty,
        visibleTappers: self.visibleTappers,
        layout: self.layout
      )
    }
    .background(
      Color.background
        .ignoresSafeArea(.all)
    )
    .task {
      self.seedShowcaseDataIfNeeded()
    }
    .onChange(of: self.shouldShowSearch) { _, shouldShowSearch in
      if !shouldShowSearch {
        self.searchText = ""
      }
    }
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
