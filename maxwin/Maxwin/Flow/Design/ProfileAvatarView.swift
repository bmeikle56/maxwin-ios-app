//
//  ProfileAvatarView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import SwiftUI

struct ProfileAvatarView: View {
    var image: UIImage?
    var size: CGFloat
    var placeholderSystemImage: String = "person.fill"
    var showsCameraBadge: Bool = false
    var isLoading: Bool = false

    private var placeholderFontSize: CGFloat {
        size * 0.4
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle()
                            .fill(MaxwinTheme.cream.opacity(0.2))
                        Image(systemName: placeholderSystemImage)
                            .font(.system(size: placeholderFontSize, weight: .semibold))
                            .foregroundStyle(MaxwinTheme.cream)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(MaxwinTheme.fieldStroke.opacity(0.8), lineWidth: 1)
            }

            if showsCameraBadge {
                Image(systemName: "camera.fill")
                    .font(.system(size: max(9, size * 0.16), weight: .semibold))
                    .foregroundStyle(MaxwinTheme.feltDeep)
                    .padding(max(4, size * 0.08))
                    .background(MaxwinTheme.cream, in: Circle())
                    .offset(x: 2, y: 2)
                    .accessibilityHidden(true)
            }

            if isLoading {
                Circle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: size, height: size)
                ProgressView()
                    .tint(MaxwinTheme.cream)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(image == nil ? "Add profile photo" : "Change profile photo")
    }
}
