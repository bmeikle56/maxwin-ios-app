//
//  SignUpView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/6/26.
//

import SwiftUI

struct SignUpView: View {
    @Bindable var viewModel: SignUpViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, 24)
                    .padding(.bottom, 40)

                formFields

                signUpButton
                    .padding(.top, 28)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.45))
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                signInLink
                    .padding(.top, 28)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltScreenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.cream)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create account")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)

            Text("Sign up to start tracking your poker earnings.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
        }
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            authField(
                title: "Username",
                text: $viewModel.username,
                field: .username,
                isSecure: false,
                contentType: .username,
                submitLabel: .next
            ) {
                focusedField = .password
            }

            authField(
                title: "Password",
                text: $viewModel.password,
                field: .password,
                isSecure: true,
                contentType: .newPassword,
                submitLabel: .next
            ) {
                focusedField = .confirmPassword
            }

            authField(
                title: "Confirm password",
                text: $viewModel.confirmPassword,
                field: .confirmPassword,
                isSecure: true,
                contentType: .newPassword,
                submitLabel: .go
            ) {
                Task { await attemptSignUp() }
            }
        }
    }

    private var signUpButton: some View {
        Button {
            Task { await attemptSignUp() }
        } label: {
            ZStack {
                Text("Sign Up")
                    .opacity(viewModel.isLoading ? 0 : 1)

                if viewModel.isLoading {
                    ProgressView()
                        .tint(MaxwinTheme.feltDeep)
                }
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(MaxwinTheme.feltDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MaxwinTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private var signInLink: some View {
        Button {
            dismiss()
        } label: {
            (
                Text("Already have an account? ")
                    .foregroundStyle(MaxwinTheme.mutedCream)
                + Text("Sign in")
                    .foregroundStyle(MaxwinTheme.gold)
            )
            .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private func authField(
        title: String,
        text: Binding<String>,
        field: Field,
        isSecure: Bool,
        contentType: UITextContentType,
        submitLabel: SubmitLabel,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)

            Group {
                if isSecure {
                    SecureField("", text: text, prompt: Text(title).foregroundStyle(MaxwinTheme.cream.opacity(0.35)))
                } else {
                    TextField("", text: text, prompt: Text(title).foregroundStyle(MaxwinTheme.cream.opacity(0.35)))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundStyle(MaxwinTheme.cream)
            .textContentType(contentType)
            .focused($focusedField, equals: field)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
            .disabled(viewModel.isLoading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        focusedField == field ? MaxwinTheme.gold.opacity(0.7) : MaxwinTheme.fieldStroke,
                        lineWidth: 1
                    )
            }
        }
    }

    private func attemptSignUp() async {
        focusedField = nil
        await viewModel.signUp()
    }
}

#Preview {
    NavigationStack {
        SignUpView(
            viewModel: SignUpViewModel(
                authService: MockAuthService(),
                biometricService: BiometricAuthService(),
                trackDataService: MockTrackDataService(sessionService: MockSessionService())
            )
        )
    }
}
