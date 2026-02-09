import SwiftUI
import UIKit

// MARK: - Haptic Manager

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - View Modifiers

struct HapticImpactModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.impact(style)
            }
        )
    }
}

struct HapticSelectionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.selection()
            }
        )
    }
}

struct HapticNotificationModifier: ViewModifier {
    let type: UINotificationFeedbackGenerator.FeedbackType

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                HapticManager.notification(type)
            }
        )
    }
}

// MARK: - View Extensions

extension View {
    func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        modifier(HapticImpactModifier(style: style))
    }

    func hapticSelection() -> some View {
        modifier(HapticSelectionModifier())
    }

    func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) -> some View {
        modifier(HapticNotificationModifier(type: type))
    }
}
