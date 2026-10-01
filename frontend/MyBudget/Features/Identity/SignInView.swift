import SwiftUI

struct SignInView: View {
    @Environment(ApplicationSession.self) private var session
    @Environment(Preferences.self) private var preferences

    @State private var code = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var failures = 0

    @FocusState private var isFocused: Bool

    private static let length = 6

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 32)

                    codeField
                        .modifier(Shake(animatableData: CGFloat(failures)))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.font(13))
                            .foregroundStyle(Theme.negative)
                            .padding(.top, 14)
                            .transition(.opacity)
                    }

                    PrimaryButton(title: String(appLocalized: "Sign in"), isDisabled: code.count < Self.length || isSubmitting) {
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
        .onAppear { isFocused = true }
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
            Text(verbatim: "My Budget")
                .font(Theme.font(30, .semibold))
                .tracking(-0.5)
                .foregroundStyle(Theme.text)
            Text("Enter your code to open your budget.")
                .font(Theme.font(14))
                .foregroundStyle(Theme.muted)
        }
    }

    /// Six boxes drawn over one hidden field. The field owns the keyboard, pasting and one-time-code autofill;
    /// the boxes only show how many digits it holds, as dots like a passcode, and where the next one goes.
    private var codeField: some View {
        ZStack {
            TextField("", text: digitsOnly)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.001)
                .accessibilityLabel("Code")

            HStack(spacing: 10) {
                ForEach(0..<Self.length, id: \.self) { index in
                    digitBox(index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .accessibilityHidden(true)
        }
    }

    /// Keeps the field to six digits and submits as the sixth arrives. It runs on every edit, however fast the digits
    /// come — typed, pasted or autofilled all at once.
    private var digitsOnly: Binding<String> {
        Binding(
            get: { code },
            set: { typed in
                code = String(typed.filter(\.isNumber).prefix(Self.length))

                if code.count == Self.length {
                    submit()
                }
            }
        )
    }

    private func digitBox(_ index: Int) -> some View {
        let digits = Array(code)
        let isNext = isFocused && !isSubmitting && index == min(digits.count, Self.length - 1)

        return Circle()
            .fill(Theme.text)
            .frame(width: 12, height: 12)
            .opacity(index < digits.count ? 1 : 0)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .glassInput(radius: Theme.controlRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                    .strokeBorder(isNext ? Theme.accent : .clear, lineWidth: 1.5)
            )
            .animation(.easeOut(duration: 0.12), value: isNext)
    }

    private func submit() {
        guard code.count == Self.length, !isSubmitting else { return }
        preferences.tap()
        isSubmitting = true
        withAnimation { errorMessage = nil }

        Task {
            do {
                try await session.signIn(code: code)
                preferences.success()
            } catch {
                let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
                withAnimation(.default) {
                    failures += 1
                    errorMessage = message
                }
                code = ""
                isSubmitting = false
                isFocused = true
            }
        }
    }
}

private struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 3), y: 0))
    }
}
