import UIKit

protocol FloatViewTransitionCoordinatorDelegate: class {
    func didChangeBackgroundShadowViewVisibility(_ isHidden: Bool, percentage: Float?)
    func didReachToMaximumPosition(_ coordinator: OverlayViewTransitionCoordinator)
}

class OverlayViewTransitionCoordinator: NSObject, OverlayViewTransitionObservable, OverlayViewTransitionable {
    
    weak var stackController: OverlayViewStackController?
    
    weak var delegate: FloatViewTransitionCoordinatorDelegate?
    
    var beginningTopConstraintConstant: CGFloat = 0
    
    init(stackController: OverlayViewStackController) {
        super.init()
        self.stackController = stackController
        self.registerNotifications()
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleOverlayViewControllerBeganTranslation(_:)), name: .didBeginOverlayViewTranslation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOverlayViewControllerTranslation(_:)), name: .didChangeOverlayViewTranslation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleOverlayViewControllerEndTranslation(_:)), name: .didEndOverlayViewTranslation, object: nil)
    }
    
    func beginOverlayViewTranslation() {
        guard
            let currentOverlayViewController = self.stackController?.currentOverlayViewController,
            let currentParameter = self.stackController?.currentParameter
            else {
                return
        }
        
        currentParameter.overlayViewHeightConstraint?.constant = currentOverlayViewController.view.bounds.height
        self.stackController?.currentOverlayViewHeightConstant = currentOverlayViewController.view.bounds.height
        
        beginningTopConstraintConstant = currentParameter.activeTopConstraint?.constant ?? 0
    }
        
    func translateOverlayView(_ translation: CGPoint) {
        guard let currentParameter = self.stackController?.currentParameter else {
            return
        }
        
        if let topSpaceConstraint = currentParameter.activeTopConstraint {
            
            let fullScreenConstant = TopLayoutConstraintCaluculator.calculatedConstant(for: .fullScreen, containerViewController: self.stackController?.containerViewController)
            let middleConstant = TopLayoutConstraintCaluculator.calculatedConstant(for: .middle, containerViewController: self.stackController?.containerViewController)
            
            let topSpaceConstant: CGFloat = {
                let absolutedTranslationY = beginningTopConstraintConstant + translation.y
                
                // Set upper and lower limit
                let mergin: CGFloat = 12.0
                let bottomConstant = TopLayoutConstraintCaluculator.calculatedConstant(for: .bottom, containerViewController: self.stackController?.containerViewController)
                
                if absolutedTranslationY < fullScreenConstant {
                    let difference = abs(absolutedTranslationY - fullScreenConstant)
                    let percentage = (mergin) / (difference + mergin)
                    return fullScreenConstant - (mergin - mergin * percentage)
                } else if absolutedTranslationY > bottomConstant {
                    let difference = abs(absolutedTranslationY - bottomConstant)
                    let percentage = (mergin) / (difference + mergin)
                    return bottomConstant + (mergin - mergin * percentage)
                } else {
                    return absolutedTranslationY
                }
            }()
            
            if topSpaceConstant <= fullScreenConstant {
                delegate?.didReachToMaximumPosition(self)
            }
            
            // shadow
            if self.stackController?.containerViewController.traitCollection.verticalSizeClass == .regular {
                if (fullScreenConstant...middleConstant).contains(topSpaceConstant) {
                    let max = middleConstant - fullScreenConstant
                    let current = topSpaceConstant - fullScreenConstant
                    let percentage = 1 - current / max
                    delegate?.didChangeBackgroundShadowViewVisibility(false, percentage: Float(percentage))
                }
            }
            
            
            topSpaceConstraint.constant = topSpaceConstant
        }
        
        currentParameter.overlayViewHeightConstraint?.constant =  (self.stackController?.currentOverlayViewHeightConstant ?? 0) + (-translation.y)
    }
    
    func endOverlayViewTranslation(_ translation: CGPoint, recognizer: UIPanGestureRecognizer) {
        guard let floatStackController = self.stackController else {
            return
        }
                
        let velocity: CGPoint = recognizer.velocity(in: self.stackController?.containerViewController.view)
        
        if abs(translation.y) < 50 {
            if (-100...100).contains(velocity.y) {
                self.move(mode: floatStackController.overlayModeBeforeProgressing, recognizer: recognizer, velocity: nil, duration: nil)
            } else if velocity.y < -100 {
                let toMode: OverlayMode = {
                    switch floatStackController.currentOverlayMode {
                    case .middle:
                        return .fullScreen
                    case .fullScreen:
                        return .fullScreen
                    case .bottom:
                        return .middle
                    case .progressing:
                        switch floatStackController.overlayModeBeforeProgressing {
                        case .fullScreen:
                            return .fullScreen
                        case .middle:
                            return .fullScreen
                        case .bottom:
                            return .middle
                        default:
                            return .middle
                        }
                    }
                }()
                self.move(mode: toMode, recognizer: nil, velocity: nil, duration: nil)
            } else if velocity.y > 100 {
                let toMode: OverlayMode = {
                    switch floatStackController.currentOverlayMode {
                    case .middle:
                        return .bottom
                    case .fullScreen:
                        return .middle
                    case .bottom:
                        return .bottom
                    case .progressing:
                        switch floatStackController.overlayModeBeforeProgressing {
                        case .fullScreen:
                            return .middle
                        case .middle:
                            return .bottom
                        case .bottom:
                            return .bottom
                        default:
                            return .middle
                        }
                    }
                }()
                self.move(mode: toMode, recognizer: recognizer, velocity: nil, duration: nil)
            }
        } else {
            #warning("TO DO ADJUSTMENT")
            let _ = recognizer.location(in: self.stackController?.containerViewController.view)
            if translation.y < -50 {
                let toMode: OverlayMode = {
                    switch floatStackController.currentOverlayMode {
                    case .middle:
                        return .fullScreen
                    case .fullScreen:
                        return .fullScreen
                    case .bottom:
                        if translation.y < -400 {
                            return .fullScreen
                        }
                        return .middle
                    case .progressing:
                        switch floatStackController.overlayModeBeforeProgressing {
                        case .fullScreen:
                            return .fullScreen
                        case .middle:
                            return .fullScreen
                        case .bottom:
                            if translation.y < -400 {
                                return .fullScreen
                            }
                            return .middle
                        default:
                            return .middle
                        }
                    }
                }()
                self.move(mode: toMode, recognizer: recognizer, velocity: nil, duration: nil)
            } else if translation.y > 50 {
                let toMode: OverlayMode = {
                    switch floatStackController.currentOverlayMode {
                    case .middle:
                        return .bottom
                    case .fullScreen:
                        if translation.y > 400 {
                            return .bottom
                        }
                        return .middle
                    case .bottom:
                        return .bottom
                    case .progressing:
                        switch floatStackController.overlayModeBeforeProgressing {
                        case .fullScreen:
                            if translation.y > 400 {
                                return .bottom
                            }
                            return .middle
                        case .middle:
                            return .bottom
                        case .bottom:
                            return .bottom
                        default:
                            return .middle
                        }
                    }
                }()
                self.move(mode: toMode, recognizer: recognizer, velocity: nil, duration: nil)
            } else {
                if (-100...100).contains(velocity.y) {
                    self.move(mode: floatStackController.overlayModeBeforeProgressing, recognizer: recognizer, velocity: nil, duration: nil)
                } else if velocity.y < -100 {
                    let toMode: OverlayMode = {
                        switch floatStackController.currentOverlayMode {
                        case .middle:
                            return .fullScreen
                        case .fullScreen:
                            return .fullScreen
                        case .bottom:
                            return .middle
                        case .progressing:
                            switch floatStackController.overlayModeBeforeProgressing {
                            case .fullScreen:
                                return .fullScreen
                            case .middle:
                                return .fullScreen
                            case .bottom:
                                return .middle
                            default:
                                return .middle
                            }
                        }
                    }()
                    self.move(mode: toMode, recognizer: recognizer, velocity: nil, duration: nil)
                } else if velocity.y > 100 {
                    let toMode: OverlayMode = {
                        switch floatStackController.currentOverlayMode {
                        case .middle:
                            return .bottom
                        case .fullScreen:
                            return .middle
                        case .bottom:
                            return .bottom
                        case .progressing:
                            switch floatStackController.overlayModeBeforeProgressing {
                            case .fullScreen:
                                return .middle
                            case .middle:
                                return .bottom
                            case .bottom:
                                return .bottom
                            default:
                                return .middle
                            }
                        }
                    }()
                    self.move(mode: toMode, recognizer: recognizer, velocity: nil, duration: nil)
                }
            }
            
            
        }
    }
    
    
    @objc public func handleOverlayViewControllerBeganTranslation(_ notification: Notification) {
        beginOverlayViewTranslation()
    }
    
    @objc public func handleOverlayViewControllerTranslation(_ notification: Notification) {
        guard
            let translation = notification.userInfo?[OverlayViewNotificationProperty.translation] as? CGPoint
            else {
                return
        }
        
        translateOverlayView(translation)
    }
    
    @objc public func handleOverlayViewControllerEndTranslation(_ notification: Notification) {
        
        guard
            let translation = notification.userInfo?[OverlayViewNotificationProperty.translation] as? CGPoint,
            let recognizer = notification.userInfo?[OverlayViewNotificationProperty.recognizer] as? UIPanGestureRecognizer
            else {
                return
        }
        
        endOverlayViewTranslation(translation, recognizer: recognizer)
    }

    func move(mode: OverlayMode, recognizer: UIPanGestureRecognizer?, velocity: Float?, duration: Double?) {
        
        /*
         Use standard UIView animation with layoutIfNeeded
         Always deactivate constraints first
         Hold to your deactivated constraints strongly
         */
        
        guard
            let currentParameter = self.stackController?.currentParameter,
            let topSpaceConstraint = currentParameter.activeTopConstraint
            else {
                return
        }
        
        let topSpaceConstraintConstantForMode = TopLayoutConstraintCaluculator.calculatedConstant(for: mode, containerViewController: self.stackController?.containerViewController)
        let merginBetweenTopConstraints = abs(topSpaceConstraint.constant - topSpaceConstraintConstantForMode)
        
        NSLayoutConstraint.activate([topSpaceConstraint])
        topSpaceConstraint.constant = topSpaceConstraintConstantForMode
        self.stackController?.currentOverlayMode = mode
        
        let velo: CGFloat = {
            if let recognizer = recognizer {
                let velocityFromGesture: CGPoint = recognizer.velocity(in: self.stackController?.containerViewController.view)
                
                return abs(velocityFromGesture.y / merginBetweenTopConstraints)
            } else if let velo = velocity {
                return CGFloat(velo)
            }
            
            return 0.0
        }()
        
        let dur: Double = duration ?? 0.5
                
        UIView.animate(withDuration: dur, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: velo, options: [.allowUserInteraction], animations: {
            self.stackController?.containerViewController.view.layoutIfNeeded()
            
            if self.stackController?.containerViewController.traitCollection.verticalSizeClass == .regular {
                self.delegate?.didChangeBackgroundShadowViewVisibility((mode != .fullScreen), percentage: nil)
            }
            
        }, completion: { finished in
            if finished {
                currentParameter.overlayViewHeightConstraint?.constant = self.stackController?.currentOverlayViewController?.view.bounds.height ?? 0
                self.stackController?.currentOverlayViewHeightConstant = self.stackController?.currentOverlayViewController?.view.bounds.height ?? 0
            }
        })
    }
    
    func present(completionHandler: ((Bool) -> Void)?) {
        guard
            let container = self.stackController?.containerViewController,
            let _ = self.stackController?.currentOverlayViewController,
            let parameter = self.stackController?.currentParameter
            else {
                return
        }

        #warning("In iOS12, it causes presentation with wrong animation")
        // layoutIfNeeded のタイミングのせいか、この call の前後で parameter.activeTC が変化してる・・
        // By calling layoutIfNeeded at once, let view layout be confirmed
        self.stackController?.containerViewController.view.layoutIfNeeded()
        
        parameter.activeTopConstraint?.constant = container.view.bounds.height / 2
        
        // For Previous
        if let previousViewController = self.stackController?.previousOverlayViewController as? Sheetable {
            UIView.animate(withDuration: 0.3, animations: {
                previousViewController.shadowView.isHiddenShadowView = false
            }) { (isFinished) in
                if isFinished {
                    UIView.animate(withDuration: 0.3, animations: {
                        previousViewController.view.layer.opacity = 0.0
                    }, completion: nil)
                }
            }
        }
        
        
        // For Current
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [.allowUserInteraction], animations: {
            
            self.stackController?.containerViewController.view.layoutIfNeeded()
            
        }, completion: { finished in
            completionHandler?(finished)
        })
    }
    
    func remove(_ viewController: UIViewController, parameter: OverlayViewLayoutConstraintParameter, previousViewController: UIViewController?, completionHandler: ((Bool) -> Void)?) {
        
        guard let container = self.stackController?.containerViewController else { return }
        
        // By calling layoutIfNeeded at once, let view layout be confirmed
        self.stackController?.containerViewController.view.layoutIfNeeded()
        
        parameter.activeTopConstraint?.constant = container.view.bounds.height
        
        // Show Previous View Controller behind Current
        if let previousViewController = previousViewController as? Sheetable {
            previousViewController.shadowView.isHiddenShadowView = false
            previousViewController.view.layer.opacity = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                previousViewController.shadowView.isHiddenShadowView = true
            }, completion: nil)
        }
        
        // Dismiss Current View Controller
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [], animations: {
            self.stackController?.containerViewController.view.layoutIfNeeded()
            
            if self.stackController?.containerViewController.traitCollection.verticalSizeClass == .regular {
                self.delegate?.didChangeBackgroundShadowViewVisibility(true, percentage: nil)
            }
            
        }, completion: { finished in
            completionHandler?(finished)
        })
        
    }
    
    func remove(completionHandler: ((Bool) -> Void)?) {
        
        guard
            let container = self.stackController?.containerViewController,
            let _ = self.stackController?.currentOverlayViewController,
            let parameter = self.stackController?.currentParameter
            else {
                return
        }

        // By calling layoutIfNeeded at once, let view layout be confirmed
        self.stackController?.containerViewController.view.layoutIfNeeded()
        
        parameter.activeTopConstraint?.constant = container.view.bounds.height
        
        if let previousViewController = self.stackController?.previousOverlayViewController as? Sheetable {
            previousViewController.shadowView.isHiddenShadowView = false
            previousViewController.view.layer.opacity = 1.0
            UIView.animate(withDuration: 0.3, animations: {
                previousViewController.shadowView.isHiddenShadowView = true
            }, completion: nil)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: [], animations: {
            self.stackController?.containerViewController.view.layoutIfNeeded()
            
            if self.stackController?.containerViewController.traitCollection.verticalSizeClass == .regular {
                self.delegate?.didChangeBackgroundShadowViewVisibility(true, percentage: nil)
            }
            
        }, completion: { finished in
            completionHandler?(finished)
        })
    }
    
}

extension OverlayViewTransitionCoordinator {
    
    internal func handleTraitcollectionWillChange(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

    }
    
    internal func handleTraitcollectionDidChange(_ previousTraitCollection: UITraitCollection?, currentTraitCollection: UITraitCollection) {
        
        updateViewConfiguration(currentTraitCollection)
    }
    
    
    /// Set up Float View
    /// - Parameters:
    ///   - traitCollection: To set up shadow view and constraint activations
    func setupViewConfiguration(_ traitCollection: UITraitCollection) {
        guard
            let currentViewController = self.stackController?.currentOverlayViewController
        else { return }

        self.updateShadowView(with: traitCollection)
        activateConstraints(traitCollection)
        
        self.stackController?.containerViewController.view.layoutIfNeeded()
        currentViewController.view.layoutIfNeeded()
    }
    
    
    /// Update Float View Constraints, shadow
    /// - Parameter traitCollection: To update shadow view and  constraint activations
    func updateViewConfiguration(_ traitCollection: UITraitCollection) {
        guard
            let currentViewController = self.stackController?.currentOverlayViewController
        else { return }
        
        self.updateConstraints()
        self.updateShadowView(with: traitCollection)
        activateConstraints(traitCollection)
        
        self.stackController?.containerViewController.view.layoutIfNeeded()
        currentViewController.view.layoutIfNeeded()
    }
    
    private func updateConstraints() {
        
        guard
            let mode =  self.stackController?.currentOverlayMode
        else { return }
        let constant = TopLayoutConstraintCaluculator.calculatedConstant(for: mode, containerViewController: self.stackController?.containerViewController)
        if let current = self.stackController?.currentParameter {
            current.portraitTopConstraint?.constant = constant
            current.landscapeTopConstraint?.constant = constant
            self.stackController?.setCurrentParameter(current)
        }
    }
    
    private func activateConstraints(_ traitCollection: UITraitCollection) {
        if traitCollection.verticalSizeClass == .compact { // landscape
            self.stackController?.currentParameter?.portraitTopConstraint?.isActive = false
            self.stackController?.currentParameter?.portraitLeftConstraint?.isActive = false
            self.stackController?.currentParameter?.portraitRightConstraint?.isActive = false
            self.stackController?.currentParameter?.portraitBottomConstraint?.isActive = false
            
            self.stackController?.currentParameter?.landscapeTopConstraint?.isActive = true
            self.stackController?.currentParameter?.landscapeLeftConstraint?.isActive = true
            self.stackController?.currentParameter?.landscapeWidthConstraint?.isActive = true
            self.stackController?.currentParameter?.landscapeBottomConstraint?.isActive = true
            
        } else if traitCollection.verticalSizeClass == .regular { // portrait
            
            self.stackController?.currentParameter?.landscapeTopConstraint?.isActive = false
            self.stackController?.currentParameter?.landscapeLeftConstraint?.isActive = false
            self.stackController?.currentParameter?.landscapeWidthConstraint?.isActive = false
            self.stackController?.currentParameter?.landscapeBottomConstraint?.isActive = false
            
            self.stackController?.currentParameter?.portraitTopConstraint?.isActive = true
            self.stackController?.currentParameter?.portraitLeftConstraint?.isActive = true
            self.stackController?.currentParameter?.portraitRightConstraint?.isActive = true
            self.stackController?.currentParameter?.portraitBottomConstraint?.isActive = true
        }
    }
    
    private func updateShadowView(with traitCollection: UITraitCollection) {
        UIView.animate(withDuration: 0.3) {
            if traitCollection.verticalSizeClass == .compact {
                self.delegate?.didChangeBackgroundShadowViewVisibility(true, percentage: nil)
            } else {
                self.delegate?.didChangeBackgroundShadowViewVisibility((self.stackController?.currentOverlayMode != .fullScreen), percentage: nil)
                
            }
        }
    }
}


private final class TopLayoutConstraintCaluculator {
    class func calculatedConstant(for mode:OverlayMode, containerViewController: UIViewController?) -> CGFloat {
        
        guard let container = containerViewController else { return 0.0}
        
        #warning("NEED TO CHANGE TO PRACTICAL VALUE")
        switch mode {
        case .fullScreen:
            if container.traitCollection.verticalSizeClass == .compact {
                return container.view.safeAreaInsets.right / 2
            }
            return container.view.safeAreaInsets.top
        case .middle:
            return container.view.bounds.height / 2
        case .bottom:
            return container.view.bounds.height / 1.3
        case .progressing:
            return 0
        }
    }
}
