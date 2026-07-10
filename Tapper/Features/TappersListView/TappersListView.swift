import SwiftUI
import SwiftData

struct TappersListView: View {
  static let cardMinimumWidth: CGFloat = 160.0
  static let regularCardMinimumWidth: CGFloat = 220.0
  static let cardOpenTapAreaHeight: CGFloat = 132.0

  enum SortMode: String, CaseIterable, Identifiable {
    case name = "Name"
    case value = "Value"
    case increment = "Increment"

    var id: Self { self }

    var systemImageName: String {
      switch self {
        case .name:
          return "textformat"
        case .value:
          return "number"
        case .increment:
          return "plus.forwardslash.minus"
      }
    }
  }
  
  @Environment(\.modelContext) var modelContext
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Binding var path: NavigationPath
  @Query(sort: \Tapper.name) var tappers: [Tapper]
  @State private var searchText = ""
  @State private var sortMode = SortMode.name

  var shouldShowSearch: Bool {
    return self.tappers.count >= 10
  }

  var layout: [GridItem] {
    let minimumWidth = self.horizontalSizeClass == .regular ? Self.regularCardMinimumWidth : Self.cardMinimumWidth
    return [
      GridItem(.adaptive(minimum: minimumWidth), spacing: .spacing.medium)
    ]
  }

  var visibleTappers: [Tapper] {
    let filteredTappers = self.tappers.filter { tapper in
      guard !self.searchText.isEmpty else { return true }
      return tapper.name.localizedCaseInsensitiveContains(self.searchText)
    }

    switch self.sortMode {
      case .name:
        return filteredTappers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      case .value:
        return filteredTappers.sorted {
          if $0.counterValue == $1.counterValue {
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
          }

          return $0.counterValue > $1.counterValue
        }
      case .increment:
        return filteredTappers.sorted {
          if $0.sumatory == $1.sumatory {
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
          }

          return $0.sumatory > $1.sumatory
        }
    }
  }

  var titleView: some View {
    HStack(alignment: .center, spacing: .zero) {
      VStack(alignment: .leading, spacing: .spacing.small) {
        Text("Tappers")
          .font(.largeTitle)
          .bold()

        Text("Count anything. Keep the rhythm.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      
      Spacer()
      
      Button(action: {
        self.addTapper()
      }, label: {
        Image(systemName: "plus")
          .font(.title3)
          .frame(width: 44.0, height: 44.0)
          .background(Color.text.opacity(0.08), in: RoundedRectangle(cornerRadius: .cornerRadius.large))
      })
      .buttonStyle(.plain)
      .accessibilityLabel("Add Tapper")
      .accessibilityIdentifier("addTapperButton")
    }
    .padding(.horizontal, .spacing.large)
  }

  var controlsView: some View {
    VStack(alignment: .leading, spacing: .spacing.small) {
      HStack {
        Menu {
          Picker("Sort By", selection: self.$sortMode) {
            ForEach(SortMode.allCases) { mode in
              Label(mode.rawValue, systemImage: mode.systemImageName)
                .tag(mode)
            }
          }
        } label: {
          Label("Sort: \(self.sortMode.rawValue)", systemImage: "arrow.up.arrow.down")
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, .spacing.medium)
            .frame(height: 40.0)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
            .overlay(
              RoundedRectangle(cornerRadius: .cornerRadius.large)
                .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
            )
        }
        .accessibilityIdentifier("sortTappersMenu")

        Spacer()
      }

      if self.shouldShowSearch {
        self.searchView
      }
    }
    .padding(.horizontal, .spacing.medium)
  }

  var searchView: some View {
    HStack(spacing: .spacing.small) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)

      TextField("Find a tapper", text: self.$searchText)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .accessibilityIdentifier("searchTappersField")

      if !self.searchText.isEmpty {
        Button(action: {
          self.searchText = ""
        }, label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        })
        .buttonStyle(.plain)
        .accessibilityLabel("Clear Search")
        .accessibilityIdentifier("clearSearchButton")
      }
    }
    .padding(.horizontal, .spacing.medium)
    .frame(height: 44.0)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadius.large))
    .overlay(
      RoundedRectangle(cornerRadius: .cornerRadius.large)
        .stroke(Color.text.opacity(0.08), lineWidth: .borderWidth.standard)
    )
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

      if !self.tappers.isEmpty {
        self.controlsView
      }
      
      self.contentView
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

  func seedShowcaseDataIfNeeded() {
    guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.tappers.isEmpty else { return }

    [
      Tapper(name: "Push-ups", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "ffd84d", counterValue: 6),
      Tapper(name: "Sit-ups", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "ef4538", counterValue: 15),
      Tapper(name: "Squats", sumatory: 1, allowsNegativeValue: false, backgroundColorHex: "62c866", counterValue: 2)
    ].forEach { tapper in
      self.modelContext.insert(tapper)
    }

    try? self.modelContext.save()
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
