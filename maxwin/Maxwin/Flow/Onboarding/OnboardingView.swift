//
//  OnboardingView.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(MaxwinTheme.gold)
                    .symbolEffect(.pulse, options: .repeating.speed(0.35), isActive: viewModel.hasAppeared)
                    .opacity(viewModel.hasAppeared ? 1 : 0)
                    .offset(y: viewModel.hasAppeared ? 0 : 16)

                VStack(spacing: 12) {
                    Text("Maxwin")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(MaxwinTheme.cream)

                    Text("Track every session. Know your edge.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(MaxwinTheme.mutedCream)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(viewModel.hasAppeared ? 1 : 0)
                .offset(y: viewModel.hasAppeared ? 0 : 20)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Log cash games and tournaments, spot trends, and see where your bankroll is headed.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(MaxwinTheme.mutedCream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)

                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.getStarted()
                    }
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(MaxwinTheme.feltDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MaxwinTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
            }
            .opacity(viewModel.hasAppeared ? 1 : 0)
            .offset(y: viewModel.hasAppeared ? 0 : 24)
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .feltScreenBackground()
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                viewModel.markAppeared()
            }
        }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(onboardingService: MockOnboardingService()))
}
