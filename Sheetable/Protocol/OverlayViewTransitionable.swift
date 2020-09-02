import UIKit

protocol OverlayViewTransitionable {
    func present(completionHandler: ((Bool) -> Void)?)
    func remove(_ viewController: UIViewController, parameter: OverlayViewLayoutConstraintParameter, previousViewController: UIViewController?, completionHandler: ((Bool) -> Void)?)
    func move(mode: OverlayMode, recognizer: UIPanGestureRecognizer?, velocity: Float?, duration: Double?)
    //func move(mode: OverlayMode, velocity: Float?, duration: Double?)
}
