import SwiftUI

struct RootView: View {
  var body: some View {
    NavigationStack {
      List {
        Section("Release Slice 1") {
          Label("Auth bootstrap", systemImage: "person.badge.key")
          Label("Feed", systemImage: "newspaper")
          Label("Map", systemImage: "map")
          Label("Adventure detail", systemImage: "binoculars")
        }

        Section("Local Setup") {
          LabeledContent("iOS app") {
            Text("Bootstrapped")
              .foregroundStyle(HATheme.accent)
          }

          LabeledContent("Server repo") {
            Text("Sibling workspace")
          }

          LabeledContent("Architecture") {
            Text("SwiftUI-first")
          }
        }
      }
      .navigationTitle("Hidden Adventures")
    }
    .tint(HATheme.accent)
  }
}
