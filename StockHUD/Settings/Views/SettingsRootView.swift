import SwiftUI

struct SettingsRootView: View {
    var body: some View {
        TabView {
            SymbolsSettingsView()
                .tabItem { Label("Symbols", systemImage: "list.star") }
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            DisplaySettingsView()
                .tabItem { Label("Display", systemImage: "textformat.size") }
            BehaviorSettingsView()
                .tabItem { Label("Behavior", systemImage: "macwindow.on.rectangle") }
            UpdateSettingsView()
                .tabItem { Label("Update", systemImage: "arrow.triangle.2.circlepath") }
        }
        .frame(width: 440)
    }
}
