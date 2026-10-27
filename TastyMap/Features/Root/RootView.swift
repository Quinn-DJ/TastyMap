import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.state {
            case .launching:
                LaunchingView()
            case .signedOut:
                LoginView()
            case .signedIn:
                MapWorkspaceView()
            }
        }
        .background(TastyTheme.paper)
        .task {
            await session.restore()
        }
    }
}

private struct LaunchingView: View {
    var body: some View {
        ZStack {
            TastyTheme.paper.ignoresSafeArea()
            PaperBackdrop()

            VStack(spacing: 18) {
                TastyMark(size: 72)
                Text("TastyMap")
                    .font(TastyTheme.title(36))
                    .foregroundStyle(TastyTheme.ink)
                ProgressView()
                    .tint(TastyTheme.actionFill)
                    .controlSize(.small)
            }
        }
    }
}
