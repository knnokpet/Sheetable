import Foundation

protocol OverlayViewTransitionObservable {
    func handleOverlayViewControllerBeganTranslation(_ notification: Notification)
    func handleOverlayViewControllerTranslation(_ notification: Notification)
    func handleOverlayViewControllerEndTranslation(_ notification: Notification)
}
