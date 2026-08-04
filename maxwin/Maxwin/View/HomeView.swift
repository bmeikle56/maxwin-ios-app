//
//  HomeView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [MaxwinTheme.felt, MaxwinTheme.feltDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(MaxwinTheme.gold)

                    Text(viewModel.welcomeTitle)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(MaxwinTheme.cream)

                    Text("Your poker earnings hub is ready.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        Task { await viewModel.signOut() }
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(MaxwinTheme.gold)
                    .disabled(viewModel.isSigningOut)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(authService: MockAuthService()))
}
