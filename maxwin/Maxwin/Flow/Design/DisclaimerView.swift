//
//  DisclaimerView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import SwiftUI

struct DisclaimerView<SheetContent: View>: View {
    let content: String
    @ViewBuilder let sheetContent: () -> SheetContent

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MaxwinTheme.mutedCream)

                Text(content)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            sheetContent()
        }
    }
}

#Preview {
    DisclaimerView(content: "Privacy policy") {
        PrivacyPolicyView()
    }
    .padding()
    .feltScreenBackground()
}
