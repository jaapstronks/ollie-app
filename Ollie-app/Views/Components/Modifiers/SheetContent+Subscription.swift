//
//  SheetContent+Subscription.swift
//  Otis-app
//
//  Sheet content builders for subscription-related sheets (Otis+)
//

import SwiftUI
import OtisShared

extension SheetCoordinator.ActiveSheet {

    // MARK: - Subscription Sheets

    @MainActor @ViewBuilder
    func buildSubscriptionContent(context: SheetContentContext) -> some View {
        switch self {
        case .otisPlus:
            OtisPlusSheet(
                onDismiss: {
                    context.sheetCoordinator.dismissSheet()
                },
                onSubscribed: {
                    context.sheetCoordinator.transitionToSheet(.subscriptionSuccess)
                }
            )

        case .subscriptionSuccess:
            SubscriptionSuccessView(
                onDismiss: {
                    context.sheetCoordinator.dismissSheet()
                }
            )

        default:
            EmptyView()
        }
    }
}
