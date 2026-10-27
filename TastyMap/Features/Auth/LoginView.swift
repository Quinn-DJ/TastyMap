import SwiftUI

struct LoginView: View {
    @Environment(AppSession.self) private var session
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            TastyTheme.paper.ignoresSafeArea()
            PaperBackdrop()

            GeometryReader { proxy in
                ScrollView {
                    if proxy.size.width >= 900 {
                        HStack(spacing: 54) {
                            brandColumn
                                .frame(width: 420, alignment: .leading)

                            loginCard
                                .frame(width: 390)
                        }
                        .frame(maxWidth: 990)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: proxy.size.height,
                            maxHeight: .infinity
                        )
                        .padding(52)
                    } else {
                        VStack(spacing: 30) {
                            brandColumn
                            loginCard
                                .frame(maxWidth: 430)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 34)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var brandColumn: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                TastyMark(size: 58)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TastyMap")
                        .font(TastyTheme.title(42))
                        .foregroundStyle(TastyTheme.ink)
                    Text("你的私人味觉地图")
                        .font(TastyTheme.label(14))
                        .foregroundStyle(TastyTheme.actionFill)
                }
            }

            Text("把想吃的、\n吃过的，都留在同一张地图上。")
                .font(TastyTheme.title(32))
                .foregroundStyle(TastyTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("搜索收藏、地图打点，一键交给 Apple 地图导航。数据保存在本机，并同步到你的私有服务器。")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(TastyTheme.secondaryInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420, alignment: .leading)

            HStack(spacing: 10) {
                featurePill("map.fill", "地图")
                featurePill("magnifyingglass", "搜索")
                featurePill("location.fill", "导航")
            }
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("回到你的味觉地图")
                    .font(TastyTheme.title(26))
                    .foregroundStyle(TastyTheme.ink)
                Text(AppConfig.apiBaseURL.absoluteString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(TastyTheme.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            VStack(spacing: 13) {
                loginField(
                    title: "邮箱",
                    systemImage: "envelope",
                    text: $email,
                    field: .email
                )
                .textContentType(.username)
                .autocorrectionDisabled()

                secureField
            }

            if let error = session.loginError {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(TastyTheme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task {
                    await session.login(email: email, password: password)
                }
            } label: {
                HStack(spacing: 8) {
                    if session.isLoggingIn {
                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                    }
                    Text(session.isLoggingIn ? "正在登录" : "进入 TastyMap")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(
                email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || password.isEmpty
                    || session.isLoggingIn
            )
            .keyboardShortcut(.defaultAction)

            Label("账号由你的私有服务器管理，不开放公开注册", systemImage: "lock.shield")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(TastyTheme.secondaryInk)
        }
        .modifier(TastyCard(padding: 26))
    }

    private func featurePill(_ image: String, _ title: String) -> some View {
        Label(title, systemImage: image)
            .font(TastyTheme.label(12))
            .foregroundStyle(TastyTheme.support)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TastyTheme.support.opacity(0.10))
            .clipShape(Capsule())
    }

    private func loginField(
        title: String,
        systemImage: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .foregroundStyle(TastyTheme.secondaryInk)
                .frame(width: 20)
            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(TastyTheme.paper.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(TastyTheme.hairline, lineWidth: 1)
        }
    }

    private var secureField: some View {
        HStack(spacing: 11) {
            Image(systemName: "key")
                .foregroundStyle(TastyTheme.secondaryInk)
                .frame(width: 20)
            SecureField("密码", text: $password)
                .focused($focusedField, equals: .password)
                .textContentType(.password)
                .textFieldStyle(.plain)
                .onSubmit {
                    guard !email.isEmpty, !password.isEmpty else { return }
                    Task {
                        await session.login(email: email, password: password)
                    }
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(TastyTheme.paper.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(TastyTheme.hairline, lineWidth: 1)
        }
    }
}
