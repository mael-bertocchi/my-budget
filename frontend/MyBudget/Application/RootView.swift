import SwiftUI

struct RootView: View {
    @Environment(LocalStore.self) private var store

    var body: some View {
        MainShell()
            .task {
                #if DEBUG
                if CommandLine.arguments.contains("-demo-empty") {
                    DebugSeed.enterDemoEmpty(store: store)
                    return
                }
                if CommandLine.arguments.contains("-demo") {
                    DebugSeed.enterDemo(store: store)
                }
                #endif
            }
    }
}

struct MainShell: View {
    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences

    @State private var selection: AppTab = .budget
    @State private var editorRoute: OperationEditorRoute?
    @State private var historyFilter: HistoryFilter = .all

    var body: some View {
        ZStack(alignment: .bottom) {
            AmbientBackground()

            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ApplicationTabBar(
                selection: $selection,
                onAddTap: {
                    preferences.tap()
                    editorRoute = .new
                }
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheet(item: $editorRoute) { route in
            OperationEditorSheet(route: route)
        }
        .onAppear {
            #if DEBUG
            if let tab = UserDefaults.standard.string(forKey: "tab"),
               let target = AppTab(rawValue: tab) {
                selection = target
            }
            if UserDefaults.standard.string(forKey: "open") == "add" {
                editorRoute = .new
            }
            #endif
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selection {
        case .budget:
            BudgetView(onOpenCategory: openCategoryInHistory)
        case .history:
            HistoryView(filter: $historyFilter, onSelect: { editorRoute = .edit($0.id) })
        case .savings:
            SavingsView()
        case .settings:
            SettingsView()
        }
    }

    private func openCategoryInHistory(_ category: Category) {
        historyFilter = .category(category.id)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            selection = .history
        }
    }
}
