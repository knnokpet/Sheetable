import Foundation

// MARK: Transition
extension Notification.Name {
    static let didBeginOverlayViewTranslation = Notification.Name("didBeginFloatViewTranslation")
    static let didChangeOverlayViewTranslation = Notification.Name("didChangeFloatViewTranslation")
    static let didEndOverlayViewTranslation = Notification.Name("didEndFloatViewTranslation")
    
    static let dismissOverlayView = Notification.Name("dismissFloatView")
    static let moveOverlayView = Notification.Name("moveFloatView")
}

enum OverlayViewNotificationProperty: String {
    case translation, velocity, recognizer, traitcollection, mode, duration
}
