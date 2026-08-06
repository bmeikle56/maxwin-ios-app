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
    @FocusState private var isUsernameFocused: Bool
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatar

                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)

                    TextField(
                        "",
                        text: $viewModel.username,
                        prompt: Text("Username").foregroundStyle(MaxwinTheme.cream.opacity(0.35))
                    )
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(MaxwinTheme.cream)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .focused($isUsernameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await saveIfNeeded() }
                    }
                    .disabled(viewModel.isSaving)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(MaxwinTheme.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isUsernameFocused ? MaxwinTheme.gold.opacity(0.7) : MaxwinTheme.fieldStroke,
                                lineWidth: 1
                            )
                    }
                }

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

    private func saveIfNeeded() async {
        guard viewModel.canSave else { return }
        isUsernameFocused = false
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
