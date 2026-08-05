//
//  SettingsView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var onAnimationPreferenceChanged: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader

                    settingsSection

                    accountSection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(MaxwinTheme.lossRed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete account?",
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your Maxwin account and local session data.")
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MaxwinTheme.cream.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MaxwinTheme.cream)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.username)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(MaxwinTheme.cream)
                Text("Profile")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
            }

            Spacer()
        }
        .padding(16)
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Settings")

            Toggle(isOn: Binding(
                get: { viewModel.animationsEnabled },
                set: { newValue in
                    viewModel.setAnimationsEnabled(newValue)
                    onAnimationPreferenceChanged?()
                }
            )) {
                Text("Animations")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
            }
            .tint(Color.white.opacity(0.45))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Account")

            Button {
                Task { await viewModel.signOut() }
            } label: {
                settingsRow(
                    title: "Log out",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: MaxwinTheme.cream,
                    isLoading: viewModel.isSigningOut
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSigningOut || viewModel.isDeletingAccount)

            Divider()
                .background(MaxwinTheme.fieldStroke)
                .padding(.leading, 52)

            Button {
                viewModel.showDeleteConfirmation = true
            } label: {
                settingsRow(
                    title: "Delete account",
                    systemImage: "trash",
                    tint: MaxwinTheme.lossRed,
                    isLoading: viewModel.isDeletingAccount
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSigningOut || viewModel.isDeletingAccount)
        }
        .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MaxwinTheme.fieldStroke, lineWidth: 1)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(MaxwinTheme.mutedCream)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    private func settingsRow(
        title: String,
        systemImage: String,
        tint: Color,
        isLoading: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(tint)

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(MaxwinTheme.gold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(
            authService: MockAuthService(),
            settingsService: MockSettingsService()
        )
    )
}
