//
//  MaxwinApp.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/3/26.
//

import SwiftUI

@main
struct MaxwinApp: App {
    @State private var rootViewModel = RootViewModel(
        authService: MockAuthService(),
        onboardingService: MockOnboardingService()
    )

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: rootViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
