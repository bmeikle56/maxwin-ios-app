//
//  LoginView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, password
    }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 56)
                        .padding(.bottom, 40)

                    formFields

                    forgotPasswordLink
                        .padding(.top, 12)

                    signInButton
                        .padding(.top, 28)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.45))
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .alert("Forgot password", isPresented: $viewModel.showForgotPasswordAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.forgotPasswordMessage)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [MaxwinTheme.felt, MaxwinTheme.feltDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .onTapGesture {
            focusedField = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Maxwin")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)

            Text("Sign in to track your poker earnings.")
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
                contentType: .password,
                submitLabel: .go
            ) {
                Task { await attemptSignIn() }
            }
        }
    }

    private var forgotPasswordLink: some View {
        Button {
            viewModel.forgotPasswordTapped()
        } label: {
            Text("Forgot your password?")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.gold)
                .underline()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private var signInButton: some View {
        Button {
            Task { await attemptSignIn() }
        } label: {
            ZStack {
                Text("Sign In")
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

    private func attemptSignIn() async {
        focusedField = nil
        await viewModel.signIn()
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(authService: MockAuthService()))
}
