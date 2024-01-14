import SwiftUI

enum TapperCoordinator: Hashable {
  case createTapper
  case editTapper(Tapper)
}

struct TapperNavigationView: View {
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: self.$path) {
      TappersListView(path: self.$path)
        .navigationDestination(for: TapperCoordinator.self) { route in
          switch route {
            case .createTapper:
              EditTapperView(path: self.$path, viewModel: .init())
                .navigationBarTitle("Create Tapper")
            case .editTapper(let tapper):
              EditTapperView(path: self.$path, viewModel: .init(tapper: tapper, isEditing: true))
                .navigationBarTitle("Edit Tapper")
          }
        }
        .navigationDestination(for: Tapper.self) { tapper in
          TapperView(path: self.$path, tapper: tapper)
            .navigationBarBackButtonHidden(true)
        }
    }
  }
}
