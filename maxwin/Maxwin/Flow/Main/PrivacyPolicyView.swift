//
//  PrivacyPolicyView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    policySection(
                        title: "What we collect",
                        body: "Maxwin stores your account details (such as username and profile photo) and the poker session data you enter—buy-ins, cash-outs, hands, and related stats—so we can show your track record and trends."
                    )

                    policySection(
                        title: "How we use it",
                        body: "Your data is used only to power the app experience: signing in, syncing your profile, and calculating session and bankroll metrics. We don’t sell your personal information or use it for third-party advertising."
                    )

                    policySection(
                        title: "Where it’s stored",
                        body: "Session and account data are kept to provide Maxwin’s features. Avatar images and preferences may be stored on device. We take reasonable steps to protect information in transit and at rest."
                    )

                    policySection(
                        title: "Your choices",
                        body: "You can update your profile anytime, and you can delete your account from Settings. Deleting your account permanently removes your Maxwin account and associated local session data."
                    )

                    policySection(
                        title: "Contact",
                        body: "Questions about this policy or your data? Reach out to the Maxwin team and we’ll help."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .feltScreenBackground()
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(MaxwinTheme.gold)
                }
            }
            .toolbarBackground(MaxwinTheme.feltDeep, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func policySection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(MaxwinTheme.cream)

            Text(body)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(MaxwinTheme.mutedCream)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
