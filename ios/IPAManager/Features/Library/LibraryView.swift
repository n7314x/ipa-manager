import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 52))
                Text("IPA Manager")
                    .font(.largeTitle.bold())
                Text("Library and secure import features are coming next.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Library")
        }
    }
}
