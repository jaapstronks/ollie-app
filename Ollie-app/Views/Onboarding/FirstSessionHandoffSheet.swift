//
//  FirstSessionHandoffSheet.swift
//  Otis-app
//
//  Post-onboarding handoff that guides first-session activation.
//

import SwiftUI

struct FirstSessionHandoffSheet: View {
    let onLogFirstEvent: () -> Void
    let onViewTimeline: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.FirstSession.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(Strings.FirstSession.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    FirstSessionStepRow(
                        icon: "plus.circle.fill",
                        title: Strings.FirstSession.stepOneTitle,
                        bodyText: Strings.FirstSession.stepOneBody
                    )

                    FirstSessionStepRow(
                        icon: "list.bullet.rectangle.portrait.fill",
                        title: Strings.FirstSession.stepTwoTitle,
                        bodyText: Strings.FirstSession.stepTwoBody
                    )

                    FirstSessionStepRow(
                        icon: "sparkles",
                        title: Strings.FirstSession.stepThreeTitle,
                        bodyText: Strings.FirstSession.stepThreeBody
                    )
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button(action: onLogFirstEvent) {
                        Text(Strings.FirstSession.logFirstEvent)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.otisAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: onViewTimeline) {
                        Text(Strings.FirstSession.viewTimeline)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.otisAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }

                    Button(action: onDismiss) {
                        Text(Strings.FirstSession.maybeLater)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(.ultraThinMaterial)
            }
        }
    }
}

private struct FirstSessionStepRow: View {
    let icon: String
    let title: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.otisAccent)
                .frame(width: 24, height: 24)
                .padding(6)
                .background(Color.otisAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    FirstSessionHandoffSheet(
        onLogFirstEvent: {},
        onViewTimeline: {},
        onDismiss: {}
    )
}
