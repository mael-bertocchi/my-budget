import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case budget
    case history
    case settings

    var id: String { rawValue }
}

struct RootView: View {
    @Environment(LocalStore.self) private var store
    @Environment(ApplicationSession.self) private var session

    var body: some View {
        Group {
            switch session.identityState {
            case .loading:
                ZStack {
                    AmbientBackground()
                    ProgressView()
                        .tint(Theme.accent)
                }
            case .signedOut:
                SignInView()
            case .signedIn:
                MainShell()
            }
        }
        .task {
            #if DEBUG
            if CommandLine.arguments.contains("-demo-empty") {
                DebugSeed.enterDemoEmpty(store: store)
                session.enterDemo()
                return
            }
            if CommandLine.arguments.contains("-demo") {
                DebugSeed.enterDemo(store: store)
                session.enterDemo()
                return
            }
            #endif
            await session.bootstrap()
        }
    }
}

struct MainShell: View {
    @Environment(Preferences.self) private var preferences
    @Environment(ApplicationSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: AppTab = .budget
    @State private var editorRoute: OperationEditorRoute?
    @State private var historyFilter: HistoryFilter = .all

    var body: some View {
        TabView(selection: $selection) {
            Tab("Budget", systemImage: "chart.pie", value: AppTab.budget) {
                BudgetView(
                    onOpenCategory: openCategoryInHistory,
                    onNewOperation: { editorRoute = .new }
                )
                .screenBackground()
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                HistoryView(
                    filter: $historyFilter,
                    onSelect: { editorRoute = .edit($0.id) },
                    onNewOperation: { editorRoute = .new }
                )
                .screenBackground()
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                SettingsView()
                    .screenBackground()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(item: $editorRoute) { route in
            OperationEditorSheet(route: route)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                session.applicationBecameActive()
            }
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

    private func openCategoryInHistory(_ category: Category) {
        historyFilter = .category(category.id)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            selection = .history
        }
    }
}
