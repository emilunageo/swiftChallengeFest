//
//  ContentView.swift
//  swiftChallenge
//
//  Created by Emiliano Luna on 07/06/25.
//

import SwiftUI

enum Tab {
    case dashboard, forum, meal, profile, suggestions
}

struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard

    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .dashboard: DashboardView()
                case .forum:  ChatView()
                case .meal:   MealView()
                case .profile: ProfileView()
                case .suggestions: SuggestionsView()
                

                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack {
                Spacer()
                HStack {
                    // Dashboard
                    TabBarButton(
                        icon: "chart.bar.fill",
                        title: "Dashboard",
                        isSelected: selectedTab == .dashboard
                    ) { selectedTab = .dashboard }

                    Spacer()
                    // Forum
                    TabBarButton(
                        icon: "bubble.left.and.bubble.right",
                        title: "Forum",
                        isSelected: selectedTab == .forum
                    ) { selectedTab = .forum }

                    Spacer()
                    // Meal (botón central grande)
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 64, height: 64)
                            .shadow(radius: 4)
                        Button {
                            selectedTab = .meal
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -12)

                    Spacer()
                    // Profile
                    TabBarButton(
                        icon: "person.crop.circle",
                        title: "Profile",
                        isSelected: selectedTab == .profile
                    ) { selectedTab = .profile }

                    Spacer()
                    // Suggestions
                    TabBarButton(
                        icon: "carrot",
                        title: "Suggestions",
                        isSelected: selectedTab == .suggestions
                    ) { selectedTab = .suggestions }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, safeAreaBottom() + 8)
                .background(Color(UIColor.systemBackground).ignoresSafeArea(edges: .bottom))
                .offset(y: 58)
            }
        }
    }

    
    private func safeAreaBottom() -> CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 24 : 20))
                    .foregroundColor(isSelected ? .green : .gray)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .green : .gray)
            }
        }
    }
}


#Preview {
    ContentView()

}
