import SwiftUI

extension EditTapperView {
  final class ViewModel: ObservableObject {
    @Published var tapper: Tapper
    @Published var backgroundColor: Color {
      didSet {
        self.tapper.backgroundColorHex = UIColor(self.backgroundColor).hex
      }
    }
    
    var isEditing: Bool
    
    init(tapper: Tapper = Tapper(), isEditing: Bool = false) {
      self.tapper = tapper
      self.backgroundColor = tapper.backgroundColor
      self.isEditing = isEditing
    }
  }
}

struct EditTapperView: View {
  static let showAllowNegativeNumbers = false
  
  @Binding var path: NavigationPath
  @StateObject var viewModel: ViewModel
  @Environment(\.modelContext) var modelContext

  var body: some View {
    Form {
      Section("Name") {
        TextField("Name", text: self.$viewModel.tapper.name)
      }
      
      Section("Tapper Increment") {
        TextField(
          "1",
          value: self.$viewModel.tapper.sumatory,
          format: .number
        )
        .keyboardType(.numberPad)
        .frame(maxWidth: .infinity)
      }
      
      Section("Counter Value") {
        TextField(
          "Counter Value",
          value: self.$viewModel.tapper.counterValue,
          format: .number
        )
        .keyboardType(.numberPad)
        .frame(maxWidth: .infinity)
      }
      
      Section("Background Color") {
        if Self.showAllowNegativeNumbers {
          Toggle(
            isOn: self.$viewModel.tapper.allowsNegativeValue,
            label: {
              Text("Allows Negative Value")
            }
          )
        }
        
        ColorPicker("Select Color", selection: self.$viewModel.backgroundColor, supportsOpacity: false)
      }
      
      Section {
        
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.background)
    .toolbar {
      ToolbarItem(placement: .keyboard) {
        HStack(alignment: .center, spacing: .zero) {
          Spacer()
          
          Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
          }, label: {
            Text("Done")
          })
        }
      }
    }
  }
}

fileprivate struct CenterView<Content: View>: View {
  let content: Content
  
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  var body: some View {
    HStack {
      Spacer()
      content
      Spacer()
    }
  }
}
#Preview {
  NavigationStack {
    EditTapperView(path: .constant(NavigationPath()), viewModel: .init(isEditing: true))
      .navigationBarTitle("Edit Tapper")
  }
}
