//
//  SettingsView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import PhotosUI
import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    var onPreferenceChanged: (() -> Void)?
    @State private var photoPickerItem: PhotosPickerItem?

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

                    DisclaimerView(content: "Privacy policy") {
                        PrivacyPolicyView()
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .navigationTitle("Settings")
            .onAppear {
                viewModel.reloadAvatar()
            }
            .onChange(of: photoPickerItem) { _, item in
                Task {
                    await viewModel.updateAvatar(from: item)
                    photoPickerItem = nil
                }
            }
            .alert("Log out?", isPresented: $viewModel.showSignOutConfirmation) {
                Button("Log out", role: .destructive) {
                    Task { await viewModel.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You’ll need to sign in again to access your sessions.")
            }
            .alert("Delete account?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your Maxwin account and local session data. This can’t be undone.")
            }
        }
    }

    private var profileHeader: some View {
        let avatarImage = viewModel.avatarImage
        let isUpdatingAvatar = viewModel.isUpdatingAvatar

        return HStack(spacing: 14) {
            PhotosPicker(
                selection: $photoPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ProfileAvatarView(
                    image: avatarImage,
                    size: 56,
                    showsCameraBadge: true,
                    isLoading: isUpdatingAvatar
                )
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingAvatar || viewModel.isSigningOut || viewModel.isDeletingAccount)

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
                    onPreferenceChanged?()
                }
            )) {
                Text("Animations")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
            }
            .tint(Color.white.opacity(0.45))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .background(MaxwinTheme.fieldStroke)
                .padding(.leading, 16)

            Toggle(isOn: Binding(
                get: { viewModel.tipsEnabled },
                set: { newValue in
                    viewModel.setTipsEnabled(newValue)
                    onPreferenceChanged?()
                }
            )) {
                Text("Tips")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
            }
            .tint(Color.white.opacity(0.45))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .background(MaxwinTheme.fieldStroke)
                .padding(.leading, 16)

            Toggle(isOn: Binding(
                get: { viewModel.condensedSessionsList },
                set: { newValue in
                    viewModel.setCondensedSessionsList(newValue)
                    onPreferenceChanged?()
                }
            )) {
                Text("Condensed list")
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

            NavigationLink {
                EditProfileView(viewModel: viewModel.makeEditProfileViewModel())
                    .onDisappear {
                        viewModel.reloadAvatar()
                    }
            } label: {
                settingsRow(
                    title: "Edit Profile",
                    systemImage: "person.crop.circle",
                    tint: MaxwinTheme.cream,
                    isLoading: false,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSigningOut || viewModel.isDeletingAccount)

            Divider()
                .background(MaxwinTheme.fieldStroke)
                .padding(.leading, 52)

            Button {
                viewModel.showSignOutConfirmation = true
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
        isLoading: Bool,
        showsChevron: Bool = false
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
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MaxwinTheme.mutedCream)
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
            settingsService: MockSettingsService(),
            trackDataService: MockTrackDataService(sessionService: MockSessionService())
        )
    )
}
