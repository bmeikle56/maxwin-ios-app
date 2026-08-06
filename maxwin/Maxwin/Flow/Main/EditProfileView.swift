//
//  EditProfileView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {
    @Bindable var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var photoPickerItem: PhotosPickerItem?

    private enum Field {
        case username, currentPassword, newPassword, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatar

                profileField(
                    title: "Username",
                    field: .username
                ) {
                    TextField(
                        "",
                        text: $viewModel.username,
                        prompt: Text("Username").foregroundStyle(MaxwinTheme.cream.opacity(0.35))
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .currentPassword
                    }
                }

                passwordSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.lossRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await saveIfNeeded() }
                } label: {
                    ZStack {
                        Text("Save")
                            .opacity(viewModel.isSaving ? 0 : 1)

                        if viewModel.isSaving {
                            ProgressView()
                                .tint(MaxwinTheme.feltDeep)
                        }
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.feltDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        MaxwinTheme.cream.opacity(viewModel.canSave || viewModel.isSaving ? 1 : 0.45),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canSave)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltScreenBackground()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: photoPickerItem) { _, item in
            Task {
                await viewModel.updateAvatar(from: item)
                photoPickerItem = nil
            }
        }
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            profileField(
                title: "Current password",
                field: .currentPassword
            ) {
                SecureField(
                    "",
                    text: $viewModel.currentPassword,
                    prompt: Text("Current password").foregroundStyle(MaxwinTheme.cream.opacity(0.35))
                )
                .textContentType(.password)
                .submitLabel(.next)
                .onSubmit {
                    if viewModel.hasEnteredCurrentPassword {
                        focusedField = .newPassword
                    }
                }
            }

            if viewModel.hasEnteredCurrentPassword {
                profileField(
                    title: "New password",
                    field: .newPassword
                ) {
                    SecureField(
                        "",
                        text: $viewModel.newPassword,
                        prompt: Text("New password").foregroundStyle(MaxwinTheme.cream.opacity(0.35))
                    )
                    .textContentType(.newPassword)
                    .submitLabel(.next)
                    .onSubmit {
                        if viewModel.hasEnteredNewPassword {
                            focusedField = .confirmPassword
                        }
                    }
                }

                if viewModel.hasEnteredNewPassword {
                    profileField(
                        title: "Confirm new password",
                        field: .confirmPassword
                    ) {
                        SecureField(
                            "",
                            text: $viewModel.confirmPassword,
                            prompt: Text("Confirm new password").foregroundStyle(MaxwinTheme.cream.opacity(0.35))
                        )
                        .textContentType(.newPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            Task { await saveIfNeeded() }
                        }
                    }
                }
            }
        }
    }

    private var avatar: some View {
        let avatarImage = viewModel.avatarImage
        let isUpdatingAvatar = viewModel.isUpdatingAvatar

        return VStack(spacing: 12) {
            PhotosPicker(
                selection: $photoPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                ProfileAvatarView(
                    image: avatarImage,
                    size: 88,
                    showsCameraBadge: true,
                    isLoading: isUpdatingAvatar
                )
            }
            .buttonStyle(.plain)
            .disabled(isUpdatingAvatar || viewModel.isSaving)

            Text(viewModel.username.isEmpty ? "Player" : viewModel.username)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(MaxwinTheme.cream)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("Tap to change photo")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func profileField<Content: View>(
        title: String,
        field: Field,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)

            content()
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)
                .focused($focusedField, equals: field)
                .disabled(viewModel.isSaving)
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

    private func saveIfNeeded() async {
        guard viewModel.canSave else { return }
        focusedField = nil
        if await viewModel.save() {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(
            viewModel: EditProfileViewModel(authService: MockAuthService())
        )
    }
}
