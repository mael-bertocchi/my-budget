import SwiftUI

struct SignInView: View {
    @Environment(ApplicationSession.self) private var session
    @Environment(Preferences.self) private var preferences

    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    @FocusState private var focus: Field?

    private enum Field {
        case username
        case password
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 28)

                    VStack(spacing: 12) {
                        field(
                            label: "Username",
                            prompt: "you",
                            text: $username,
                            focus: .username,
                            secure: false,
                            submit: { focus = .password }
                        )
                        field(
                            label: "Password",
                            prompt: "••••••••",
                            text: $password,
                            focus: .password,
                            secure: true,
                            submit: submit
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.negative)
                            .padding(.top, 14)
                            .transition(.opacity)
                    }

                    PrimaryButton(title: "Sign in", isDisabled: !canSubmit || isSubmitting) {
                        submit()
                    }
                    .padding(.top, 22)
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 80)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            username = session.username ?? ""
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.accent.opacity(0.16))
                    .frame(width: 60, height: 60)
                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.bottom, 6)
            Text("My Budget")
                .font(Theme.font(30, .semibold))
                .tracking(-0.5)
                .foregroundStyle(Theme.text)
            Text("Sign in to sync your budget across devices.")
                .font(Theme.font(14))
                .foregroundStyle(Theme.muted)
        }
    }

    private var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    private func field(
        label: String,
        prompt: String,
        text: Binding<String>,
        focus field: Field,
        secure: Bool,
        submit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(label)
            Group {
                if secure {
                    SecureField("", text: text, prompt: Text(prompt).foregroundStyle(Theme.faint))
                        .onSubmit(submit)
                } else {
                    TextField("", text: text, prompt: Text(prompt).foregroundStyle(Theme.faint))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(submit)
                }
            }
            .font(Theme.font(15))
            .foregroundStyle(Theme.text)
            .focused($focus, equals: field)
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .glassInput(radius: Theme.controlRadius)
            .accessibilityLabel(label)
        }
    }

    private func submit() {
        guard canSubmit, !isSubmitting else { return }
        preferences.tap()
        focus = nil
        isSubmitting = true
        withAnimation { errorMessage = nil }

        Task {
            do {
                try await session.signIn(
                    username: username.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                preferences.success()
            } catch {
                let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
                withAnimation { errorMessage = message }
                isSubmitting = false
            }
        }
    }
}
